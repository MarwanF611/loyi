// Seeds a realistic demo world into the running emulators: three shops with
// logos and card designs, a week of stamp activity, and a showcase client.
//   cd e2e && node seed.js
// Used for local testing and for the marketing screenshots (../marketing).
import { randomBytes } from "node:crypto";
import { readFile } from "node:fs/promises";

process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8085";
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";

const { initializeApp } = await import("firebase-admin/app");
const { getAuth } = await import("firebase-admin/auth");
const { getFirestore, Timestamp } = await import("firebase-admin/firestore");

const PROJECT = "demo-loyi";
const HOST = "http://localhost:5050";
const PASSWORD = "demo1234";
initializeApp({ projectId: PROJECT });
const db = getFirestore();
const auth = getAuth();

// Fixed ids so the marketing script can find everything again.
export const DEMO = {
  client: { uid: "demo-client-sam", email: "sam@loyi.test" },
  shops: [
    {
      id: "bakkerij-peeters",
      owner: { uid: "demo-owner-peeters", email: "demo@loyi.test" },
      name: "Bakkerij Peeters",
      color: 0xffc17828,
      logo: "assets/logo-peeters.png",
      program: {
        id: "peeters-broodjeskaart",
        name: "Broodjeskaart",
        stampsRequired: 5,
        stampCooldownMinutes: 30,
        rewards: [
          { id: "broodje", title: "Gratis broodje", active: true },
          { id: "koffie", title: "Gratis koffie", active: true },
        ],
        design: { background: 0xffc17828, background2: 0xff8d4e1a, style: "gradient", stampColor: 0xfffff4e1, stampIcon: "croissant" },
      },
      tags: { join: "Pk7wQ2mXn4Rt9LbA3cZe", stamp: "Hs8vD1qLr6Yp0KaN5tWu" },
      clients: 42,
      week: [12, 17, 15, 21, 9, 26, 19],
      peaks: [8, 12],
      showcase: { stamps: 4, daysAgo: 2 },
    },
    {
      id: "koffiebar-mokka",
      owner: { uid: "demo-owner-mokka", email: "mokka@loyi.test" },
      name: "Koffiebar Mokka",
      color: 0xff263238,
      logo: "assets/logo-mokka.png",
      program: {
        id: "mokka-koffiekaart",
        name: "Koffiekaart",
        stampsRequired: 8,
        stampCooldownMinutes: 30,
        rewards: [{ id: "latte", title: "Gratis latte", active: true }],
        design: { background: 0xff263238, background2: null, style: "pattern", stampColor: 0xffffd699, stampIcon: "coffee" },
      },
      tags: { join: "Mx3cV9nB2kQ7eR4tY1uI", stamp: "Zq5wE8rT2yU6iO9pA3sD" },
      clients: 64,
      week: [22, 25, 19, 30, 28, 35, 24],
      peaks: [9, 15],
      showcase: { stamps: 4, daysAgo: 1 },
    },
    {
      id: "bloemen-lies",
      owner: { uid: "demo-owner-lies", email: "lies@loyi.test" },
      name: "Bloemen Lies",
      color: 0xff2e7d5b,
      logo: "assets/logo-lies.png",
      program: {
        id: "lies-bloemenkaart",
        name: "Bloemenkaart",
        stampsRequired: 6,
        stampCooldownMinutes: 60,
        rewards: [{ id: "boeket", title: "Gratis boeketje", active: true }],
        design: { background: 0xff2e7d5b, background2: 0xff1b5e44, style: "gradient", stampColor: 0xffffe4ec, stampIcon: "flower" },
      },
      tags: { join: "Lf4gH7jK1lZ3xC6vB9nM", stamp: "Qw2eR5tY8uI1oP4aS7dF" },
      clients: 23,
      week: [4, 6, 3, 8, 11, 9, 7],
      peaks: [11, 17],
      announcement: { title: "De lentebloemen zijn binnen", body: "Tulpen en ranonkels de hele week. Toon je kaart voor een dubbele stempel op elk boeket." },
      showcase: { stamps: 2, daysAgo: 4 },
    },
  ],
};

async function upsertUser({ uid, email }) {
  try {
    await auth.updateUser(uid, { email, password: PASSWORD });
  } catch {
    await auth.createUser({ uid, email, password: PASSWORD, emailVerified: true });
  }
}

