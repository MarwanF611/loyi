import 'package:flutter_test/flutter_test.dart';
import 'package:loyi/services/stamping.dart';

void main() {
  test('addStamp fills the card without completing it', () {
    expect(addStamp(2, 0, 5), (stamps: 3, rewards: 0));
  });

  test('addStamp banks a reward and resets when the card is full', () {
    expect(addStamp(4, 1, 5), (stamps: 0, rewards: 2));
  });

  test('addStamp rolls over extra stamps after stampsRequired was lowered', () {
    expect(addStamp(8, 0, 4), (stamps: 1, rewards: 2));
  });

  test('mergeProgress sums and rolls over', () {
    expect(mergeProgress((stamps: 3, rewards: 1), (stamps: 4, rewards: 0), 5), (stamps: 2, rewards: 2));
  });

  test('cooldownRemaining', () {
    final now = DateTime(2026, 9, 24, 12);
    expect(cooldownRemaining(null, 30, now), Duration.zero);
    expect(cooldownRemaining(now.subtract(const Duration(minutes: 1)), 0, now), Duration.zero);
    expect(cooldownRemaining(now.subtract(const Duration(minutes: 10)), 30, now), const Duration(minutes: 20));
    expect(cooldownRemaining(now.subtract(const Duration(minutes: 31)), 30, now), Duration.zero);
  });
}
