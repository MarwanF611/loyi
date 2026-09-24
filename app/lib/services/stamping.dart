/// Pure stamp-card maths. firestore.rules checks exactly the same formulas, so
/// keep the two in sync.
library;

typedef Progress = ({int stamps, int rewards});

/// One more stamp; a full card rolls over into a banked reward.
Progress addStamp(int stamps, int rewards, int stampsRequired) {
  final next = stamps + 1;
  return (stamps: next % stampsRequired, rewards: rewards + next ~/ stampsRequired);
}

/// Combines two cards of the same program (account merge).
Progress mergeProgress(Progress a, Progress b, int stampsRequired) {
  final sum = a.stamps + b.stamps;
  return (stamps: sum % stampsRequired, rewards: a.rewards + b.rewards + sum ~/ stampsRequired);
}

/// Time left before the next stamp is allowed, or [Duration.zero].
Duration cooldownRemaining(DateTime? lastStampAt, int cooldownMinutes, DateTime now) {
  if (lastStampAt == null || cooldownMinutes <= 0) return Duration.zero;
  final left = lastStampAt.add(Duration(minutes: cooldownMinutes)).difference(now);
  return left.isNegative ? Duration.zero : left;
}
