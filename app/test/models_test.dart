import 'package:flutter_test/flutter_test.dart';
import 'package:loyi/models.dart';

void main() {
  LoyaltyCard card({required int stamps, int rewards = 0}) => LoyaltyCard(
    id: 'p_u',
    clientUid: 'u',
    businessId: 'b',
    programId: 'p',
    stamps: stamps,
    rewardsAvailable: rewards,
    totalStamps: stamps,
    totalRedeemed: 0,
  );

  test('progress is unchanged while the card is not full', () {
    final p = card(stamps: 3).progressFor(5);
    expect(p.stamps, 3);
    expect(p.rewards, 0);
  });

  test('progress rolls over when the business lowered stampsRequired', () {
    final p = card(stamps: 7, rewards: 1).progressFor(3);
    expect(p.stamps, 1);
    expect(p.rewards, 3);
  });
}
