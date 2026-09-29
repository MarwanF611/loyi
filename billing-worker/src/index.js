// RevenueCat webhook → Firestore `subscriptions/{uid}`.
//
// Loyi runs on Firebase's free Spark plan (no Cloud Functions), so this small
// Cloudflare Worker (free tier) is the only server. firestore.rules only let
// tags work while `subscriptions/{ownerUid}.expiresAt` is in the future, and
// only this Worker (a service account) can write that document.
//
// The webhook body is only used to learn *which* users changed. Their status is
// always read back from the RevenueCat API with the secret key, so a forged or
// replayed webhook can't grant anything.
//
// Secrets (wrangler secret put …):
//   REVENUECAT_WEBHOOK_AUTH   the exact Authorization header value set in RevenueCat
//   REVENUECAT_SECRET_KEY     RevenueCat secret API key (sk_…)
//   FIREBASE_SERVICE_ACCOUNT  service account JSON with the "Cloud Datastore User" role
// Vars (wrangler.toml): FIREBASE_PROJECT_ID, ENTITLEMENT_ID, ALLOW_SANDBOX

const FAR_FUTURE = new Date("9999-12-31T23:59:59Z").toISOString(); // lifetime / non-expiring entitlements

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method !== "POST" || url.pathname !== "/revenuecat") {
      return new Response("Not found", { status: 404 });
    }
    if (!env.REVENUECAT_WEBHOOK_AUTH || !safeEqual(request.headers.get("Authorization") ?? "", env.REVENUECAT_WEBHOOK_AUTH)) {
      return new Response("Unauthorized", { status: 401 });
    }

    let event;
    try {
      event = (await request.json()).event;
    } catch {
      return new Response("Bad request", { status: 400 });
    }
    if (!event) return new Response("Bad request", { status: 400 });

    try {
      const updated = [];
      for (const uid of affectedUsers(event)) {
        if (await syncUser(uid, env)) updated.push(uid);
      }
      return Response.json({ ok: true, updated });
    } catch (e) {
      // A 5xx makes RevenueCat retry the webhook later.
      console.error(e);
      return new Response("Sync failed", { status: 500 });
    }
  },
};

/** Firebase uids named in the event. Anonymous RevenueCat ids are skipped: the app logs in first. */
export function affectedUsers(event) {
  const ids = [
    event.app_user_id,
    event.original_app_user_id,
    ...(event.aliases ?? []),
    ...(event.transferred_from ?? []),
    ...(event.transferred_to ?? []),
  ];
  return [...new Set(ids.filter((id) => typeof id === "string" && id && !id.startsWith("$RCAnonymousID:")))];
}

/** Reads the user's entitlement from RevenueCat and mirrors it into Firestore. Returns true if written. */
export async function syncUser(uid, env) {
  const subscriber = await fetchSubscriber(uid, env);
  const status = entitlementStatus(subscriber, env);
  const existing = await readSubscription(uid, env);

  // Nothing bought and nothing stored (e.g. RevenueCat's test event): leave no trace.
  if (!status && !existing) return false;

  // An access grant (App Review demo account, a friendly shop) outlives a cancelled purchase.
  if (existing?.source === "grant" && (!status || existing.expiresAt >= status.expiresAt)) return false;

  const doc = status ?? {
    expiresAt: new Date(0).toISOString(),
    productId: existing?.productId ?? null,
    store: existing?.store ?? null,
    environment: existing?.environment ?? null,
    willRenew: false,
    billingIssue: false,
  };
  await writeSubscription(uid, { ...doc, source: "revenuecat", updatedAt: new Date().toISOString() }, env);
  return true;
}

/** The entitlement's expiry (incl. grace period) and details, or null when the user never had it. */
export function entitlementStatus(subscriber, env) {
  const entitlement = subscriber?.entitlements?.[env.ENTITLEMENT_ID || "business"];
  if (!entitlement) return null;
  const sub = subscriber.subscriptions?.[entitlement.product_identifier] ?? {};
  if (sub.is_sandbox && env.ALLOW_SANDBOX !== "true") return null;
  const expires = [entitlement.expires_date, entitlement.grace_period_expires_date, sub.grace_period_expires_date]
    .filter(Boolean)
    .map((d) => new Date(d).toISOString())
    .sort()
    .at(-1);
  return {
    expiresAt: entitlement.expires_date === null ? FAR_FUTURE : (expires ?? new Date(0).toISOString()),
    productId: entitlement.product_identifier ?? null,
    store: sub.store ?? null,
    environment: sub.is_sandbox ? "SANDBOX" : "PRODUCTION",
    willRenew: !sub.unsubscribe_detected_at,
    billingIssue: Boolean(sub.billing_issues_detected_at),
  };
}

async function fetchSubscriber(uid, env) {
  const base = env.REVENUECAT_API_BASE || "https://api.revenuecat.com";
  const res = await fetch(`${base}/v1/subscribers/${encodeURIComponent(uid)}`, {
    headers: { Authorization: `Bearer ${env.REVENUECAT_SECRET_KEY}`, Accept: "application/json" },
  });
  if (!res.ok) throw new Error(`RevenueCat ${res.status} for ${uid}`);
  return (await res.json()).subscriber;
}

// ── Firestore REST ───────────────────────────────────────────────────────────

function docUrl(uid, env) {
  const root = env.FIRESTORE_EMULATOR_HOST
    ? `http://${env.FIRESTORE_EMULATOR_HOST}/v1`
    : "https://firestore.googleapis.com/v1";
  return `${root}/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/subscriptions/${encodeURIComponent(uid)}`;
}

async function readSubscription(uid, env) {
  const res = await fetch(docUrl(uid, env), { headers: await authHeaders(env) });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`Firestore read ${res.status}`);
  const f = (await res.json()).fields ?? {};
  return {
    expiresAt: f.expiresAt?.timestampValue ? new Date(f.expiresAt.timestampValue).toISOString() : new Date(0).toISOString(),
    source: f.source?.stringValue ?? null,
    productId: f.productId?.stringValue ?? null,
    store: f.store?.stringValue ?? null,
    environment: f.environment?.stringValue ?? null,
  };
}

async function writeSubscription(uid, data, env) {
  const value = (v) =>
    v === null || v === undefined
      ? { nullValue: null }
      : typeof v === "boolean"
        ? { booleanValue: v }
        : { stringValue: String(v) };
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    fields[k] = k === "expiresAt" || k === "updatedAt" ? { timestampValue: v } : value(v);
  }
  const res = await fetch(docUrl(uid, env), {
    method: "PATCH",
    headers: { ...(await authHeaders(env)), "Content-Type": "application/json" },
    body: JSON.stringify({ fields }),
  });
  if (!res.ok) throw new Error(`Firestore write ${res.status}: ${await res.text()}`);
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
  const der = Uint8Array.from(
    atob(privateKeyPem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "")),
    (c) => c.charCodeAt(0),
  );
  const key = await crypto.subtle.importKey("pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, [
    "sign",
  ]);
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned));
  return `${unsigned}.${base64url(new Uint8Array(sig))}`;
}

function base64url(bytes) {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/** Constant-time string comparison for the webhook secret. */
function safeEqual(a, b) {
  const x = new TextEncoder().encode(a);
  const y = new TextEncoder().encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  return diff === 0;
}

export function resetTokenCacheForTests() {
  cachedToken = null;
}