/** Stores the logo in Firestore (`logos/{businessId}`), like the app does. */
async function saveLogo(shopId, file) {
  await db.doc(`logos/${shopId}`).set({
    data: await readFile(new URL(file, import.meta.url)),
    contentType: "image/png",
    updatedAt: Timestamp.now(),
  });
  return Date.now();
}

/** A timestamp `daysAgo` days back at a plausible shop hour (never in the future). */
function atShopHour(daysAgo) {
  const now = new Date();
  const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - daysAgo, 7, 30);
  const latest = daysAgo === 0 ? now.getTime() - 60_000 : d.getTime() + 10.5 * 3600_000;
  return Timestamp.fromMillis(d.getTime() + Math.random() * Math.max(0, latest - d.getTime()));
}

async function deleteWhere(collection, field, value) {
  const snap = await db.collection(collection).where(field, "==", value).get();
  for (let i = 0; i < snap.docs.length; i += 400) {
    const batch = db.batch();
    snap.docs.slice(i, i + 400).forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }
}

async function seedShop(shop) {
  const { owner, program } = shop;
  await upsertUser(owner);
  for (const c of ["cards", "stampEvents", "redemptions", "messages"]) await deleteWhere(c, "businessId", shop.id);

  await db.doc(`businesses/${shop.id}`).set({
    ownerUid: owner.uid,
    name: shop.name,
    color: shop.color,
    colors: [shop.color],
    logoVersion: await saveLogo(shop.id, shop.logo),
    createdAt: Timestamp.fromDate(new Date(Date.now() - 60 * 86400_000)),
  });
  // Demo shops are subscribed for a year (in production the billing webhook writes this).
  await db.doc(`subscriptions/${owner.uid}`).set({
    expiresAt: Timestamp.fromDate(new Date(Date.now() + 365 * 86400_000)),
    environment: "DEMO",
    updatedAt: Timestamp.now(),
  });
  await db.doc(`programs/${program.id}`).set({
    businessId: shop.id,
    ownerUid: owner.uid,
    name: program.name,
    stampsRequired: program.stampsRequired,
    stampCooldownMinutes: program.stampCooldownMinutes,
    rewards: program.rewards,
    design: program.design,
    active: true,
    createdAt: Timestamp.fromDate(new Date(Date.now() - 60 * 86400_000)),
  });
  const totalStamps = shop.week.reduce((a, b) => a + b, 0);
  if (shop.announcement) {
    await db.collection("messages").add({
      businessId: shop.id,
      ownerUid: owner.uid,
      programId: null,
      audience: "all",
      active: true,
      endsAt: Timestamp.fromMillis(Date.now() + 14 * 86400_000),
      createdAt: Timestamp.fromMillis(Date.now() - 86400_000),
      updatedAt: Timestamp.now(),
      ...shop.announcement,
    });
  }
  // A follow-up message for clients who haven't been back in a while.
  await db.collection("messages").add({
    businessId: shop.id,
    ownerUid: owner.uid,
    programId: null,
    title: "We missen je!",
    body: "Toon je kaart deze week aan de toog en krijg een dubbele stempel.",
    audience: "slipping",
    active: true,
    endsAt: Timestamp.fromMillis(Date.now() + 10 * 86400_000),
    createdAt: Timestamp.fromMillis(Date.now() - 2 * 86400_000),
    updatedAt: Timestamp.now(),
  });
  for (const [type, label] of [["join", "Ingang"], ["stamp", "Toog"]]) {
    await db.doc(`tags/${shop.tags[type]}`).set({
      businessId: shop.id,
      ownerUid: owner.uid,
      programId: program.id,
      type,
      label,
      active: true,
      tapCount: type === "stamp" ? totalStamps : shop.clients,
      lastTapAt: atShopHour(0),
      createdAt: Timestamp.fromDate(new Date(Date.now() - 60 * 86400_000)),
    });
  }

  // Clients with a realistic history: regulars, occasional visitors and people who
  // stopped coming, with stamp and reward logs that add up to their cards.
  const writes = [];
  for (let n = 0; n < shop.clients; n++) {
    const uid = `demo-${randomBytes(6).toString("hex")}`;
    const cardId = `${program.id}_${uid}`;
    const joinedDaysAgo = Math.floor(Math.random() ** 1.4 * 150);
    const kind = Math.random();
    const gap = kind < 0.35 ? 3 + Math.random() * 4 : kind < 0.75 ? 9 + Math.random() * 14 : 999; // regular, occasional, one-off
    const stopsDaysAgo = Math.random() < 0.3 ? Math.floor(Math.random() * joinedDaysAgo) : 0; // some stop coming
    const visits = [];
    for (let d = joinedDaysAgo; d >= stopsDaysAgo; d -= Math.max(1, Math.round(gap * (0.6 + Math.random() * 0.8)))) {
      visits.push(atBusyHour(d, shop.peaks));
    }
    visits.sort((a, b) => a.toMillis() - b.toMillis());
    const total = visits.length;
    const earned = Math.floor(total / program.stampsRequired);
    const unused = earned > 0 && Math.random() < 0.3 ? 1 : 0;
    const base = { businessId: shop.id, ownerUid: owner.uid, programId: program.id, cardId, clientUid: uid };
    writes.push([
      `cards/${cardId}`,
      {
        clientUid: uid,
        businessId: shop.id,
        ownerUid: owner.uid,
        programId: program.id,
        stamps: total % program.stampsRequired,
        rewardsAvailable: unused,
        totalStamps: total,
        totalRedeemed: earned - unused,
        lastStampAt: visits.at(-1),
        createdAt: visits[0],
        updatedAt: visits.at(-1),
      },
    ]);
    visits.forEach((at, i) => {
      writes.push([`stampEvents/${cardId}_${i + 1}`, { ...base, tagId: shop.tags.stamp, createdAt: at }]);
    });
    for (let r = 0; r < earned - unused; r++) {
      const reward = program.rewards[r % program.rewards.length];
      const at = visits[Math.min(visits.length - 1, (r + 1) * program.stampsRequired)];
      writes.push([
        `redemptions/${cardId}_r${r + 1}`,
        { ...base, rewardId: reward.id, rewardTitle: reward.title, createdAt: at },
      ]);
    }
  }
  for (let i = 0; i < writes.length; i += 450) {
    const batch = db.batch();
    for (const [path, data] of writes.slice(i, i + 450)) batch.set(db.doc(path), data);
    await batch.commit();
  }
}

