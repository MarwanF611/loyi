// Loyi billing: Stripe subscriptions → Firestore `subscriptions/{uid}`.
//
// Loyi runs on Firebase's free Spark plan (no Cloud Functions), so this small
// Cloudflare Worker (free tier) is the only server. firestore.rules only let
// a shop's dashboard and tags work while `subscriptions/{ownerUid}.expiresAt`
// is in the future, and only this Worker (a service account) writes it.
//
// Routes
//   POST /checkout        signed-in shop → Stripe Checkout URL for the monthly plan
//   POST /portal          signed-in shop → Stripe customer portal URL (card, invoices, cancel)
//   POST /delete-account  signed-in shop → cancels its subscription and removes billing records
//   POST /stripe          Stripe webhook (signature-checked)
// The first three need `Authorization: Bearer <Firebase ID token>`.
//
// Webhooks are only a nudge: the subscription is always read back from the
// Stripe API, so out-of-order or replayed events can't leave a wrong status.
//
// Secrets (wrangler secret put …):
//   STRIPE_SECRET_KEY          sk_test_… or sk_live_… (a restricted key works too, see README)
//   STRIPE_WEBHOOK_SECRET      whsec_… from the webhook endpoint
//   FIREBASE_SERVICE_ACCOUNT   service account JSON with the "Cloud Datastore User" role
// Vars (wrangler.toml): FIREBASE_PROJECT_ID, STRIPE_PRICE_ID, APP_URL, ALLOWED_ORIGINS

const STRIPE_VERSION = "2024-06-20"; // pinned so response shapes don't change under us
const DAY = 86_400_000;
const PAST_DUE_GRACE = 7 * DAY; // Stripe retries a failed renewal; keep the shop running meanwhile
const SIGNATURE_TOLERANCE_S = 300;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const origin = request.headers.get("Origin");
    const cors = corsHeaders(origin, env);
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
    if (request.method !== "POST") return json({ error: "Not found" }, 404, cors);

    try {
      switch (url.pathname) {
        case "/stripe":
          return await handleWebhook(request, env);
        case "/checkout":
          return json(await createCheckout(await requireShop(request, env), appUrl(origin, env), env, stripeLocale(url)), 200, cors);
        case "/portal":
          return json(await createPortal(await requireShop(request, env), appUrl(origin, env), env, stripeLocale(url)), 200, cors);
        case "/delete-account":
          return json(await deleteAccount(await requireUser(request, env), env), 200, cors);
        default:
          return json({ error: "Not found" }, 404, cors);
      }
    } catch (e) {
      if (e instanceof HttpError) return json({ error: e.message }, e.status, cors);
      // A 5xx makes Stripe retry the webhook later.
      console.error(e);
      return json({ error: "Server error" }, 500, cors);
    }
  },
};

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function json(body, status, headers = {}) {
  return new Response(JSON.stringify(body), { status, headers: { ...headers, "Content-Type": "application/json" } });
}

function allowedOrigins(env) {
  return (env.ALLOWED_ORIGINS || "").split(",").map((o) => o.trim()).filter(Boolean);
}

function corsHeaders(origin, env) {
  if (!origin || !allowedOrigins(env).includes(origin)) return {};
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
}

/** Where Stripe sends the shop back to: the site it came from (if allowed), else APP_URL. */
function appUrl(origin, env) {
  return origin && allowedOrigins(env).includes(origin) ? origin : env.APP_URL;
}

// ── Shop endpoints ───────────────────────────────────────────────────────────

async function requireUser(request, env) {
  const header = request.headers.get("Authorization") ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : "";
  if (!token) throw new HttpError(401, "Sign in first.");
  try {
    return await verifyFirebaseToken(token, env);
  } catch {
    throw new HttpError(401, "Sign in again.");
  }
}

async function requireShop(request, env) {
  const user = await requireUser(request, env);
  if (user.provider === "anonymous") throw new HttpError(403, "Only business accounts can subscribe.");
  return user;
}

/** The app's language (?locale=nl|fr|en) for Stripe's pages; otherwise Stripe follows the browser. */
function stripeLocale(url) {
  const locale = url.searchParams.get("locale");
  return ["nl", "fr", "en"].includes(locale) ? locale : "auto";
}

