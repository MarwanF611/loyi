// Tests the webhook Worker against the Firestore emulator with a fake RevenueCat API.
// Start the emulators first (repo root): firebase emulators:start --project demo-loyi
// then: cd billing-worker && npm test
import { test } from "node:test";
import assert from "node:assert/strict";
import { generateKeyPairSync, createVerify } from "node:crypto";
import worker, { accessToken, affectedUsers, resetTokenCacheForTests } from "../src/index.js";

const env = {
  FIREBASE_PROJECT_ID: "demo-loyi",
  FIRESTORE_EMULATOR_HOST: "127.0.0.1:8085",
  ENTITLEMENT_ID: "business",
  ALLOW_SANDBOX: "true",
  REVENUECAT_WEBHOOK_AUTH: "Bearer test-webhook-secret",
  REVENUECAT_SECRET_KEY: "sk_test",
  REVENUECAT_API_BASE: "https://revenuecat.fake",
};

// Fake RevenueCat: subscribers[uid] is what GET /v1/subscribers/{uid} returns.
const subscribers = {};
const realFetch = globalThis.fetch;
globalThis.fetch = async (input, init) => {
  const url = String(input);
  if (url.startsWith("https://revenuecat.fake/v1/subscribers/")) {
    assert.equal(new Headers(init.headers).get("Authorization"), "Bearer sk_test");
    const uid = decodeURIComponent(url.split("/").pop());
    return Response.json({ subscriber: subscribers[uid] ?? { entitlements: {}, subscriptions: {} } });
  }
  return realFetch(input, init);
};

const run = Date.now();
const iso = (ms) => new Date(Date.now() + ms).toISOString();
const DAY = 86400_000;

function webhook(event, auth = env.REVENUECAT_WEBHOOK_AUTH) {
  return worker.fetch(
    new Request("https://billing.example/revenuecat", {
      method: "POST",
      headers: { Authorization: auth, "Content-Type": "application/json" },
      body: JSON.stringify({ event }),
    }),
    env,
  );
}

async function stored(uid) {
  const res = await realFetch(
    `http://127.0.0.1:8085/v1/projects/demo-loyi/databases/(default)/documents/subscriptions/${uid}`,
    { headers: { Authorization: "Bearer owner" } },
  );
  if (res.status === 404) return null;
  const f = (await res.json()).fields;
  return Object.fromEntries(Object.entries(f).map(([k, v]) => [k, Object.values(v)[0]]));
}

function subscribed(expires, extra = {}) {
  return {
    entitlements: { business: { expires_date: expires, product_identifier: "loyi_business_monthly" } },
    subscriptions: { loyi_business_monthly: { store: "app_store", is_sandbox: false, ...extra } },
  };
}

test("rejects anything that isn't an authenticated RevenueCat webhook", async () => {
  assert.equal((await webhook({ app_user_id: "x" }, "Bearer wrong")).status, 401);
  assert.equal((await webhook({ app_user_id: "x" }, "")).status, 401);
  const get = await worker.fetch(new Request("https://billing.example/revenuecat"), env);
  assert.equal(get.status, 404);
});

test("a purchase switches the business on; expiry and cancellation are mirrored", async () => {
  const uid = `owner-${run}`;
  subscribers[uid] = subscribed(iso(30 * DAY));
  const res = await webhook({ type: "INITIAL_PURCHASE", app_user_id: uid });
  assert.deepEqual(await res.json(), { ok: true, updated: [uid] });
  let doc = await stored(uid);
  assert.ok(new Date(doc.expiresAt) > new Date(Date.now() + 29 * DAY));
  assert.deepEqual([doc.store, doc.environment, doc.willRenew, doc.source], ["app_store", "PRODUCTION", true, "revenuecat"]);

  // Cancelled: still active until the period ends, but won't renew.
  subscribers[uid] = subscribed(iso(10 * DAY), { unsubscribe_detected_at: iso(0) });
  await webhook({ type: "CANCELLATION", app_user_id: uid });
  doc = await stored(uid);
  assert.equal(doc.willRenew, false);

  // Expired.
  subscribers[uid] = subscribed(iso(-DAY));
  await webhook({ type: "EXPIRATION", app_user_id: uid });
  assert.ok(new Date((await stored(uid)).expiresAt) < new Date());
});

