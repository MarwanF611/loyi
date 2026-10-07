// Tests the billing Worker against the Firestore emulator, with a fake Stripe API
// and fake Google signing keys for Firebase ID tokens.
// Start the emulators first (repo root): firebase emulators:start --project demo-loyi
// then: cd billing-worker && npm test
import { test } from "node:test";
import assert from "node:assert/strict";
import { createHmac, createSign, createVerify, generateKeyPairSync } from "node:crypto";
import worker, { accessToken, formEncode, resetCachesForTests, subscriptionStatus } from "../src/index.js";

const PROJECT = "demo-loyi";
const env = {
  FIREBASE_PROJECT_ID: PROJECT,
  FIRESTORE_EMULATOR_HOST: "127.0.0.1:8085",
  STRIPE_SECRET_KEY: "sk_test_fake",
  STRIPE_WEBHOOK_SECRET: "whsec_test_secret",
  STRIPE_PRICE_ID: "price_monthly",
  STRIPE_API_BASE: "https://stripe.fake",
  APP_URL: "https://loyi.example",
  ALLOWED_ORIGINS: "https://loyi.example,http://localhost:5050",
};
const run = Date.now();
const DAY = 86_400;
const now = () => Math.floor(Date.now() / 1000);

// ── Fake Google keys: tokens signed like Firebase Auth does ─────────────────
const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
const jwk = { ...publicKey.export({ format: "jwk" }), kid: "test-kid", alg: "RS256", use: "sig" };
const b64 = (o) => Buffer.from(JSON.stringify(o)).toString("base64url");
function idToken(uid, { provider = "password", project = PROJECT, exp = now() + 3600, key = privateKey } = {}) {
  const head = b64({ alg: "RS256", kid: "test-kid", typ: "JWT" });
  const body = b64({
    iss: `https://securetoken.google.com/${project}`,
    aud: project,
    sub: uid,
    iat: now() - 10,
    exp,
    email: `${uid}@shop.test`,
    firebase: { sign_in_provider: provider },
  });
  const sig = createSign("RSA-SHA256").update(`${head}.${body}`).sign(key).toString("base64url");
  return `${head}.${body}.${sig}`;
}

// ── Fake Stripe ──────────────────────────────────────────────────────────────
const stripe = { subscriptions: {}, calls: [], deleted: [] };
const realFetch = globalThis.fetch;
globalThis.fetch = async (input, init = {}) => {
  const url = new URL(String(input));
  if (url.hostname === "www.googleapis.com") {
    return Response.json({ keys: [jwk] }, { headers: { "Cache-Control": "public, max-age=600" } });
  }
  if (url.hostname !== "stripe.fake") return realFetch(input, init);
  assert.equal(new Headers(init.headers).get("Authorization"), "Bearer sk_test_fake");
  const method = init.method ?? "GET";
  const params = new URLSearchParams(init.body ?? "");
  stripe.calls.push({ method, path: url.pathname, params });
  if (url.pathname === "/v1/checkout/sessions") return Response.json({ url: `https://checkout.stripe.fake/${params.get("client_reference_id")}` });
  if (url.pathname === "/v1/billing_portal/sessions") return Response.json({ url: `https://portal.stripe.fake/${params.get("customer")}` });
  if (url.pathname === "/v1/subscriptions" && method === "GET") {
    const customer = url.searchParams.get("customer");
    return Response.json({ data: Object.values(stripe.subscriptions).filter((s) => s.customer === customer) });
  }
  const id = url.pathname.split("/").pop();
  if (method === "DELETE") {
    stripe.deleted.push(id);
    stripe.subscriptions[id] = { ...stripe.subscriptions[id], status: "canceled", ended_at: now() };
    return Response.json(stripe.subscriptions[id]);
  }
  const sub = stripe.subscriptions[id];
  return sub ? Response.json(sub) : Response.json({ error: { message: "No such subscription" } }, { status: 404 });
};

