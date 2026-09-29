// End-to-end test of firestore.rules against the local emulators. Loyi runs on
// the free Spark plan (no Cloud Functions), so the rules are what stops clients
// from cheating: this file performs the app's own writes and a set of attacks.
// Start the emulators first from the repo root:
//   firebase emulators:start --project demo-loyi
// then: cd e2e && npm test
import { test } from "node:test";
import assert from "node:assert/strict";
import { deleteApp, initializeApp } from "firebase/app";
import { connectAuthEmulator, createUserWithEmailAndPassword, getAuth, signInAnonymously } from "firebase/auth";
import {
  Bytes,
  Timestamp as ClientTimestamp,
  addDoc,
  collection,
  connectFirestoreEmulator,
  deleteDoc,
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
  writeBatch,
} from "firebase/firestore";
import { initializeApp as initializeAdmin } from "firebase-admin/app";
import { Timestamp, getFirestore as getAdminFirestore } from "firebase-admin/firestore";
import { mergeCard, redeem, tap, writeTransfer } from "./client-ops.js";

const PROJECT = "demo-loyi";
process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8085";
// Stands in for the billing webhook, which writes subscriptions with a service account.
const admin = getAdminFirestore(initializeAdmin({ projectId: PROJECT }, `admin-${Date.now()}`));
const DAY = 24 * 60 * 60 * 1000;
const subscribe = (ownerUid, days = 30) =>
  admin.doc(`subscriptions/${ownerUid}`).set({ expiresAt: Timestamp.fromMillis(Date.now() + days * DAY) });
const run = Date.now();
const apps = [];

function client(name) {
  const app = initializeApp({ apiKey: "demo-api-key", projectId: PROJECT }, `${name}-${run}`);
  apps.push(app);
  const auth = getAuth(app);
  connectAuthEmulator(auth, "http://127.0.0.1:9099", { disableWarnings: true });
  const db = getFirestore(app);
  connectFirestoreEmulator(db, "127.0.0.1", 8085);
  return { auth, db, uid: () => auth.currentUser.uid };
}

async function denied(promise) {
  await assert.rejects(promise, (e) => {
    assert.match(String(e.code ?? e.message), /permission-denied|PERMISSION_DENIED/);
    return true;
  });
}

