// JS mirror of the app's client-side writes (app/lib/services/api.dart and
// auth_service.dart), used to test firestore.rules end to end. Keep in sync.
import { doc, getDoc, increment, runTransaction, serverTimestamp, setDoc } from "firebase/firestore";

export async function tap(db, uid, tagId) {
  const tagRef = doc(db, "tags", tagId);
  const tag = (await getDoc(tagRef)).data();
  if (!tag?.active) throw new Error("tag not active");
  const program = { id: tag.programId, ...(await getDoc(doc(db, "programs", tag.programId))).data() };
  const cardId = `${program.id}_${uid}`;
  const cardRef = doc(db, "cards", cardId);

  return runTransaction(db, async (tx) => {
    const snap = await tx.get(cardRef);
    const card = snap.exists() ? snap.data() : null;
    const now = serverTimestamp();
    const base = { clientUid: uid, businessId: program.businessId, ownerUid: program.ownerUid, programId: program.id };

    if (tag.type === "join") {
      if (card) return { cardId, outcome: "already_member" };
      tx.set(cardRef, {
        ...base,
        stamps: 0,
        rewardsAvailable: 0,
        totalStamps: 0,
        totalRedeemed: 0,
        lastStampAt: null,
        lastTagId: tagId,
        createdAt: now,
        updatedAt: now,
      });
      tx.update(tagRef, { tapCount: increment(1), lastTapAt: now });
      return { cardId, outcome: "joined" };
    }

    const next = (card?.stamps ?? 0) + 1;
    const stamps = next % program.stampsRequired;
    const rewardsAvailable = (card?.rewardsAvailable ?? 0) + Math.floor(next / program.stampsRequired);
    const totalStamps = (card?.totalStamps ?? 0) + 1;
    const stamp = { stamps, rewardsAvailable, totalStamps, lastStampAt: now, lastTagId: tagId, updatedAt: now };
    if (card) tx.update(cardRef, stamp);
    else tx.set(cardRef, { ...base, ...stamp, totalRedeemed: 0, createdAt: now });
    tx.set(doc(db, "stampEvents", `${cardId}_${totalStamps}`), {
      businessId: program.businessId,
      ownerUid: program.ownerUid,
      programId: program.id,
      cardId,
      clientUid: uid,
      tagId,
      createdAt: now,
    });
    tx.update(tagRef, { tapCount: increment(1), lastTapAt: now });
    return {
      cardId,
      outcome: "stamped",
      stamps,
      rewardsAvailable,
      completedCard: rewardsAvailable > (card?.rewardsAvailable ?? 0),
    };
  });
}

export async function redeem(db, cardId, rewardId) {
  const cardRef = doc(db, "cards", cardId);
  return runTransaction(db, async (tx) => {
    const card = (await tx.get(cardRef)).data();
    const program = (await tx.get(doc(db, "programs", card.programId))).data();
    const reward = program.rewards.find((r) => r.id === rewardId);
    const totalRedeemed = card.totalRedeemed + 1;
    const now = serverTimestamp();
    tx.update(cardRef, { rewardsAvailable: card.rewardsAvailable - 1, totalRedeemed, updatedAt: now });
    tx.set(doc(db, "redemptions", `${cardId}_r${totalRedeemed}`), {
      businessId: card.businessId,
      ownerUid: card.ownerUid,
      programId: card.programId,
      cardId,
      clientUid: card.clientUid,
      rewardId: reward.id,
      rewardTitle: reward.title,
      createdAt: now,
    });
    return reward.title;
  });
}

/** Step 2 of the merge: the anonymous session names the target account. */
export const writeTransfer = (db, anonUid, toUid) =>
  setDoc(doc(db, "transfers", anonUid), { toUid, createdAt: serverTimestamp() });

/** Step 3: signed in as the target account, merge one source card into mine and delete it. */
export async function mergeCard(db, sourceId, anonUid, me) {
  const sourceRef = doc(db, "cards", sourceId);
  return runTransaction(db, async (tx) => {
    const src = (await tx.get(sourceRef)).data();
    const program = (await tx.get(doc(db, "programs", src.programId))).data();
    const targetRef = doc(db, "cards", `${src.programId}_${me}`);
    const targetSnap = await tx.get(targetRef);
    const now = serverTimestamp();
    if (targetSnap.exists()) {
      const t = targetSnap.data();
      const sum = t.stamps + src.stamps;
      tx.update(targetRef, {
        stamps: sum % program.stampsRequired,
        rewardsAvailable: t.rewardsAvailable + src.rewardsAvailable + Math.floor(sum / program.stampsRequired),
        totalStamps: t.totalStamps + src.totalStamps,
        totalRedeemed: t.totalRedeemed + src.totalRedeemed,
        mergedFrom: anonUid,
        updatedAt: now,
      });
    } else {
      tx.set(targetRef, {
        clientUid: me,
        businessId: src.businessId,
        ownerUid: src.ownerUid,
        programId: src.programId,
        stamps: src.stamps,
        rewardsAvailable: src.rewardsAvailable,
        totalStamps: src.totalStamps,
        totalRedeemed: src.totalRedeemed,
        lastStampAt: src.lastStampAt ?? null,
        mergedFrom: anonUid,
        createdAt: now,
        updatedAt: now,
      });
    }
    tx.delete(sourceRef);
  });
}