function subscription(id, uid, fields = {}) {
  stripe.subscriptions[id] = {
    id,
    object: "subscription",
    customer: `cus_${uid}`,
    status: "active",
    livemode: false,
    current_period_end: now() + 30 * DAY,
    cancel_at_period_end: false,
    metadata: uid ? { firebase_uid: uid } : {},
    ...fields,
  };
  return stripe.subscriptions[id];
}

// ── Helpers ──────────────────────────────────────────────────────────────────
function call(path, { token, origin = "https://loyi.example", method = "POST" } = {}) {
  const headers = { Origin: origin };
  if (token) headers.Authorization = `Bearer ${token}`;
  return worker.fetch(new Request(`https://billing.example${path}`, { method, headers }), env);
}

function webhook(type, object, { secret = env.STRIPE_WEBHOOK_SECRET, t = now() } = {}) {
  const body = JSON.stringify({ id: `evt_${Math.random()}`, type, data: { object } });
  const sig = createHmac("sha256", secret).update(`${t}.${body}`).digest("hex");
  return worker.fetch(
    new Request("https://billing.example/stripe", {
      method: "POST",
      headers: { "Stripe-Signature": `t=${t},v1=${sig}` },
      body,
    }),
    env,
  );
}

async function doc(path) {
  const res = await realFetch(`http://127.0.0.1:8085/v1/projects/${PROJECT}/databases/(default)/documents/${path}`, {
    headers: { Authorization: "Bearer owner" },
  });
  if (res.status === 404) return null;
  const f = (await res.json()).fields;
  return Object.fromEntries(Object.entries(f).map(([k, v]) => [k, Object.values(v)[0]]));
}

// ── Tests ────────────────────────────────────────────────────────────────────

test("webhooks need a valid, fresh Stripe signature", async () => {
  const sub = subscription(`sub_sig_${run}`, `sig-${run}`);
  assert.equal((await webhook("customer.subscription.updated", sub, { secret: "whsec_wrong" })).status, 400);
  assert.equal((await webhook("customer.subscription.updated", sub, { t: now() - 3600 })).status, 400);
  assert.equal(await doc(`subscriptions/sig-${run}`), null);
});

test("checkout: only signed-in shop accounts, with a genuine token", async () => {
  const uid = `shop-${run}`;
  assert.equal((await call("/checkout")).status, 401);
  assert.equal((await call("/checkout", { token: idToken(uid, { provider: "anonymous" }) })).status, 403);
  assert.equal((await call("/checkout", { token: idToken(uid, { project: "someone-else" }) })).status, 401);
  assert.equal((await call("/checkout", { token: idToken(uid, { exp: now() - 10 }) })).status, 401);
  const forged = generateKeyPairSync("rsa", { modulusLength: 2048 }).privateKey;
  assert.equal((await call("/checkout", { token: idToken(uid, { key: forged }) })).status, 401);

  const res = await call("/checkout", { token: idToken(uid) });
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { url: `https://checkout.stripe.fake/${uid}` });
  const p = stripe.calls.at(-1).params;
  assert.equal(p.get("mode"), "subscription");
  assert.equal(p.get("line_items[0][price]"), "price_monthly");
  assert.equal(p.get("subscription_data[metadata][firebase_uid]"), uid);
  assert.equal(p.get("customer_email"), `${uid}@shop.test`);
  assert.equal(p.get("success_url"), "https://loyi.example/business?checkout=done");
  assert.equal(p.get("locale"), "auto"); // no language given: Stripe follows the browser

  // The app's language is passed on; anything else falls back to auto.
  await call("/checkout?locale=fr", { token: idToken(`${uid}-fr`) });
  assert.equal(stripe.calls.at(-1).params.get("locale"), "fr");
  await call("/checkout?locale=xx", { token: idToken(`${uid}-xx`) });
  assert.equal(stripe.calls.at(-1).params.get("locale"), "auto");
});