/** A timestamp `daysAgo` days back, clustered around the shop's busy hours (Saturdays busier). */
function atBusyHour(daysAgo, peaks) {
  const now = new Date();
  const day = new Date(now.getFullYear(), now.getMonth(), now.getDate() - daysAgo);
  if (day.getDay() === 0 && Math.random() < 0.7) day.setDate(day.getDate() - 1); // mostly closed on Sunday
  const peak = peaks[Math.random() < 0.6 ? 0 : 1];
  const hour = Math.min(19.5, Math.max(7, peak + (Math.random() + Math.random() + Math.random() - 1.5) * 2.2));
  const at = day.getTime() + hour * 3600_000;
  return Timestamp.fromMillis(Math.min(at, now.getTime() - 60_000));
}

async function seedShowcaseClient() {
  const { uid } = DEMO.client;
  await upsertUser(DEMO.client);
  for (const shop of DEMO.shops) {
    const { program, showcase } = shop;
    const at = Timestamp.fromDate(new Date(Date.now() - showcase.daysAgo * 86400_000));
    await db.doc(`cards/${program.id}_${uid}`).set({
      clientUid: uid,
      businessId: shop.id,
      ownerUid: shop.owner.uid,
      programId: program.id,
      stamps: showcase.stamps,
      rewardsAvailable: 0,
      totalStamps: showcase.stamps + program.stampsRequired * 2,
      totalRedeemed: 2,
      lastStampAt: at,
      createdAt: Timestamp.fromDate(new Date(Date.now() - 40 * 86400_000)),
      updatedAt: at,
    });
  }
}

for (const shop of DEMO.shops) await seedShop(shop);
await seedShowcaseClient();

console.log(`Demo client: ${DEMO.client.email} / ${PASSWORD}`);
for (const shop of DEMO.shops) {
  console.log(`\n${shop.name}: ${shop.owner.email} / ${PASSWORD}  →  ${HOST}/business`);
  console.log(`  join  tag: ${HOST}/t/${shop.tags.join}`);
  console.log(`  stamp tag: ${HOST}/t/${shop.tags.stamp}`);
}
process.exit(0);