test("Loyi rules: full flow and abuse attempts", async (t) => {
  const biz = client("biz");
  const other = client("other");
  const alice = client("alice");
  const bob = client("bob");

  // ── Business setup ────────────────────────────────────────────────────────
  const owner = (await createUserWithEmailAndPassword(biz.auth, `owner-${run}@test.be`, "test1234")).user;
  const bizRef = await addDoc(collection(biz.db, "businesses"), {
    ownerUid: owner.uid,
    name: "Bakkerij Peeters",
    color: 0xffc17828,
    createdAt: serverTimestamp(),
  });
  const program = {
    businessId: bizRef.id,
    ownerUid: owner.uid,
    name: "Broodjeskaart",
    stampsRequired: 5,
    stampCooldownMinutes: 0,
    rewards: [
      { id: "broodje", title: "Gratis broodje", active: true },
      { id: "koffie", title: "Gratis koffie", active: false },
    ],
    active: true,
  };
  const programRef = await addDoc(collection(biz.db, "programs"), program);
  const newTag = (type, active = true) =>
    addDoc(collection(biz.db, "tags"), {
      businessId: bizRef.id,
      ownerUid: owner.uid,
      programId: programRef.id,
      type,
      label: type,
      active,
      tapCount: 0,
      createdAt: serverTimestamp(),
    });
  await subscribe(owner.uid);
  const joinTag = await newTag("join");
  const stampTag = await newTag("stamp");
  const offTag = await newTag("stamp", false);

  await signInAnonymously(alice.auth);
  await signInAnonymously(bob.auth);
  const aliceCard = doc(alice.db, "cards", `${programRef.id}_${alice.uid()}`);
  const eventFields = (cardId, clientUid) => ({
    businessId: bizRef.id,
    ownerUid: owner.uid,
    programId: programRef.id,
    cardId,
    clientUid,
    tagId: stampTag.id,
    createdAt: serverTimestamp(),
  });

  await t.test("business data rules", async () => {
    await createUserWithEmailAndPassword(other.auth, `other-${run}@test.be`, "test1234");
    await denied(addDoc(collection(other.db, "programs"), { ...program, ownerUid: other.uid() }));
    await denied(addDoc(collection(alice.db, "businesses"), { ownerUid: alice.uid(), name: "Fake", color: 1 }));
    // Clients may look up a tag they tapped, but never list them.
    assert.equal((await getDoc(doc(alice.db, "tags", stampTag.id))).get("type"), "stamp");
    await denied(getDocs(query(collection(alice.db, "tags"), where("ownerUid", "==", owner.uid))));
    await denied(updateDoc(doc(biz.db, "tags", stampTag.id), { type: "join" }));
  });

  await t.test("join, then stamps until the card is full", async () => {
    assert.equal((await tap(alice.db, alice.uid(), joinTag.id)).outcome, "joined");
    assert.equal((await tap(alice.db, alice.uid(), joinTag.id)).outcome, "already_member");
    for (let i = 1; i <= 4; i++) {
      const r = await tap(alice.db, alice.uid(), stampTag.id);
      assert.equal(r.stamps, i);
      assert.equal(r.completedCard, false);
    }
    const full = await tap(alice.db, alice.uid(), stampTag.id);
    assert.deepEqual([full.stamps, full.rewardsAvailable, full.completedCard], [0, 1, true]);
    assert.equal((await getDoc(doc(biz.db, "tags", stampTag.id))).get("tapCount"), 5);
  });

  await t.test("first tap on a stamp tag joins and stamps", async () => {
    const r = await tap(bob.db, bob.uid(), stampTag.id);
    assert.deepEqual([r.outcome, r.stamps], ["stamped", 1]);
  });

  await t.test("abuse: stamps are exactly +1 from an active stamp tag", async () => {
    const now = serverTimestamp();
    const card = (await getDoc(aliceCard)).data();
    const stampWith = (tagId, extra = {}) =>
      updateDoc(aliceCard, {
        stamps: card.stamps + 1,
        totalStamps: card.totalStamps + 1,
        lastStampAt: now,
        lastTagId: tagId,
        updatedAt: now,
        ...extra,
      });
    await denied(stampWith(stampTag.id, { stamps: card.stamps + 2 })); // +2
    await denied(stampWith(joinTag.id)); // join tag used as stamp tag
    await denied(stampWith(offTag.id)); // disabled tag
    await denied(updateDoc(aliceCard, { rewardsAvailable: 9, updatedAt: now })); // free rewards
    await denied(updateDoc(aliceCard, { clientUid: bob.uid(), updatedAt: now })); // give away
    // Bob can't read Alice's card or create one in her name.
    await denied(getDoc(doc(bob.db, "cards", aliceCard.id)));
    await denied(
      setDoc(doc(bob.db, "cards", `${programRef.id}_${alice.uid()}`), {
        clientUid: alice.uid(),
        businessId: bizRef.id,
        ownerUid: owner.uid,
        programId: programRef.id,
        stamps: 0,
        rewardsAvailable: 0,
        totalStamps: 0,
        totalRedeemed: 0,
        lastStampAt: null,
        lastTagId: joinTag.id,
        createdAt: now,
        updatedAt: now,
      }),
    );
  });

  await t.test("abuse: one stamp event per stamp, never on its own", async () => {
    const card = (await getDoc(aliceCard)).data();
    const nextId = `${aliceCard.id}_${card.totalStamps + 1}`;
    await denied(setDoc(doc(alice.db, "stampEvents", nextId), eventFields(aliceCard.id, alice.uid())));
    // A real stamp plus a second, fake event in the same batch.
    const now = serverTimestamp();
    const batch = writeBatch(alice.db);
    batch.update(aliceCard, {
      stamps: card.stamps + 1,
      totalStamps: card.totalStamps + 1,
      lastStampAt: now,
      lastTagId: stampTag.id,
      updatedAt: now,
    });
    batch.set(doc(alice.db, "stampEvents", nextId), eventFields(aliceCard.id, alice.uid()));
    batch.set(doc(alice.db, "stampEvents", `${aliceCard.id}_fake`), eventFields(aliceCard.id, alice.uid()));
    await denied(batch.commit());
  });

  await t.test("redeem a chosen, active reward", async () => {
    await denied(redeem(alice.db, aliceCard.id, "koffie")); // inactive reward
    const now = serverTimestamp();
    const fake = writeBatch(alice.db);
    fake.update(aliceCard, { rewardsAvailable: 0, totalRedeemed: 1, updatedAt: now });
    fake.set(doc(alice.db, "redemptions", `${aliceCard.id}_r1`), {
      businessId: bizRef.id,
      ownerUid: owner.uid,
      programId: programRef.id,
      cardId: aliceCard.id,
      clientUid: alice.uid(),
      rewardId: "broodje",
      rewardTitle: "Gratis iPhone", // not a real reward
      createdAt: now,
    });
    await denied(fake.commit());

    // The business switches this week's reward; Alice redeems it.
    await updateDoc(programRef, {
      rewards: [
        { id: "broodje", title: "Gratis broodje", active: false },
        { id: "koffie", title: "Gratis koffie", active: true },
      ],
    });
    assert.equal(await redeem(alice.db, aliceCard.id, "koffie"), "Gratis koffie");
    const card = (await getDoc(aliceCard)).data();
    assert.deepEqual([card.rewardsAvailable, card.totalRedeemed], [0, 1]);
    await denied(redeem(alice.db, aliceCard.id, "koffie")); // nothing left
  });

  await t.test("cooldown is enforced with server time; disabled tags are refused", async () => {
    await updateDoc(programRef, { stampCooldownMinutes: 30 });
    await denied(tap(alice.db, alice.uid(), stampTag.id));
    await updateDoc(programRef, { stampCooldownMinutes: 0 });
    await updateDoc(doc(biz.db, "tags", stampTag.id), { active: false });
    await assert.rejects(tap(alice.db, alice.uid(), stampTag.id));
    await updateDoc(doc(biz.db, "tags", stampTag.id), { active: true });
  });

  await t.test("business insights", async () => {
    const owned = (db, c) =>
      query(collection(db, c), where("ownerUid", "==", owner.uid), where("businessId", "==", bizRef.id));
    assert.equal((await getCountFromServer(owned(biz.db, "cards"))).data().count, 2);
    assert.equal((await getCountFromServer(owned(biz.db, "stampEvents"))).data().count, 6); // Alice 5 + Bob 1
    const redemptions = await getDocs(owned(biz.db, "redemptions"));
    assert.deepEqual(redemptions.docs.map((d) => d.get("rewardTitle")), ["Gratis koffie"]);
    await denied(getDocs(owned(alice.db, "stampEvents"))); // clients can't read the business log
  });

  await t.test("merge a device's anonymous cards into an existing account", async () => {
    // Carol has an account with 3 stamps; on a new phone she collects 4 more anonymously.
    const carol = client("carol");
    const carolUid = (await createUserWithEmailAndPassword(carol.auth, `carol-${run}@test.be`, "test1234")).user.uid;
    for (let i = 0; i < 3; i++) await tap(carol.db, carolUid, stampTag.id);
    const phone = client("carol-phone");
    await signInAnonymously(phone.auth);
    const anonUid = phone.uid();
    for (let i = 0; i < 4; i++) await tap(phone.db, anonUid, stampTag.id);
    const sourceId = `${programRef.id}_${anonUid}`;

    // Without a transfer from the anonymous session, nobody can take the cards.
    await denied(mergeCard(carol.db, sourceId, anonUid, carolUid));
    await writeTransfer(phone.db, anonUid, carolUid);
    await denied(mergeCard(bob.db, sourceId, anonUid, bob.uid())); // not the named account

    await mergeCard(carol.db, sourceId, anonUid, carolUid);
    const merged = (await getDoc(doc(carol.db, "cards", `${programRef.id}_${carolUid}`))).data();
    assert.deepEqual([merged.stamps, merged.rewardsAvailable, merged.totalStamps], [2, 1, 7]); // 3 + 4 = 7
    assert.equal((await getDoc(doc(phone.db, "cards", sourceId))).exists(), false); // source removed
    await assert.rejects(mergeCard(carol.db, sourceId, anonUid, carolUid)); // can't merge twice
  });

  await t.test("abuse: merging with made-up numbers is refused", async () => {
    const dave = client("dave");
    const daveUid = (await createUserWithEmailAndPassword(dave.auth, `dave-${run}@test.be`, "test1234")).user.uid;
    const phone = client("dave-phone");
    await signInAnonymously(phone.auth);
    await tap(phone.db, phone.uid(), stampTag.id);
    await writeTransfer(phone.db, phone.uid(), daveUid);
    const now = serverTimestamp();
    const batch = writeBatch(dave.db);
    batch.set(doc(dave.db, "cards", `${programRef.id}_${daveUid}`), {
      clientUid: daveUid,
      businessId: bizRef.id,
      ownerUid: owner.uid,
      programId: programRef.id,
      stamps: 4,
      rewardsAvailable: 3,
      totalStamps: 99,
      totalRedeemed: 0,
      lastStampAt: null,
      mergedFrom: phone.uid(),
      createdAt: now,
      updatedAt: now,
    });
    batch.delete(doc(dave.db, "cards", `${programRef.id}_${phone.uid()}`));
    await denied(batch.commit());
    // Only the anonymous session itself may write its transfer.
    await denied(setDoc(doc(dave.db, "transfers", phone.uid()), { toUid: daveUid, createdAt: serverTimestamp() }));
  });

  await t.test("card design validation", async () => {
    const design = { background: 0xff6d4c41, background2: null, style: "pattern", stampColor: 0xffffffff, stampIcon: "coffee" };
    await updateDoc(programRef, { design });
    await denied(updateDoc(programRef, { design: { ...design, style: "neon" } }));
    await denied(updateDoc(programRef, { design: { ...design, script: "<b>" } }));
  });

  await t.test("logos live in Firestore: public, owner-only, small images", async () => {
    const png = Bytes.fromUint8Array(new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0]));
    const logoRef = doc(biz.db, "logos", bizRef.id);
    const logo = (data, contentType = "image/png") => ({ data, contentType, updatedAt: serverTimestamp() });
    await setDoc(logoRef, logo(png));
    await updateDoc(bizRef, { logoVersion: 1 });
    assert.equal((await getDoc(doc(alice.db, "logos", bizRef.id))).get("contentType"), "image/png");
    await denied(setDoc(doc(other.db, "logos", bizRef.id), logo(png)));
    await denied(setDoc(logoRef, logo(png, "image/svg+xml")));
    await denied(setDoc(logoRef, logo(Bytes.fromUint8Array(new Uint8Array(200 * 1024 + 1)))));
    await denied(updateDoc(bizRef, { logoVersion: "x" }));
    await deleteDoc(logoRef);
  });

  await t.test("subscriptions: tags only work while the business is subscribed", async () => {
    const zoe = client("zoe");
    const zoeUid = (await createUserWithEmailAndPassword(zoe.auth, `zoe-${run}@test.be`, "test1234")).user.uid;
    const shop = await addDoc(collection(zoe.db, "businesses"), { ownerUid: zoeUid, name: "Zoe", color: 1 });
    const prog = await addDoc(collection(zoe.db, "programs"), {
      ...program,
      businessId: shop.id,
      ownerUid: zoeUid,
      stampsRequired: 1,
    });
    const tag = (type) =>
      addDoc(collection(zoe.db, "tags"), {
        businessId: shop.id,
        ownerUid: zoeUid,
        programId: prog.id,
        type,
        label: type,
        active: true,
        tapCount: 0,
        createdAt: serverTimestamp(),
      });
    const join = await tag("join");
    const stamp = await tag("stamp");
    const eve = client("eve");
    await signInAnonymously(eve.auth);

    // Set up but never subscribed: no joining, no stamps.
    await denied(tap(eve.db, eve.uid(), join.id));
    await denied(tap(eve.db, eve.uid(), stamp.id));

    // Nobody but the webhook can grant a subscription, and nobody can list them.
    const fake = { expiresAt: ClientTimestamp.fromMillis(Date.now() + 365 * DAY) };
    await denied(setDoc(doc(zoe.db, "subscriptions", zoeUid), fake));
    await denied(setDoc(doc(eve.db, "subscriptions", zoeUid), fake));
    await denied(getDocs(collection(zoe.db, "subscriptions")));

    await subscribe(zoeUid);
    assert.equal((await tap(eve.db, eve.uid(), stamp.id)).rewardsAvailable, 1); // 1-stamp card: full

    // Expired: tags pause, but a reward the client already earned can still be used.
    await subscribe(zoeUid, -1);
    assert.equal((await getDoc(doc(eve.db, "subscriptions", zoeUid))).exists(), true); // readable
    await denied(tap(eve.db, eve.uid(), stamp.id));
    assert.equal(await redeem(eve.db, `${prog.id}_${eve.uid()}`, "broodje"), "Gratis broodje");
  });

  await t.test("brand colours: 1 to 3 colour values", async () => {
    await updateDoc(bizRef, { colors: [0xffff5a3c, 0xff263238, 0xffffffff], color: 0xffff5a3c });
    await denied(updateDoc(bizRef, { colors: [] }));
    await denied(updateDoc(bizRef, { colors: [1, 2, 3, 4] }));
    await denied(updateDoc(bizRef, { colors: ["red"] }));
    await denied(updateDoc(bizRef, { colors: [1, "red"] }));
  });

  await t.test("data export: a client reads their own stamps, not someone else's", async () => {
    const mine = await getDocs(query(collection(alice.db, "stampEvents"), where("clientUid", "==", alice.uid())));
    assert.ok(mine.size >= 5);
    await denied(getDocs(query(collection(alice.db, "stampEvents"), where("clientUid", "==", bob.uid()))));
  });

  await t.test("abuse: programs and tags only accept known fields", async () => {
    await denied(updateDoc(programRef, { name: "x".repeat(61) }));
    await denied(updateDoc(programRef, { active: "yes" }));
    await denied(updateDoc(programRef, { secret: true }));
    await denied(
      addDoc(collection(biz.db, "tags"), {
        businessId: bizRef.id,
        ownerUid: owner.uid,
        programId: programRef.id,
        type: "stamp",
        label: "Counter",
        active: true,
        tapCount: 500, // fake popularity
        createdAt: serverTimestamp(),
      }),
    );
    await denied(updateDoc(doc(biz.db, "tags", stampTag.id), { label: "" }));
  });

  await t.test("account deletion: clients and businesses remove only their own data", async () => {
    // A client deletes their own card; nobody else can.
    const bobCard = doc(bob.db, "cards", `${programRef.id}_${bob.uid()}`);
    await denied(deleteDoc(doc(alice.db, "cards", bobCard.id)));
    await deleteDoc(bobCard);

    // Another business can't delete this business's data.
    await denied(deleteDoc(doc(other.db, "businesses", bizRef.id)));
    await denied(deleteDoc(doc(other.db, "programs", programRef.id)));
    await denied(deleteDoc(doc(other.db, "tags", joinTag.id)));
    await denied(deleteDoc(doc(other.db, "cards", aliceCard.id)));
    await denied(deleteDoc(doc(alice.db, "stampEvents", `${aliceCard.id}_1`))); // clients can't erase the log

    // The owner deletes everything, logs first and the business last.
    const mine = async (c) => (await getDocs(query(collection(biz.db, c), where("ownerUid", "==", owner.uid)))).docs;
    for (const c of ["stampEvents", "redemptions", "cards", "tags", "programs"]) {
      const batch = writeBatch(biz.db);
      for (const d of await mine(c)) batch.delete(d.ref);
      await batch.commit();
      assert.equal((await mine(c)).length, 0, c);
    }
    await deleteDoc(bizRef);
    assert.equal((await getDoc(bizRef)).exists(), false);
  });
});

test.after(async () => {
  await Promise.all(apps.map((a) => deleteApp(a)));
});
