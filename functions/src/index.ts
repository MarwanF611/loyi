import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { setGlobalOptions } from "firebase-functions/options";
import { addStamp, cooldownRemainingMs, mergeProgress, normalize } from "./stamping";

initializeApp();
setGlobalOptions({ region: "europe-west1", maxInstances: 10 });

const db = getFirestore();

interface Tag {
  businessId: string;
  ownerUid: string;
  programId: string;
  type: "join" | "stamp";
  active: boolean;
}

interface Reward {
  id: string;
  title: string;
  active: boolean;
}

interface Program {
  businessId: string;
  ownerUid: string;
  name: string;
  stampsRequired: number;
  stampCooldownMinutes: number;
  rewards: Reward[];
  active: boolean;
}

interface Card {
  clientUid: string;
  businessId: string;
  ownerUid: string;
  programId: string;
  stamps: number;
  rewardsAvailable: number;
  totalStamps: number;
  totalRedeemed: number;
  lastStampAt: Timestamp | null;
}

const cardId = (programId: string, uid: string) => `${programId}_${uid}`;

function requireUid(auth: { uid: string } | undefined): string {
  if (!auth) throw new HttpsError("unauthenticated", "Sign in first.");
  return auth.uid;
}

function requireString(value: unknown, name: string, maxLength = 200): string {
  if (typeof value !== "string" || value.length === 0 || value.length > maxLength) {
    throw new HttpsError("invalid-argument", `${name} is required.`);
  }
  return value;
}

/**
 * Called when a client taps (or scans) a Loyi tag. Tapping any tag joins the
 * program; tapping a stamp tag also adds one stamp.
 */
export const tap = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const tagId = requireString(request.data?.tagId, "tagId");

  return db.runTransaction(async (tx) => {
    const tagSnap = await tx.get(db.collection("tags").doc(tagId));
    const tag = tagSnap.data() as Tag | undefined;
    if (!tag || !tag.active) throw new HttpsError("not-found", "This tag is not active.");

    const programSnap = await tx.get(db.collection("programs").doc(tag.programId));
    const program = programSnap.data() as Program | undefined;
    if (!program || !program.active) throw new HttpsError("failed-precondition", "This loyalty card is paused.");

    const cardRef = db.collection("cards").doc(cardId(tag.programId, uid));
    const cardSnap = await tx.get(cardRef);
    const existing = cardSnap.data() as Card | undefined;
    const now = Timestamp.now();

    let card: Card = existing ?? {
      clientUid: uid,
      businessId: tag.businessId,
      ownerUid: program.ownerUid,
      programId: tag.programId,
      stamps: 0,
      rewardsAvailable: 0,
      totalStamps: 0,
      totalRedeemed: 0,
      lastStampAt: null,
    };
    let outcome: "joined" | "already_member" | "stamped" | "cooldown" = existing ? "already_member" : "joined";
    let completedCard = false;
    let retryAfterMs = 0;

    if (tag.type === "stamp") {
      retryAfterMs = cooldownRemainingMs(
        card.lastStampAt?.toMillis() ?? null,
        program.stampCooldownMinutes ?? 0,
        now.toMillis(),
      );
      if (retryAfterMs > 0) {
        outcome = "cooldown";
      } else {
        const next = addStamp(card, program.stampsRequired);
        completedCard = next.completed > 0;
        card = {
          ...card,
          stamps: next.stamps,
          rewardsAvailable: next.rewardsAvailable,
          totalStamps: card.totalStamps + 1,
          lastStampAt: now,
        };
        outcome = "stamped";
        tx.create(db.collection("stampEvents").doc(), {
          businessId: tag.businessId,
          ownerUid: program.ownerUid,
          programId: tag.programId,
          cardId: cardRef.id,
          clientUid: uid,
          tagId,
          createdAt: now,
        });
      }
    } else if (existing) {
      // Apply any stampsRequired change the business made since the last visit.
      const n = normalize(card, program.stampsRequired);
      card = { ...card, stamps: n.stamps, rewardsAvailable: n.rewardsAvailable };
    }

    tx.set(cardRef, { ...card, createdAt: existing ? cardSnap.get("createdAt") : now, updatedAt: now });
    tx.update(tagSnap.ref, { lastTapAt: now, tapCount: FieldValue.increment(1) });

    return {
      cardId: cardRef.id,
      outcome,
      completedCard,
      retryAfterMs,
      stamps: card.stamps,
      rewardsAvailable: card.rewardsAvailable,
      stampsRequired: program.stampsRequired,
    };
  });
});