export async function createCheckout(user, returnTo, env, locale = "auto") {
  const current = await readDoc(`subscriptions/${user.uid}`, env);
  if (current && new Date(current.expiresAt) > new Date()) throw new HttpError(409, "You're already subscribed.");
  const billing = await readDoc(`billing/${user.uid}`, env);

  const params = {
    mode: "subscription",
    line_items: [{ price: env.STRIPE_PRICE_ID, quantity: 1 }],
    client_reference_id: user.uid,
    metadata: { firebase_uid: user.uid },
    subscription_data: { metadata: { firebase_uid: user.uid } },
    success_url: `${returnTo}/business?checkout=done`,
    cancel_url: `${returnTo}/business`,
    billing_address_collection: "required",
    tax_id_collection: { enabled: true }, // businesses can add their VAT number for the invoice
    allow_promotion_codes: true,
    locale,
  };
  if (billing?.customerId) {
    params.customer = billing.customerId;
    params.customer_update = { name: "auto", address: "auto" };
  } else if (user.email) {
    params.customer_email = user.email;
  }
  const session = await stripe(env, "POST", "/v1/checkout/sessions", params);
  return { url: session.url };
}

export async function createPortal(user, returnTo, env, locale = "auto") {
  const billing = await readDoc(`billing/${user.uid}`, env);
  if (!billing?.customerId) throw new HttpError(404, "There is no subscription to manage yet.");
  const session = await stripe(env, "POST", "/v1/billing_portal/sessions", {
    customer: billing.customerId,
    return_url: `${returnTo}/business/subscribe`,
    locale,
  });
  return { url: session.url };
}

/** Account deletion: stop charging the shop, then forget the billing link. Stripe keeps its own records (invoices). */
export async function deleteAccount(user, env) {
  const billing = await readDoc(`billing/${user.uid}`, env);
  let cancelled = 0;
  if (billing?.customerId) {
    const subs = await stripe(env, "GET", `/v1/subscriptions?customer=${encodeURIComponent(billing.customerId)}&status=all&limit=100`);
    for (const sub of subs.data ?? []) {
      if (["canceled", "incomplete_expired"].includes(sub.status)) continue;
      await stripe(env, "DELETE", `/v1/subscriptions/${sub.id}`);
      cancelled++;
    }
  }
  await deleteDoc(`billing/${user.uid}`, env);
  await deleteDoc(`subscriptions/${user.uid}`, env);
  return { ok: true, cancelled };
}

// ── Webhook ──────────────────────────────────────────────────────────────────

const HANDLED = new Set([
  "checkout.session.completed",
  "checkout.session.async_payment_succeeded",
  "checkout.session.async_payment_failed",
  "customer.subscription.created",
  "customer.subscription.updated",
  "customer.subscription.deleted",
  "customer.subscription.paused",
  "customer.subscription.resumed",
  "invoice.paid",
  "invoice.payment_failed",
]);

async function handleWebhook(request, env) {
  const body = await request.text();
  const ok = await verifyStripeSignature(body, request.headers.get("Stripe-Signature") ?? "", env.STRIPE_WEBHOOK_SECRET);
  if (!ok) return json({ error: "Bad signature" }, 400);
  const event = JSON.parse(body);
  if (!HANDLED.has(event.type)) return json({ ok: true, ignored: event.type }, 200);

  const object = event.data?.object ?? {};
  const ref = (v) => (typeof v === "string" ? v : v?.id);
  const subscriptionId =
    object.object === "subscription"
      ? object.id
      : // Newer API versions (2025+) moved an invoice's subscription under parent.
        (ref(object.subscription) ?? ref(object.parent?.subscription_details?.subscription));
  if (!subscriptionId) return json({ ok: true, ignored: "no subscription" }, 200);
  const uid = await syncSubscription(subscriptionId, env);
  return json({ ok: true, updated: uid ? [uid] : [] }, 200);
}

/** Reads the subscription from Stripe and mirrors it into Firestore. Returns the shop's uid, or null if not ours. */
export async function syncSubscription(subscriptionId, env) {
  const sub = await stripe(env, "GET", `/v1/subscriptions/${encodeURIComponent(subscriptionId)}`);
  const uid = sub.metadata?.firebase_uid;
  if (!uid) return null; // created outside Loyi's checkout

  const billing = await readDoc(`billing/${uid}`, env);
  const status = subscriptionStatus(sub);
  // An old, ended subscription mustn't overwrite the shop's newer one.
  if (billing?.subscriptionId && billing.subscriptionId !== sub.id && !status.active) return null;

  const customerId = typeof sub.customer === "string" ? sub.customer : sub.customer?.id;
  await writeDoc(`billing/${uid}`, { customerId, subscriptionId: sub.id, updatedAt: new Date().toISOString() }, env);

  // A manual grant (App Review, pilot shop) is never shortened by Stripe.
  const existing = await readDoc(`subscriptions/${uid}`, env);
  if (existing?.source === "grant" && existing.expiresAt >= status.expiresAt) return uid;

  await writeDoc(
    `subscriptions/${uid}`,
    {
      expiresAt: status.expiresAt,
      store: "stripe",
      source: "stripe",
      environment: sub.livemode ? "LIVE" : "TEST",
      willRenew: status.willRenew,
      billingIssue: status.billingIssue,
      updatedAt: new Date().toISOString(),
    },
    env,
  );
  return uid;
}