test("payment → shop switched on; renewal, cancellation and failed payments are mirrored", async () => {
  const uid = `paid-${run}`;
  const sub = subscription(`sub_paid_${run}`, uid);
  const session = { object: "checkout.session", subscription: sub.id, client_reference_id: uid };
  assert.deepEqual(await (await webhook("checkout.session.completed", session)).json(), { ok: true, updated: [uid] });

  let s = await doc(`subscriptions/${uid}`);
  assert.ok(new Date(s.expiresAt) > new Date(Date.now() + 29 * DAY * 1000));
  assert.deepEqual([s.store, s.source, s.environment, s.willRenew, s.billingIssue], ["stripe", "stripe", "TEST", true, false]);
  assert.equal((await doc(`billing/${uid}`)).customerId, `cus_${uid}`);

  // Already subscribed: no second checkout.
  assert.equal((await call("/checkout", { token: idToken(uid) })).status, 409);

  subscription(sub.id, uid, { cancel_at_period_end: true });
  await webhook("customer.subscription.updated", stripe.subscriptions[sub.id]);
  assert.equal((await doc(`subscriptions/${uid}`)).willRenew, false);

  subscription(sub.id, uid, { status: "past_due" });
  await webhook("invoice.payment_failed", { object: "invoice", subscription: sub.id });
  s = await doc(`subscriptions/${uid}`);
  assert.equal(s.billingIssue, true);
  assert.ok(new Date(s.expiresAt) > new Date(Date.now() + 36 * DAY * 1000)); // period end + grace

  // Newer webhook API versions put an invoice's subscription under parent.
  subscription(sub.id, uid, { status: "active" });
  await webhook("invoice.paid", { object: "invoice", parent: { subscription_details: { subscription: sub.id } } });
  assert.equal((await doc(`subscriptions/${uid}`)).billingIssue, false);

  subscription(sub.id, uid, { status: "canceled", ended_at: now() - 5 });
  await webhook("customer.subscription.deleted", stripe.subscriptions[sub.id]);
  assert.ok(new Date((await doc(`subscriptions/${uid}`)).expiresAt) <= new Date());

  // Resubscribing reuses the Stripe customer.
  await call("/checkout", { token: idToken(uid) });
  assert.equal(stripe.calls.at(-1).params.get("customer"), `cus_${uid}`);
});

test("an old cancelled subscription doesn't overwrite the newer one", async () => {
  const uid = `two-${run}`;
  const fresh = subscription(`sub_new_${run}`, uid);
  await webhook("customer.subscription.created", fresh);
  const old = subscription(`sub_old_${run}`, uid, { status: "canceled", ended_at: now() - DAY });
  assert.deepEqual(await (await webhook("customer.subscription.deleted", old)).json(), { ok: true, updated: [] });
  assert.ok(new Date((await doc(`subscriptions/${uid}`)).expiresAt) > new Date());
});

test("subscriptions not created by Loyi's checkout are ignored", async () => {
  const sub = subscription(`sub_foreign_${run}`, null);
  assert.deepEqual(await (await webhook("customer.subscription.created", sub)).json(), { ok: true, updated: [] });
  assert.deepEqual(await (await webhook("payment_intent.succeeded", { object: "payment_intent" })).json(), {
    ok: true,
    ignored: "payment_intent.succeeded",
  });
});

test("a manual access grant isn't shortened by Stripe", async () => {
  const uid = `granted-${run}`;
  const far = new Date(Date.now() + 365 * DAY * 1000).toISOString();
  await realFetch(`http://127.0.0.1:8085/v1/projects/${PROJECT}/databases/(default)/documents/subscriptions/${uid}`, {
    method: "PATCH",
    headers: { Authorization: "Bearer owner", "Content-Type": "application/json" },
    body: JSON.stringify({ fields: { expiresAt: { timestampValue: far }, source: { stringValue: "grant" } } }),
  });
  await webhook("customer.subscription.created", subscription(`sub_grant_${run}`, uid));
  assert.equal((await doc(`subscriptions/${uid}`)).source, "grant");
});

test("portal: only for shops with a Stripe customer", async () => {
  assert.equal((await call("/portal", { token: idToken(`nobody-${run}`) })).status, 404);
  const uid = `portal-${run}`;
  await webhook("customer.subscription.created", subscription(`sub_portal_${run}`, uid));
  const res = await call("/portal", { token: idToken(uid) });
  assert.deepEqual(await res.json(), { url: `https://portal.stripe.fake/cus_${uid}` });
  assert.equal(stripe.calls.at(-1).params.get("return_url"), "https://loyi.example/business/subscribe");
});

