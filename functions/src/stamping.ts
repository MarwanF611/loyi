/**
 * Pure stamp-card maths, kept free of Firebase so it can be unit tested.
 */

export interface CardProgress {
  /** Stamps on the card that is currently being filled. */
  stamps: number;
  /** Full cards the client has banked and not yet redeemed. */
  rewardsAvailable: number;
}

/**
 * Rolls surplus stamps over into banked rewards. Also covers the case where a
 * business lowers `stampsRequired` while clients already hold more stamps.
 */
export function normalize(progress: CardProgress, stampsRequired: number): CardProgress & { completed: number } {
  if (!Number.isInteger(stampsRequired) || stampsRequired < 1) {
    throw new Error(`Invalid stampsRequired: ${stampsRequired}`);
  }
  const completed = Math.floor(progress.stamps / stampsRequired);
  return {
    stamps: progress.stamps % stampsRequired,
    rewardsAvailable: progress.rewardsAvailable + completed,
    completed,
  };
}

export function addStamp(progress: CardProgress, stampsRequired: number): CardProgress & { completed: number } {
  return normalize({ ...progress, stamps: progress.stamps + 1 }, stampsRequired);
}

/** Combines two cards for the same program (used when merging a device account into a saved account). */
export function mergeProgress(a: CardProgress, b: CardProgress, stampsRequired: number): CardProgress {
  const { stamps, rewardsAvailable } = normalize(
    { stamps: a.stamps + b.stamps, rewardsAvailable: a.rewardsAvailable + b.rewardsAvailable },
    stampsRequired,
  );
  return { stamps, rewardsAvailable };
}

/** Milliseconds the client must still wait before the next stamp, or 0 when allowed. */
export function cooldownRemainingMs(lastStampAtMs: number | null, cooldownMinutes: number, nowMs: number): number {
  if (lastStampAtMs == null || cooldownMinutes <= 0) return 0;
  return Math.max(0, lastStampAtMs + cooldownMinutes * 60_000 - nowMs);
}
