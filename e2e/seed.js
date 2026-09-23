// Seeds two demo shops (with logos and card designs) into the running
// emulators and prints logins + tag URLs to try.
//   cd e2e && node seed.js
import { readFile } from "node:fs/promises";
import { deleteApp, initializeApp } from "firebase/app";
import { connectAuthEmulator, createUserWithEmailAndPassword, getAuth, signInWithEmailAndPassword } from "firebase/auth";
import { addDoc, collection, connectFirestoreEmulator, getDocs, getFirestore, query, serverTimestamp, updateDoc, where } from "firebase/firestore";
import { connectStorageEmulator, getDownloadURL, getStorage, ref, uploadBytes } from "firebase/storage";

const HOST = "http://localhost:5050";
const PASSWORD = "demo1234";

const shops = [
  {
    email: "demo@loyi.test",
    name: "Bakkerij Peeters",
    color: 0xffc17828,
    logo: "assets/logo-peeters.png",
    program: {
      name: "Broodjeskaart",
      stampsRequired: 5,
      rewards: [
        { id: "sandwich", title: "Free sandwich", active: true },
        { id: "coffee", title: "Free coffee", active: true },
      ],
      design: { background: 0xffc17828, background2: 0xff8d4e1a, style: "gradient", stampColor: 0xfffff4e1, stampIcon: "croissant" },
    },
  },
  {
    email: "mokka@loyi.test",
    name: "Koffiebar Mokka",
    color: 0xff263238,
    logo: "assets/logo-mokka.png",
    program: {
      name: "Koffiekaart",
      stampsRequired: 8,
      rewards: [{ id: "latte", title: "Free latte", active: true }],
      design: { background: 0xff263238, background2: null, style: "pattern", stampColor: 0xffffd699, stampIcon: "coffee" },
    },
  },
];

for (const [i, shop] of shops.entries()) {
  const app = initializeApp({ apiKey: "demo-api-key", projectId: "demo-loyi", storageBucket: "demo-loyi.appspot.com" }, `seed-${i}`);
  const auth = getAuth(app);
  connectAuthEmulator(auth, "http://127.0.0.1:9099", { disableWarnings: true });
  const db = getFirestore(app);
  connectFirestoreEmulator(db, "127.0.0.1", 8085);
  const storage = getStorage(app);
  connectStorageEmulator(storage, "127.0.0.1", 9199);

  const user = await createUserWithEmailAndPassword(auth, shop.email, PASSWORD)
    .catch(() => signInWithEmailAndPassword(auth, shop.email, PASSWORD))
    .then((c) => c.user);

  let businesses = await getDocs(query(collection(db, "businesses"), where("ownerUid", "==", user.uid)));
  const business =
    businesses.docs[0]?.ref ??
    (await addDoc(collection(db, "businesses"), { ownerUid: user.uid, name: shop.name, color: shop.color, createdAt: serverTimestamp() }));

  const logoPath = `logos/${business.id}/seed.png`;
  await uploadBytes(ref(storage, logoPath), await readFile(new URL(shop.logo, import.meta.url)), { contentType: "image/png" });
  await updateDoc(business, { name: shop.name, color: shop.color, logoUrl: await getDownloadURL(ref(storage, logoPath)), logoPath });

  const programs = await getDocs(query(collection(db, "programs"), where("businessId", "==", business.id)));
  if (programs.empty) {
    const program = await addDoc(collection(db, "programs"), {
      ...shop.program,
      businessId: business.id,
      ownerUid: user.uid,
      stampCooldownMinutes: 0,
      active: true,
      createdAt: serverTimestamp(),
    });
    for (const [type, label] of [["join", "Entrance"], ["stamp", "Counter"]]) {
      await addDoc(collection(db, "tags"), {
        businessId: business.id,
        ownerUid: user.uid,
        programId: program.id,
        type,
        label,
        active: true,
        tapCount: 0,
        createdAt: serverTimestamp(),
      });
    }
  } else {
    await updateDoc(programs.docs[0].ref, { design: shop.program.design });
  }

  const tags = await getDocs(query(collection(db, "tags"), where("ownerUid", "==", user.uid)));
  console.log(`\n${shop.name}: ${shop.email} / ${PASSWORD}  →  ${HOST}/business`);
  for (const t of tags.docs) console.log(`  ${t.get("type").padEnd(5)} tag: ${HOST}/t/${t.id}`);
  await deleteApp(app);
}
process.exit(0);
