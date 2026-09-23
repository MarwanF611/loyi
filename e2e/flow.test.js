// End-to-end test of the Loyi backend (security rules + Cloud Functions)
// against the local emulators. Start them first from the repo root:
//   firebase emulators:start --project demo-loyi
// then: cd e2e && npm test
import { test } from "node:test";
import assert from "node:assert/strict";
import { deleteApp, initializeApp } from "firebase/app";
import {
  connectAuthEmulator,
  createUserWithEmailAndPassword,
  getAuth,
  sendSignInLinkToEmail,
  signInAnonymously,
  signInWithEmailLink,
} from "firebase/auth";
import {
  addDoc,
  collection,
  connectFirestoreEmulator,
  doc,
  getCountFromServer,
  getDoc,
  getDocs,
  getFirestore,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from "firebase/firestore";
import { connectFunctionsEmulator, getFunctions, httpsCallable } from "firebase/functions";
import { connectStorageEmulator, getDownloadURL, getStorage, ref, uploadBytes } from "firebase/storage";

const PROJECT = "demo-loyi";
const AUTH_PORT = 9099;
const run = Date.now();
const apps = [];

function client(name) {
  const app = initializeApp(
    { apiKey: "demo-api-key", projectId: PROJECT, authDomain: `${PROJECT}.firebaseapp.com`, storageBucket: `${PROJECT}.appspot.com` },
    `${name}-${run}`,
  );
  apps.push(app);
  const auth = getAuth(app);
  connectAuthEmulator(auth, `http://127.0.0.1:${AUTH_PORT}`, { disableWarnings: true });
  const db = getFirestore(app);
  connectFirestoreEmulator(db, "127.0.0.1", 8085);
  const fns = getFunctions(app, "europe-west1");
  connectFunctionsEmulator(fns, "127.0.0.1", 5001);
  const storage = getStorage(app);
  connectStorageEmulator(storage, "127.0.0.1", 9199);
  const call = (fn) => async (data) => (await httpsCallable(fns, fn)(data)).data;
  return { auth, db, storage, tap: (tagId) => call("tap")({ tagId }), redeem: call("redeem"), merge: call("mergeAccount") };
}

async function rejects(promise, code) {
  await assert.rejects(promise, (e) => {
    assert.match(String(e.code), new RegExp(code));
    return true;
  });
}

async function emailLinkSignIn(c, email) {
  await sendSignInLinkToEmail(c.auth, email, { url: "http://localhost:5050/account/finish", handleCodeInApp: true });
  const res = await fetch(`http://127.0.0.1:${AUTH_PORT}/emulator/v1/projects/${PROJECT}/oobCodes`);
  const { oobCodes } = await res.json();
  const link = oobCodes.filter((c) => c.email === email).at(-1).oobLink;
  const anonToken = c.auth.currentUser?.isAnonymous ? await c.auth.currentUser.getIdToken() : null;
  await signInWithEmailLink(c.auth, email, link);
  if (anonToken) await c.merge({ anonIdToken: anonToken });
}

test("business → client → reward flow", async (t) => {
  const biz = client("biz");
  const other = client("other");
  const alice = client("alice");
  const bob = client("bob");

  // ── Business setup ────────────────────────────────────────────────────────
  const owner = (await createUserWithEmailAndPassword(biz.auth, `owner-${run}@test.be`, "test1234")).user;
  const bizRef = await addDoc(collection(biz.db, "businesses"), {
    ownerUid: owner.uid,
    name: "Bakkerij Peeters",
    color: 0xff7c4dff,
    createdAt: serverTimestamp(),
  });
  const program = {
    businessId: bizRef.id,
    ownerUid: owner.uid,
    name: "Broodjeskaart",
    stampsRequired: 5,
    stampCooldownMinutes: 0,
    rewards: [
      { id: "sandwich", title: "Free sandwich", active: true },
      { id: "coffee", title: "Free coffee", active: false },
    ],
    active: true,
  };
  const programRef = await addDoc(collection(biz.db, "programs"), program);
  const tag = (type) =>
    addDoc(collection(biz.db, "tags"), {
      businessId: bizRef.id,
      ownerUid: owner.uid,
      programId: programRef.id,
      type,
      label: type,
      active: true,
      tapCount: 0,
      createdAt: serverTimestamp(),
    });
  const joinTag = await tag("join");
  const stampTag = await tag("stamp");

  await t.test("security rules", async () => {
    await createUserWithEmailAndPassword(other.auth, `other-${run}@test.be`, "test1234");
    // Another business can't attach programs or tags to this business.
    await rejects(addDoc(collection(other.db, "programs"), { ...program, ownerUid: other.auth.currentUser.uid }), "permission-denied");
    await rejects(getDoc(doc(other.db, "tags", stampTag.id)), "permission-denied");

    await signInAnonymously(alice.auth);
    // Anonymous clients can't create businesses, write cards, or read tags.
    await rejects(
      addDoc(collection(alice.db, "businesses"), { ownerUid: alice.auth.currentUser.uid, name: "Fake" }),
      "permission-denied",
    );
    await rejects(
      setDoc(doc(alice.db, "cards", `${programRef.id}_${alice.auth.currentUser.uid}`), { stamps: 99 }),
      "permission-denied",
    );
    await rejects(getDoc(doc(alice.db, "tags", stampTag.id)), "permission-denied");
    // Tag updates are limited to active/label.
    await rejects(updateDoc(doc(biz.db, "tags", stampTag.id), { type: "join" }), "permission-denied");
  });

  let aliceCardId;
  await t.test("join and collect stamps", async () => {
    const joined = await alice.tap(joinTag.id);
    assert.equal(joined.outcome, "joined");
    aliceCardId = joined.cardId;
    assert.equal((await alice.tap(joinTag.id)).outcome, "already_member");

    for (let i = 1; i <= 4; i++) {
      const r = await alice.tap(stampTag.id);
      assert.equal(r.outcome, "stamped");
      assert.equal(r.stamps, i);
      assert.equal(r.completedCard, false);
    }
    const full = await alice.tap(stampTag.id);
    assert.equal(full.completedCard, true);
    assert.equal(full.stamps, 0);
    assert.equal(full.rewardsAvailable, 1);

    // Bob can't read Alice's card.
    await signInAnonymously(bob.auth);
    await rejects(getDoc(doc(bob.db, "cards", aliceCardId)), "permission-denied");
  });

  await t.test("redeem a chosen reward", async () => {
    await rejects(alice.redeem({ cardId: aliceCardId, rewardId: "coffee" }), "failed-precondition"); // inactive
    await rejects(bob.redeem({ cardId: aliceCardId, rewardId: "sandwich" }), "not-found"); // not Bob's card

    // The business switches this week's reward to coffee; Alice picks it.
    await updateDoc(programRef, {
      rewards: [
        { id: "sandwich", title: "Free sandwich", active: false },
        { id: "coffee", title: "Free coffee", active: true },
      ],
    });
    const r = await alice.redeem({ cardId: aliceCardId, rewardId: "coffee" });
    assert.equal(r.rewardTitle, "Free coffee");
    await rejects(alice.redeem({ cardId: aliceCardId, rewardId: "coffee" }), "failed-precondition"); // none left
  });

  await t.test("cooldown and inactive tags", async () => {
    // Alice was stamped seconds ago, so with a 30 min cooldown the next tap is refused.
    await updateDoc(programRef, { stampCooldownMinutes: 30 });
    const again = await alice.tap(stampTag.id);
    assert.equal(again.outcome, "cooldown");
    assert.ok(again.retryAfterMs > 29 * 60_000);

    await updateDoc(doc(biz.db, "tags", stampTag.id), { active: false });
    await rejects(alice.tap(stampTag.id), "not-found");
    await updateDoc(doc(biz.db, "tags", stampTag.id), { active: true });
    await updateDoc(programRef, { stampCooldownMinutes: 0 });
  });

  await t.test("business insights", async () => {
    const owned = (c) => query(collection(biz.db, c), where("ownerUid", "==", owner.uid), where("businessId", "==", bizRef.id));
    assert.equal((await getCountFromServer(owned("cards"))).data().count, 1);
    assert.equal((await getCountFromServer(owned("stampEvents"))).data().count, 5);
    const redemptions = await getDocs(owned("redemptions"));
    assert.deepEqual(redemptions.docs.map((d) => d.get("rewardTitle")), ["Free coffee"]);
  });

  await t.test("card design validation", async () => {
    const design = { background: 0xff6d4c41, background2: null, style: "pattern", stampColor: 0xffffffff, stampIcon: "coffee" };
    await updateDoc(programRef, { design });
    await rejects(updateDoc(programRef, { design: { ...design, style: "neon" } }), "permission-denied");
    await rejects(updateDoc(programRef, { design: { ...design, script: "<b>" } }), "permission-denied");
    await rejects(updateDoc(programRef, { design: { ...design, background: "brown" } }), "permission-denied");
    assert.deepEqual((await getDoc(programRef)).get("design"), design);
  });

  await t.test("logo upload rules", async () => {
    const png = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 0]);
    const path = `logos/${bizRef.id}/${run}.png`;
    await uploadBytes(ref(biz.storage, path), png, { contentType: "image/png" });
    const url = await getDownloadURL(ref(biz.storage, path));
    await updateDoc(bizRef, { logoUrl: url, logoPath: path });
    assert.equal((await getDoc(doc(alice.db, "businesses", bizRef.id))).get("logoUrl"), url); // public

    // Other businesses, clients, wrong types and huge files are refused.
    await rejects(uploadBytes(ref(other.storage, `logos/${bizRef.id}/x.png`), png, { contentType: "image/png" }), "unauthorized");
    await rejects(uploadBytes(ref(alice.storage, `logos/${bizRef.id}/x.png`), png, { contentType: "image/png" }), "unauthorized");
    await rejects(uploadBytes(ref(biz.storage, `logos/${bizRef.id}/x.svg`), png, { contentType: "image/svg+xml" }), "unauthorized");
    await rejects(
      uploadBytes(ref(biz.storage, `logos/${bizRef.id}/big.png`), new Uint8Array(1024 * 1024 + 1), { contentType: "image/png" }),
      "unauthorized",
    );
    // logoUrl must point at our own bucket.
    await rejects(updateDoc(bizRef, { logoUrl: "https://evil.example/pixel.gif", logoPath: path }), "permission-denied");
  });

  await t.test("one client, cards from several shops", async () => {
    const biz2 = client("biz2");
    const owner2 = (await createUserWithEmailAndPassword(biz2.auth, `owner2-${run}@test.be`, "test1234")).user;
    const shop2 = await addDoc(collection(biz2.db, "businesses"), { ownerUid: owner2.uid, name: "Koffiebar Mokka", color: 0xff6d4c41 });
    const program2 = await addDoc(collection(biz2.db, "programs"), { ...program, businessId: shop2.id, ownerUid: owner2.uid, name: "Koffiekaart" });
    const stamp2 = await addDoc(collection(biz2.db, "tags"), {
      businessId: shop2.id,
      ownerUid: owner2.uid,
      programId: program2.id,
      type: "stamp",
      label: "Counter",
      active: true,
      tapCount: 0,
    });

    const r = await alice.tap(stamp2.id);
    assert.equal(r.outcome, "stamped");
    assert.equal(r.stamps, 1);

    const mine = await getDocs(query(collection(alice.db, "cards"), where("clientUid", "==", alice.auth.currentUser.uid)));
    assert.deepEqual(new Set(mine.docs.map((d) => d.get("businessId"))), new Set([bizRef.id, shop2.id]));

    // Each shop only sees its own clients' cards.
    const cardsOf = (c, uid, bid) => query(collection(c.db, "cards"), where("ownerUid", "==", uid), where("businessId", "==", bid));
    assert.equal((await getCountFromServer(cardsOf(biz, owner.uid, bizRef.id))).data().count, 1);
    assert.equal((await getCountFromServer(cardsOf(biz2, owner2.uid, shop2.id))).data().count, 1);
    await rejects(getDoc(doc(biz2.db, "cards", aliceCardId)), "permission-denied");
  });

  await t.test("save cards with email and merge devices", async () => {
    const email = `bob-${run}@test.be`;
    // Phone 1: Bob collects 3 stamps anonymously, then saves with his email.
    for (let i = 0; i < 3; i++) await bob.tap(stampTag.id);
    const bobAnonUid = bob.auth.currentUser.uid;
    await emailLinkSignIn(bob, email);
    const bobUid = bob.auth.currentUser.uid;
    assert.notEqual(bobUid, bobAnonUid);
    let card = await getDoc(doc(bob.db, "cards", `${programRef.id}_${bobUid}`));
    assert.equal(card.get("stamps"), 3);

    // Phone 2: Bob collects 4 more anonymously, then signs in with the same email.
    const phone2 = client("bob-phone2");
    await signInAnonymously(phone2.auth);
    for (let i = 0; i < 4; i++) await phone2.tap(stampTag.id);
    await emailLinkSignIn(phone2, email);
    assert.equal(phone2.auth.currentUser.uid, bobUid);
    card = await getDoc(doc(phone2.db, "cards", `${programRef.id}_${bobUid}`));
    assert.equal(card.get("stamps"), 2); // 3 + 4 = 7 → 1 full card + 2
    assert.equal(card.get("rewardsAvailable"), 1);
  });
});

test.after(async () => {
  await Promise.all(apps.map((a) => deleteApp(a)));
});
