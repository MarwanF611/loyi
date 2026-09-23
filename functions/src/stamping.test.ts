import { test } from "node:test";
import assert from "node:assert/strict";
import { addStamp, cooldownRemainingMs, mergeProgress, normalize } from "./stamping";

test("addStamp fills the card without completing it", () => {
  assert.deepEqual(addStamp({ stamps: 2, rewardsAvailable: 0 }, 5), { stamps: 3, rewardsAvailable: 0, completed: 0 });
});

test("addStamp banks a reward and resets when the card is full", () => {
  assert.deepEqual(addStamp({ stamps: 4, rewardsAvailable: 1 }, 5), { stamps: 0, rewardsAvailable: 2, completed: 1 });
});

test("normalize rolls over when the business lowers stampsRequired", () => {
  assert.deepEqual(normalize({ stamps: 9, rewardsAvailable: 0 }, 4), { stamps: 1, rewardsAvailable: 2, completed: 2 });
});

test("normalize rejects invalid stampsRequired", () => {
  assert.throws(() => normalize({ stamps: 1, rewardsAvailable: 0 }, 0));
});

test("mergeProgress sums and rolls over", () => {
  assert.deepEqual(mergeProgress({ stamps: 3, rewardsAvailable: 1 }, { stamps: 4, rewardsAvailable: 0 }, 5), {
    stamps: 2,
    rewardsAvailable: 2,
  });
});

test("cooldownRemainingMs", () => {
  const now = 1_000_000_000;
  assert.equal(cooldownRemainingMs(null, 30, now), 0);
  assert.equal(cooldownRemainingMs(now - 60_000, 0, now), 0);
  assert.equal(cooldownRemainingMs(now - 10 * 60_000, 30, now), 20 * 60_000);
  assert.equal(cooldownRemainingMs(now - 31 * 60_000, 30, now), 0);
});