/** How long a Stripe subscription keeps the shop running. */
export function subscriptionStatus(sub, now = Date.now()) {
  const periodEnd =
    (sub.current_period_end ?? Math.max(0, ...(sub.items?.data ?? []).map((i) => i.current_period_end ?? 0))) * 1000;
  const iso = (ms) => new Date(ms).toISOString();
  switch (sub.status) {
    case "active":
    case "trialing":
      return {
        active: true,
        expiresAt: iso(periodEnd),
        willRenew: !sub.cancel_at_period_end && !sub.cancel_at,
        billingIssue: false,
      };
    case "past_due":
      return { active: true, expiresAt: iso(periodEnd + PAST_DUE_GRACE), willRenew: true, billingIssue: true };
    default: // incomplete, incomplete_expired, unpaid, canceled, paused
      return {
        active: false,
        expiresAt: iso(Math.min(now, sub.ended_at ? sub.ended_at * 1000 : now)),
        willRenew: false,
        billingIssue: sub.status === "unpaid",
      };
  }
}

/** Stripe-Signature: t=<unix>,v1=<hex hmac of "t.body">. */
export async function verifyStripeSignature(body, header, secret, now = Date.now()) {
  if (!secret) return false;
  const items = header.split(",").map((p) => p.trim());
  const t = items.find((p) => p.startsWith("t="))?.slice(2);
  const signatures = items.filter((p) => p.startsWith("v1=")).map((p) => p.slice(3));
  if (!t || signatures.length === 0) return false;
  if (Math.abs(now / 1000 - Number(t)) > SIGNATURE_TOLERANCE_S) return false;
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, [
    "sign",
  ]);
  const mac = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${t}.${body}`)));
  const expected = [...mac].map((b) => b.toString(16).padStart(2, "0")).join("");
  return signatures.some((s) => safeEqual(s, expected));
}

// ── Stripe API ───────────────────────────────────────────────────────────────

async function stripe(env, method, path, params) {
  const base = env.STRIPE_API_BASE || "https://api.stripe.com";
  const res = await fetch(`${base}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${env.STRIPE_SECRET_KEY}`,
      "Stripe-Version": STRIPE_VERSION,
      ...(params ? { "Content-Type": "application/x-www-form-urlencoded" } : {}),
    },
    body: params ? formEncode(params) : undefined,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(`Stripe ${method} ${path}: ${res.status} ${data.error?.message ?? ""}`);
  return data;
}

/** Stripe's form encoding: a[b]=1&items[0][price]=… */
export function formEncode(params) {
  const out = new URLSearchParams();
  const add = (prefix, value) => {
    if (value === undefined || value === null) return;
    if (Array.isArray(value)) value.forEach((v, i) => add(`${prefix}[${i}]`, v));
    else if (typeof value === "object") for (const [k, v] of Object.entries(value)) add(`${prefix}[${k}]`, v);
    else out.append(prefix, String(value));
  };
  for (const [k, v] of Object.entries(params)) add(k, v);
  return out.toString();
}

// ── Firebase ID tokens ───────────────────────────────────────────────────────

const JWKS_URL = "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com";
let cachedJwks = null;

/** Verifies a Firebase Auth ID token (RS256, Google's keys) and returns {uid, provider, email}. */
export async function verifyFirebaseToken(token, env, now = Date.now()) {
  const [h, p, s] = token.split(".");
  if (!h || !p) throw new Error("malformed");
  const header = JSON.parse(new TextDecoder().decode(base64urlDecode(h)));
  const claims = JSON.parse(new TextDecoder().decode(base64urlDecode(p)));

  if (env.FIREBASE_AUTH_EMULATOR_HOST) {
    // The Auth emulator issues unsigned tokens; never set this variable in production.
  } else {
    if (header.alg !== "RS256" || !header.kid || !s) throw new Error("bad header");
    const jwk = (await googleKeys(now)).find((k) => k.kid === header.kid);
    if (!jwk) throw new Error("unknown key");
    const key = await crypto.subtle.importKey("jwk", jwk, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["verify"]);
    const valid = await crypto.subtle.verify("RSASSA-PKCS1-v1_5", key, base64urlDecode(s), new TextEncoder().encode(`${h}.${p}`));
    if (!valid) throw new Error("bad signature");
  }

  const project = env.FIREBASE_PROJECT_ID;
  const t = now / 1000;
  if (claims.aud !== project || claims.iss !== `https://securetoken.google.com/${project}`) throw new Error("wrong project");
  if (!(claims.exp > t) || claims.iat > t + 60 || !claims.sub) throw new Error("expired");
  return { uid: claims.sub, provider: claims.firebase?.sign_in_provider ?? null, email: claims.email ?? null };
}