test("account deletion cancels the subscription and forgets the billing link", async () => {
  const uid = `leaving-${run}`;
  const sub = subscription(`sub_leaving_${run}`, uid);
  await webhook("customer.subscription.created", sub);
  const res = await call("/delete-account", { token: idToken(uid) });
  assert.deepEqual(await res.json(), { ok: true, cancelled: 1 });
  assert.ok(stripe.deleted.includes(sub.id));
  assert.equal(await doc(`subscriptions/${uid}`), null);
  assert.equal(await doc(`billing/${uid}`), null);
  // Clients (anonymous) can call it too; nothing to cancel.
  assert.deepEqual(await (await call("/delete-account", { token: idToken(`client-${run}`, { provider: "anonymous" }) })).json(), {
    ok: true,
    cancelled: 0,
  });
});

test("CORS only for Loyi's own sites; the return URL follows the calling site", async () => {
  const pre = await call("/checkout", { method: "OPTIONS", origin: "http://localhost:5050" });
  assert.equal(pre.status, 204);
  assert.equal(pre.headers.get("Access-Control-Allow-Origin"), "http://localhost:5050");
  const evil = await call("/checkout", { method: "OPTIONS", origin: "https://evil.example" });
  assert.equal(evil.headers.get("Access-Control-Allow-Origin"), null);

  await call("/checkout", { token: idToken(`local-${run}`), origin: "http://localhost:5050" });
  assert.equal(stripe.calls.at(-1).params.get("cancel_url"), "http://localhost:5050/business");
  await call("/checkout", { token: idToken(`evil-${run}`), origin: "https://evil.example" });
  assert.equal(stripe.calls.at(-1).params.get("cancel_url"), "https://loyi.example/business");
});

test("status mapping", () => {
  const t = now();
  const base = { current_period_end: t + DAY };
  assert.equal(subscriptionStatus({ ...base, status: "trialing" }).active, true);
  assert.equal(subscriptionStatus({ ...base, status: "incomplete" }).active, false);
  assert.equal(subscriptionStatus({ ...base, status: "unpaid" }).billingIssue, true);
  // Newer Stripe API versions keep the period end on the subscription items.
  const items = subscriptionStatus({ status: "active", items: { data: [{ current_period_end: t + 2 * DAY }] } });
  assert.equal(items.expiresAt, new Date((t + 2 * DAY) * 1000).toISOString());
});

test("Stripe form encoding", () => {
  assert.equal(
    decodeURIComponent(formEncode({ a: 1, line_items: [{ price: "p", quantity: 1 }], m: { k: "v" }, skip: null })),
    "a=1&line_items[0][price]=p&line_items[0][quantity]=1&m[k]=v",
  );
});

test("service account token: signed RS256 JWT exchanged at Google's token endpoint", async () => {
  const sa = {
    client_email: "billing@loyi-b530b.iam.gserviceaccount.com",
    private_key: privateKey.export({ type: "pkcs8", format: "pem" }),
    token_uri: "https://oauth.fake/token",
  };
  let assertion;
  const before = globalThis.fetch;
  globalThis.fetch = async (url, init) => {
    assert.equal(String(url), "https://oauth.fake/token");
    assertion = new URLSearchParams(init.body).get("assertion");
    return Response.json({ access_token: "ya29.fake", expires_in: 3600 });
  };
  try {
    resetCachesForTests();
    assert.equal(await accessToken({ FIREBASE_SERVICE_ACCOUNT: JSON.stringify(sa) }), "ya29.fake");
  } finally {
    globalThis.fetch = before;
    resetCachesForTests();
  }
  const [h, c, s] = assertion.split(".");
  assert.equal(JSON.parse(Buffer.from(c, "base64url")).scope, "https://www.googleapis.com/auth/datastore");
  assert.ok(createVerify("RSA-SHA256").update(`${h}.${c}`).verify(publicKey, Buffer.from(s, "base64url")));
});
