// Gives a business owner access without a purchase: the App Review demo account,
// a pilot shop, a friend. The webhook never shortens a grant.
//
//   node grant-access.js <ownerUid> <days>                  (production)
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8085 node grant-access.js <ownerUid> <days> demo-loyi
//
// The uid is in the Firebase console under Authentication. Production needs
// GOOGLE_SERVICE_ACCOUNT=path/to/service-account.json (the same key as the Worker).
// Use 0 days to end a grant.
import { readFile } from "node:fs/promises";
import { accessToken } from "./src/index.js";

const [uid, daysArg, project = "loyi-b530b"] = process.argv.slice(2);
const days = Number(daysArg);
if (!uid || !Number.isFinite(days)) {
  console.error("Usage: node grant-access.js <ownerUid> <days> [projectId]");
  process.exit(1);
}

const emulator = process.env.FIRESTORE_EMULATOR_HOST;
if (!emulator && !process.env.GOOGLE_SERVICE_ACCOUNT) {
  console.error("Set GOOGLE_SERVICE_ACCOUNT to the service account JSON file (or FIRESTORE_EMULATOR_HOST for local).");
  process.exit(1);
}
const env = {
  FIREBASE_PROJECT_ID: project,
  FIRESTORE_EMULATOR_HOST: emulator,
  FIREBASE_SERVICE_ACCOUNT: emulator ? undefined : await readFile(process.env.GOOGLE_SERVICE_ACCOUNT, "utf8"),
};
const token = emulator ? "owner" : await accessToken(env);
const root = emulator ? `http://${emulator}/v1` : "https://firestore.googleapis.com/v1";
const expiresAt = new Date(Date.now() + days * 86400_000).toISOString();

const res = await fetch(`${root}/projects/${project}/databases/(default)/documents/subscriptions/${uid}`, {
  method: "PATCH",
  headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
  body: JSON.stringify({
    fields: {
      expiresAt: { timestampValue: expiresAt },
      source: { stringValue: "grant" },
      environment: { stringValue: "GRANT" },
      updatedAt: { timestampValue: new Date().toISOString() },
    },
  }),
});
if (!res.ok) {
  console.error(`Failed: ${res.status} ${await res.text()}`);
  process.exit(1);
}
console.log(`${uid} has access until ${expiresAt} (${project}).`);