async function googleKeys(now) {
  if (cachedJwks && cachedJwks.expires > now) return cachedJwks.keys;
  const res = await fetch(JWKS_URL);
  if (!res.ok) throw new Error(`Google keys ${res.status}`);
  const maxAge = Number(res.headers.get("Cache-Control")?.match(/max-age=(\d+)/)?.[1] ?? 3600);
  cachedJwks = { keys: (await res.json()).keys, expires: now + maxAge * 1000 };
  return cachedJwks.keys;
}

// ── Firestore REST ───────────────────────────────────────────────────────────

function docUrl(path, env) {
  const root = env.FIRESTORE_EMULATOR_HOST ? `http://${env.FIRESTORE_EMULATOR_HOST}/v1` : "https://firestore.googleapis.com/v1";
  const encoded = path.split("/").map(encodeURIComponent).join("/");
  return `${root}/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${encoded}`;
}

const TIMESTAMP_FIELDS = new Set(["expiresAt", "updatedAt"]);

/** A document as plain values (timestamps as ISO strings), or null. */
async function readDoc(path, env) {
  const res = await fetch(docUrl(path, env), { headers: await authHeaders(env) });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`Firestore read ${path}: ${res.status}`);
  const out = {};
  for (const [k, v] of Object.entries((await res.json()).fields ?? {})) {
    out[k] =
      "timestampValue" in v ? new Date(v.timestampValue).toISOString() : (v.stringValue ?? v.booleanValue ?? v.integerValue ?? null);
  }
  return out;
}

async function writeDoc(path, data, env) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    fields[k] =
      v === null || v === undefined
        ? { nullValue: null }
        : TIMESTAMP_FIELDS.has(k)
          ? { timestampValue: v }
          : typeof v === "boolean"
            ? { booleanValue: v }
            : { stringValue: String(v) };
  }
  const res = await fetch(docUrl(path, env), {
    method: "PATCH",
    headers: { ...(await authHeaders(env)), "Content-Type": "application/json" },
    body: JSON.stringify({ fields }),
  });
  if (!res.ok) throw new Error(`Firestore write ${path}: ${res.status} ${await res.text()}`);
}

async function deleteDoc(path, env) {
  const res = await fetch(docUrl(path, env), { method: "DELETE", headers: await authHeaders(env) });
  if (!res.ok && res.status !== 404) throw new Error(`Firestore delete ${path}: ${res.status}`);
}

// ── Google service account auth (JWT bearer grant, WebCrypto) ────────────────

let cachedToken = null;

async function authHeaders(env) {
  if (env.FIRESTORE_EMULATOR_HOST) return { Authorization: "Bearer owner" }; // emulator: admin access
  return { Authorization: `Bearer ${await accessToken(env)}` };
}

export async function accessToken(env, now = Date.now()) {
  if (cachedToken && cachedToken.expires > now + 60_000) return cachedToken.token;
  const sa = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);
  const tokenUri = sa.token_uri || "https://oauth2.googleapis.com/token";
  const iat = Math.floor(now / 1000);
  const jwt = await signJwt(
    { iss: sa.client_email, scope: "https://www.googleapis.com/auth/datastore", aud: tokenUri, iat, exp: iat + 3600 },
    sa.private_key,
  );
  const res = await fetch(tokenUri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: jwt }),
  });
  if (!res.ok) throw new Error(`Google token ${res.status}`);
  const { access_token, expires_in } = await res.json();
  cachedToken = { token: access_token, expires: now + expires_in * 1000 };
  return access_token;
}

async function signJwt(claims, privateKeyPem) {
  const enc = (obj) => base64url(new TextEncoder().encode(JSON.stringify(obj)));
  const unsigned = `${enc({ alg: "RS256", typ: "JWT" })}.${enc(claims)}`;
  const der = Uint8Array.from(atob(privateKeyPem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "")), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey("pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned));
  return `${unsigned}.${base64url(new Uint8Array(sig))}`;
}

function base64url(bytes) {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64urlDecode(s) {
  const b64 = s.replace(/-/g, "+").replace(/_/g, "/") + "=".repeat((4 - (s.length % 4)) % 4);
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
}

/** Constant-time string comparison. */
function safeEqual(a, b) {
  const x = new TextEncoder().encode(a);
  const y = new TextEncoder().encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  return diff === 0;
}

export function resetCachesForTests() {
  cachedToken = null;
  cachedJwks = null;
}