/** Client spends one banked full card on a reward of their choice. */
export const redeem = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const id = requireString(request.data?.cardId, "cardId");
  const rewardId = requireString(request.data?.rewardId, "rewardId");

  return db.runTransaction(async (tx) => {
    const cardRef = db.collection("cards").doc(id);
    const cardSnap = await tx.get(cardRef);
    const card = cardSnap.data() as Card | undefined;
    if (!card || card.clientUid !== uid) throw new HttpsError("not-found", "Card not found.");

    const program = (await tx.get(db.collection("programs").doc(card.programId))).data() as Program | undefined;
    if (!program) throw new HttpsError("not-found", "Card not found.");

    const { stamps, rewardsAvailable } = normalize(card, program.stampsRequired);
    if (rewardsAvailable < 1) throw new HttpsError("failed-precondition", "No full card to redeem yet.");

    const reward = program.rewards.find((r) => r.id === rewardId && r.active);
    if (!reward) throw new HttpsError("failed-precondition", "This reward is no longer available.");

    const now = Timestamp.now();
    tx.update(cardRef, {
      stamps,
      rewardsAvailable: rewardsAvailable - 1,
      totalRedeemed: FieldValue.increment(1),
      updatedAt: now,
    });
    const redemptionRef = db.collection("redemptions").doc();
    tx.create(redemptionRef, {
      businessId: card.businessId,
      ownerUid: card.ownerUid,
      programId: card.programId,
      cardId: id,
      clientUid: uid,
      rewardId: reward.id,
      rewardTitle: reward.title,
      createdAt: now,
    });
    return { redemptionId: redemptionRef.id, rewardTitle: reward.title, redeemedAt: now.toMillis() };
  });
});

/**
 * After a client signs in with an email link on a device where they already
 * collected stamps anonymously, move those anonymous cards into the account.
 */
export const mergeAccount = onCall(async (request) => {
  const uid = requireUid(request.auth);
  if (request.auth?.token.firebase.sign_in_provider === "anonymous") {
    throw new HttpsError("failed-precondition", "Sign in with email first.");
  }
  const anonIdToken = requireString(request.data?.anonIdToken, "anonIdToken", 4096);
  let anonUid: string;
  try {
    const decoded = await getAuth().verifyIdToken(anonIdToken);
    if (decoded.firebase.sign_in_provider !== "anonymous") throw new Error("not anonymous");
    anonUid = decoded.uid;
  } catch {
    throw new HttpsError("permission-denied", "Could not verify the previous device session.");
  }
  if (anonUid === uid) return { merged: 0 };

  const merged = await db.runTransaction(async (tx) => {
    const anonCards = await tx.get(db.collection("cards").where("clientUid", "==", anonUid));
    const targets = await Promise.all(
      anonCards.docs.map(async (doc) => {
        const card = doc.data() as Card;
        const targetRef = db.collection("cards").doc(cardId(card.programId, uid));
        const [target, program] = await Promise.all([
          tx.get(targetRef),
          tx.get(db.collection("programs").doc(card.programId)),
        ]);
        return { doc, card, targetRef, target, program: program.data() as Program | undefined };
      }),
    );

    const now = Timestamp.now();
    for (const { doc, card, targetRef, target, program } of targets) {
      const existing = target.data() as Card | undefined;
      if (existing && program) {
        const progress = mergeProgress(existing, card, program.stampsRequired);
        tx.update(targetRef, {
          ...progress,
          totalStamps: existing.totalStamps + card.totalStamps,
          totalRedeemed: existing.totalRedeemed + card.totalRedeemed,
          updatedAt: now,
        });
      } else {
        tx.set(targetRef, { ...card, clientUid: uid, createdAt: doc.get("createdAt") ?? now, updatedAt: now });
      }
      tx.delete(doc.ref);
    }
    return targets.length;
  });

  const history = await db.collection("redemptions").where("clientUid", "==", anonUid).get();
  const batch = db.batch();
  history.docs.forEach((doc) =>
    batch.update(doc.ref, { clientUid: uid, cardId: cardId(doc.get("programId"), uid) }),
  );
  await batch.commit();
  await getAuth().deleteUser(anonUid).catch(() => undefined);

  return { merged };
});
