// Seeds a demo business into the running emulators and prints tag URLs to try.
//   cd e2e && node seed.js
import { initializeApp } from "firebase/app";
import { connectAuthEmulator, createUserWithEmailAndPassword, getAuth, signInWithEmailAndPassword } from "firebase/auth";
import { addDoc, collection, connectFirestoreEmulator, getDocs, getFirestore, query, serverTimestamp, where } from "firebase/firestore";

const HOST = "http://localhost:5050";
const EMAIL = "demo@loyi.test";
const PASSWORD = "demo1234";

const app = initializeApp({ apiKey: "demo-api-key", projectId: "demo-loyi" });
const auth = getAuth(app);
connectAuthEmulator(auth, "http://127.0.0.1:9099", { disableWarnings: true });
const db = getFirestore(app);
connectFirestoreEmulator(db, "127.0.0.1", 8085);

const user = await createUserWithEmailAndPassword(auth, EMAIL, PASSWORD)
  .catch(() => signInWithEmailAndPassword(auth, EMAIL, PASSWORD))
  .then((c) => c.user);

const existing = await getDocs(query(collection(db, "tags"), where("ownerUid", "==", user.uid)));
if (existing.empty) {
  const business = await addDoc(collection(db, "businesses"), {
    ownerUid: user.uid,
    name: "Bakkerij Peeters",
    color: 0xff7c4dff,
    createdAt: serverTimestamp(),
  });
  const program = await addDoc(collection(db, "programs"), {
    businessId: business.id,
    ownerUid: user.uid,
    name: "Broodjeskaart",
    stampsRequired: 5,
    stampCooldownMinutes: 0,
    rewards: [
      { id: "sandwich", title: "Free sandwich", active: true },
      { id: "coffee", title: "Free coffee", active: true },
    ],
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
}

const tags = await getDocs(query(collection(db, "tags"), where("ownerUid", "==", user.uid)));
console.log(`Business login: ${EMAIL} / ${PASSWORD}  →  ${HOST}/business`);
for (const t of tags.docs) console.log(`${t.get("type").padEnd(5)} tag: ${HOST}/t/${t.id}`);
process.exit(0);
