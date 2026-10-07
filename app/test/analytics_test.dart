import 'package:flutter_test/flutter_test.dart';
import 'package:loyi/business/insights/analytics.dart';
import 'package:loyi/models.dart';

void main() {
  final now = DateTime(2026, 10, 6, 15);
  const program = Program(
    id: 'p',
    businessId: 'b',
    ownerUid: 'o',
    name: 'Koffiekaart',
    stampsRequired: 5,
    stampCooldownMinutes: 0,
    rewards: [],
    active: true,
  );
  final programs = {'p': program};

  LoyaltyCard card(
    String uid, {
    int stamps = 0,
    int rewards = 0,
    int total = 0,
    required int joinedDaysAgo,
    int? lastStampDaysAgo,
  }) => LoyaltyCard(
    id: 'p_$uid',
    clientUid: uid,
    businessId: 'b',
    programId: 'p',
    stamps: stamps,
    rewardsAvailable: rewards,
    totalStamps: total,
    totalRedeemed: 0,
    createdAt: now.subtract(Duration(days: joinedDaysAgo)),
    lastStampAt: lastStampDaysAgo == null ? null : now.subtract(Duration(days: lastStampDaysAgo)),
  );

  ActivityItem stamp(String uid, DateTime at) =>
      ActivityItem(isRedemption: false, programId: 'p', at: at, cardId: 'p_$uid', clientUid: uid);

  group('clientCode', () {
    test('is stable, short and differs per shop', () {
      final a = clientCode('shop1', 'uid-123');
      expect(a, clientCode('shop1', 'uid-123'));
      expect(a, matches(RegExp(r'^#[0-9A-Z]{4}$')));
      expect(a, isNot(clientCode('shop2', 'uid-123')));
    });

    test('spreads clients over many codes', () {
      final codes = {for (var i = 0; i < 500; i++) clientCode('shop', 'client-$i')};
      expect(codes.length, greaterThan(490));
    });
  });

  group('audiences', () {
    test('new client close to a reward', () {
      final a = audiencesFor(card('u', stamps: 4, total: 4, joinedDaysAgo: 3, lastStampDaysAgo: 1), program, now);
      expect(a, containsAll([Audience.all, Audience.newcomers, Audience.almost]));
      expect(a, isNot(contains(Audience.slipping)));
    });

    test('a reward waiting is not "almost there"', () {
      final a = audiencesFor(card('u', rewards: 1, total: 5, joinedDaysAgo: 60, lastStampDaysAgo: 2), program, now);
      expect(a, contains(Audience.reward));
      expect(a, isNot(contains(Audience.almost)));
    });

    test('slipping away after 30 days, lost after 90', () {
      expect(
        audiencesFor(card('u', stamps: 1, total: 1, joinedDaysAgo: 100, lastStampDaysAgo: 45), program, now),
        contains(Audience.slipping),
      );
      final lost = audiencesFor(
        card('u', stamps: 1, total: 1, joinedDaysAgo: 200, lastStampDaysAgo: 120),
        program,
        now,
      );
      expect(lost, contains(Audience.lost));
      expect(lost, isNot(contains(Audience.slipping)));
    });

    test('a message shows only to its group, its card and while live', () {
      final c = card('u', stamps: 4, total: 4, joinedDaysAgo: 40, lastStampDaysAgo: 1);
      ShopMessage msg(Audience a, {String? programId, bool active = true, int endsInDays = 3}) => ShopMessage(
        id: 'm',
        businessId: 'b',
        ownerUid: 'o',
        programId: programId,
        title: 't',
        body: 'b',
        audience: a,
        active: active,
        endsAt: now.add(Duration(days: endsInDays)),
      );
      expect(msg(Audience.almost).showsFor(c, program, now), isTrue);
      expect(msg(Audience.lost).showsFor(c, program, now), isFalse);
      expect(msg(Audience.all, programId: 'other').showsFor(c, program, now), isFalse);
      expect(msg(Audience.all, active: false).showsFor(c, program, now), isFalse);
      expect(msg(Audience.all, endsInDays: -1).showsFor(c, program, now), isFalse);
    });
  });

  group('clients', () {
    test('cards of one client are grouped and get one status', () {
      const second = Program(
        id: 'q',
        businessId: 'b',
        ownerUid: 'o',
        name: 'Broodjes',
        stampsRequired: 10,
        stampCooldownMinutes: 0,
        rewards: [],
        active: true,
      );
      final cards = [
        card('u', stamps: 2, total: 12, joinedDaysAgo: 90, lastStampDaysAgo: 2),
        LoyaltyCard(
          id: 'q_u',
          clientUid: 'u',
          businessId: 'b',
          programId: 'q',
          stamps: 3,
          rewardsAvailable: 0,
          totalStamps: 3,
          totalRedeemed: 0,
          createdAt: now.subtract(const Duration(days: 20)),
          lastStampAt: now.subtract(const Duration(days: 5)),
        ),
        card('v', stamps: 1, total: 1, joinedDaysAgo: 50, lastStampDaysAgo: 50),
      ];
      final list = summarizeClients('b', cards, {...programs, 'q': second});
      expect(list, hasLength(2));
      expect(list.first.clientUid, 'u'); // most recent visit first
      expect(list.first.totalStamps, 15);
      expect(list.first.joined, now.subtract(const Duration(days: 90)));
      expect(list.first.statusAt(now), ClientStatus.regular);
      expect(list.last.statusAt(now), ClientStatus.slipping);
    });

    test('reach counts clients, not cards', () {
      final cards = [
        card('u', stamps: 4, total: 4, joinedDaysAgo: 5, lastStampDaysAgo: 1),
        card('v', stamps: 0, total: 0, joinedDaysAgo: 5),
      ];
      expect(reach(cards, programs, Audience.newcomers, null, now), 2);
      expect(reach(cards, programs, Audience.almost, null, now), 1);
      expect(reach(cards, programs, Audience.all, 'other', now), 0);
    });
  });

  group('insights', () {
    test('counts per day, busy hours, new and returning clients', () {
      final cards = [
        card('old', stamps: 3, total: 8, joinedDaysAgo: 60, lastStampDaysAgo: 0),
        card('new', stamps: 1, total: 1, joinedDaysAgo: 2, lastStampDaysAgo: 2),
        card('gone', stamps: 1, total: 1, joinedDaysAgo: 45),
      ];
      final saturday10 = DateTime(2026, 10, 3, 10, 15);
      final stamps = [
        stamp('old', DateTime(2026, 9, 30, 9)),
        stamp('old', saturday10),
        stamp('old', saturday10.add(const Duration(minutes: 35))),
        stamp('old', DateTime(2026, 10, 6, 10)),
        stamp('new', DateTime(2026, 10, 4, 10, 30)),
        stamp('old', DateTime(2026, 8, 1, 9)), // before the period: ignored
      ];
      final i = Insights.compute(
        businessId: 'b',
        now: now,
        days: 7,
        cards: cards,
        programs: programs,
        stamps: stamps,
        redemptions: const [],
      );
      expect(i.stampsPerDay, [1, 0, 0, 2, 1, 0, 1]); // 30 Sep … 6 Oct
      expect(i.totalStamps, 5);
      expect(i.activeClients, 2);
      expect(i.newClients, 1);
      expect(i.returningClients, 1);
      expect(i.peak, (weekday: DateTime.saturday - 1, hour: 10));
      expect(i.heatmap[DateTime.saturday - 1][10], 2);
      expect(i.daysBetweenVisits, closeTo(145 / 24 / 3, 0.001)); // 30 Sep 9:00 → 6 Oct 10:00 over 3 gaps
      // Of the clients who joined 30+ days ago, "old" came back and "gone" didn't.
      expect(i.returnRate, 0.5);
      expect(i.progress['p'], [0, 2, 0, 1, 0]);
    });

    test('buckets keep the last week complete', () {
      expect(bucket([1, 1, 1, 1, 1, 1, 1, 1, 1], 7), [2, 7]);
      expect(change(12, 10), closeTo(0.2, 1e-9));
      expect(change(3, 0), isNull);
    });
  });
}