test("the webhook body can't grant anything: status always comes from the RevenueCat API", async () => {
  const uid = `forger-${run}`;
  const res = await webhook({
    type: "INITIAL_PURCHASE",
    app_user_id: uid,
    expiration_at_ms: Date.now() + 999 * DAY,
    entitlement_ids: ["business"],
  });
  assert.deepEqual(await res.json(), { ok: true, updated: [] });
  assert.equal(await stored(uid), null);
});

test("grace period extends access; lifetime access never expires", async () => {
  const grace = `grace-${run}`;
  subscribers[grace] = {
    entitlements: {
      business: {
        expires_date: iso(-DAY),
        grace_period_expires_date: iso(6 * DAY),
        product_identifier: "loyi_business_monthly",
      },
    },
    subscriptions: { loyi_business_monthly: { store: "play_store", billing_issues_detected_at: iso(-DAY) } },
  };
  await webhook({ type: "BILLING_ISSUE", app_user_id: grace });
  const doc = await stored(grace);
  assert.ok(new Date(doc.expiresAt) > new Date(Date.now() + 5 * DAY));
  assert.equal(doc.billingIssue, true);

  const lifetime = `lifetime-${run}`;
  subscribers[lifetime] = subscribed(null);
  await webhook({ type: "NON_RENEWING_PURCHASE", app_user_id: lifetime });
  assert.match((await stored(lifetime)).expiresAt, /^9999-/);
});

test("sandbox purchases count only when ALLOW_SANDBOX is on", async () => {
  const uid = `sandbox-${run}`;
  subscribers[uid] = subscribed(iso(DAY), { is_sandbox: true });
  const off = await worker.fetch(
    new Request("https://billing.example/revenuecat", {
      method: "POST",
      headers: { Authorization: env.REVENUECAT_WEBHOOK_AUTH },
      body: JSON.stringify({ event: { app_user_id: uid } }),
    }),
    { ...env, ALLOW_SANDBOX: "false" },
  );
  assert.deepEqual(await off.json(), { ok: true, updated: [] });
  await webhook({ app_user_id: uid });
  assert.equal((await stored(uid)).environment, "SANDBOX");
});

test("a manual access grant isn't overwritten by a shorter purchase", async () => {
  const uid = `granted-${run}`;
  await realFetch(
    `http://127.0.0.1:8085/v1/projects/demo-loyi/databases/(default)/documents/subscriptions/${uid}`,
    {
      method: "PATCH",
      headers: { Authorization: "Bearer owner", "Content-Type": "application/json" },
      body: JSON.stringify({
        fields: { expiresAt: { timestampValue: iso(365 * DAY) }, source: { stringValue: "grant" } },
      }),
    },
  );
  subscribers[uid] = subscribed(iso(-DAY));
  await webhook({ type: "EXPIRATION", app_user_id: uid });
  assert.equal((await stored(uid)).source, "grant");
});

test("transfers update both users; anonymous ids are ignored", () => {
  assert.deepEqual(
    affectedUsers({
      app_user_id: "$RCAnonymousID:abc",
      transferred_from: ["old-uid", "$RCAnonymousID:def"],
      transferred_to: ["new-uid"],
    }),
    ["old-uid", "new-uid"],
  );
});

test("service account token: signed RS256 JWT exchanged at Google's token endpoint", async () => {
  const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
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
    resetTokenCacheForTests();
    assert.equal(await accessToken({ FIREBASE_SERVICE_ACCOUNT: JSON.stringify(sa) }), "ya29.fake");
  } finally {
    globalThis.fetch = before;
    resetTokenCacheForTests();
  }
  const [h, c, s] = assertion.split(".");
  const claims = JSON.parse(Buffer.from(c, "base64url"));
  assert.equal(claims.iss, sa.client_email);
  assert.equal(claims.scope, "https://www.googleapis.com/auth/datastore");
  const ok = createVerify("RSA-SHA256").update(`${h}.${c}`).verify(publicKey, Buffer.from(s, "base64url"));
  assert.ok(ok, "signature verifies with the service account's public key");
});
