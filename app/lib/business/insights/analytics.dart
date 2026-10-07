import 'dart:math' as math;

import '../../l10n/app_localizations.dart';
import '../../models.dart';

/// Turns a shop's cards and activity log into the numbers behind the Clients
/// and Insights tabs. Pure functions, no Firestore, so they're easy to test.
///
/// Privacy: Loyi never knows a client's name, email or phone number, and this
/// code doesn't try to find out. Clients appear as a short code that is unique
/// per shop ([clientCode]), so two shops can't match up their lists.

/// A stable, anonymous label like "#K7Q2" for a client of [businessId].
String clientCode(String businessId, String clientUid) {
  // FNV-1a: tiny, deterministic and good enough to spread ids over 32^4 codes.
  var hash = 0x811C9DC5;
  for (final unit in '$businessId/$clientUid'.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'; // Crockford: no I, L, O, U
  final chars = [for (var i = 0; i < 4; i++) alphabet[(hash >> (i * 5)) & 31]];
  return '#${chars.join()}';
}

/// One line in the client list.
enum ClientStatus { reward, newcomer, almost, regular, occasional, slipping, lost }

extension ClientStatusText on ClientStatus {
  String label(L10n l) => switch (this) {
    ClientStatus.reward => l.statusReward,
    ClientStatus.newcomer => l.statusNew,
    ClientStatus.almost => l.statusAlmost,
    ClientStatus.regular => l.statusRegular,
    ClientStatus.occasional => l.statusOccasional,
    ClientStatus.slipping => l.statusSlipping,
    ClientStatus.lost => l.statusLost,
  };
}

/// A client of the shop: all their cards together.
class ClientSummary {
  ClientSummary({required this.code, required this.clientUid, required this.cards, required this.programs});

  final String code;
  final String clientUid;
  final List<LoyaltyCard> cards;
  final Map<String, Program> programs;

  DateTime? get joined => _min(cards.map((c) => c.createdAt));
  DateTime? get lastVisit => _max(cards.map((c) => c.lastVisit));
  int get totalStamps => cards.fold(0, (a, c) => a + c.totalStamps);
  int get redeemed => cards.fold(0, (a, c) => a + c.totalRedeemed);

  int get rewardsWaiting => cards.fold(0, (a, c) {
    final p = programs[c.programId];
    return a + (p == null ? c.rewardsAvailable : c.progressFor(p.stampsRequired).rewards);
  });

  Set<Audience> audiencesAt(DateTime now) => {
    for (final c in cards)
      if (programs[c.programId] case final p?) ...audiencesFor(c, p, now),
  };

  ClientStatus statusAt(DateTime now) {
    final a = audiencesAt(now);
    if (a.contains(Audience.reward)) return ClientStatus.reward;
    if (a.contains(Audience.newcomers)) return ClientStatus.newcomer;
    if (a.contains(Audience.lost)) return ClientStatus.lost;
    if (a.contains(Audience.slipping)) return ClientStatus.slipping;
    if (a.contains(Audience.almost)) return ClientStatus.almost;
    final last = lastVisit;
    final recent = last != null && now.difference(last).inDays < 30;
    return recent && totalStamps >= 4 ? ClientStatus.regular : ClientStatus.occasional;
  }
}

/// Groups cards per client, most recent visit first.
List<ClientSummary> summarizeClients(String businessId, List<LoyaltyCard> cards, Map<String, Program> programs) {
  final byClient = <String, List<LoyaltyCard>>{};
  for (final c in cards) {
    (byClient[c.clientUid] ??= []).add(c);
  }
  final list = [
    for (final e in byClient.entries)
      ClientSummary(code: clientCode(businessId, e.key), clientUid: e.key, cards: e.value, programs: programs),
  ];
  list.sort((a, b) => (b.lastVisit ?? DateTime(0)).compareTo(a.lastVisit ?? DateTime(0)));
  return list;
}

/// How many card holders a message for [audience] (on [programId], or all cards) reaches today.
int reach(List<LoyaltyCard> cards, Map<String, Program> programs, Audience audience, String? programId, DateTime now) {
  final clients = <String>{};
  for (final c in cards) {
    final p = programs[c.programId];
    if (p == null || (programId != null && c.programId != programId)) continue;
    if (audiencesFor(c, p, now).contains(audience)) clients.add(c.clientUid);
  }
  return clients.length;
}

/// Insights over one period, from the cards (all time) and the activity in the period.
class Insights {
  Insights._({
    required this.start,
    required this.days,
    required this.stampsPerDay,
    required this.redemptionsPerDay,
    required this.newClientsPerDay,
    required this.heatmap,
    required this.activeClients,
    required this.newClients,
    required this.returningClients,
    required this.visitsPerClient,
    required this.daysBetweenVisits,
    required this.returnRate,
    required this.rewardsWaiting,
    required this.progress,
    required this.perProgram,
    required this.statusCounts,
    required this.capped,
  });

  final DateTime start;
  final int days;

  /// One value per day from [start], oldest first.
  final List<int> stampsPerDay;
  final List<int> redemptionsPerDay;
  final List<int> newClientsPerDay;

  /// Stamps per weekday (0 = Monday) and hour (0–23).
  final List<List<int>> heatmap;

  /// Clients with at least one stamp in the period.
  final int activeClients;

  /// Clients who joined in the period.
  final int newClients;

  /// Active clients who had joined before the period.
  final int returningClients;

  /// Average stamps per active client in the period.
  final double visitsPerClient;

  /// Average days between two visits of the same client, or null without repeat visits.
  final double? daysBetweenVisits;

  /// Share of clients who joined at least 30 days ago and came back after their first visit.
  final double? returnRate;
  final int rewardsWaiting;

  /// Cards by stamps collected towards the next reward, per program.
  final Map<String, List<int>> progress;
  final List<ProgramInsight> perProgram;
  final Map<ClientStatus, int> statusCounts;

  /// True when the period had more activity than one load fetches.
  final bool capped;

  int get totalStamps => stampsPerDay.fold(0, (a, b) => a + b);
  int get totalRedemptions => redemptionsPerDay.fold(0, (a, b) => a + b);

  /// The busiest weekday and hour, or null without stamps.
  ({int weekday, int hour})? get peak {
    var best = 0;
    ({int weekday, int hour})? at;
    for (var d = 0; d < 7; d++) {
      for (var h = 0; h < 24; h++) {
        if (heatmap[d][h] > best) {
          best = heatmap[d][h];
          at = (weekday: d, hour: h);
        }
      }
    }
    return at;
  }

  static Insights compute({
    required String businessId,
    required DateTime now,
    required int days,
    required List<LoyaltyCard> cards,
    required Map<String, Program> programs,
    required List<ActivityItem> stamps,
    required List<ActivityItem> redemptions,
    bool capped = false,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: days - 1));
    int? dayIndex(DateTime t) {
      final d = DateTime(t.year, t.month, t.day).difference(start).inHours;
      final i = (d / 24).round(); // DST-safe
      return i < 0 || i >= days ? null : i;
    }

    final stampsPerDay = List.filled(days, 0);
    final heatmap = List.generate(7, (_) => List.filled(24, 0));
    final visitsByClient = <String, List<DateTime>>{};
    final stampsByProgram = <String, int>{};
    for (final s in stamps) {
      final i = dayIndex(s.at);
      if (i == null) continue;
      stampsPerDay[i]++;
      heatmap[s.at.weekday - 1][s.at.hour]++;
      (visitsByClient[s.clientUid] ??= []).add(s.at);
      stampsByProgram[s.programId] = (stampsByProgram[s.programId] ?? 0) + 1;
    }

    final redemptionsPerDay = List.filled(days, 0);
    final redemptionsByProgram = <String, int>{};
    for (final r in redemptions) {
      final i = dayIndex(r.at);
      if (i == null) continue;
      redemptionsPerDay[i]++;
      redemptionsByProgram[r.programId] = (redemptionsByProgram[r.programId] ?? 0) + 1;
    }

    final clients = summarizeClients(businessId, cards, programs);
    final newClientsPerDay = List.filled(days, 0);
    final joinedInPeriod = <String>{};
    for (final c in clients) {
      final joined = c.joined;
      final i = joined == null ? null : dayIndex(joined);
      if (i != null) {
        newClientsPerDay[i]++;
        joinedInPeriod.add(c.clientUid);
      }
    }

    // Average gap between consecutive visits of the same client.
    var gapSum = 0.0;
    var gapCount = 0;
    for (final visits in visitsByClient.values) {
      if (visits.length < 2) continue;
      visits.sort();
      gapSum += visits.last.difference(visits.first).inHours / 24 / (visits.length - 1);
      gapCount++;
    }

    // Came back: a later visit at least half a day after joining.
    final settled = [
      for (final c in cards)
        if (c.createdAt != null && now.difference(c.createdAt!).inDays >= 30) c,
    ];
    final cameBack = settled.where(
      (c) => c.lastStampAt != null && c.lastStampAt!.difference(c.createdAt!).inHours >= 12,
    );

    final progress = <String, List<int>>{};
    var rewardsWaiting = 0;
    final cardsByProgram = <String, int>{};
    for (final c in cards) {
      final p = programs[c.programId];
      if (p == null) continue;
      final pr = c.progressFor(p.stampsRequired);
      (progress[p.id] ??= List.filled(p.stampsRequired, 0))[pr.stamps]++;
      rewardsWaiting += pr.rewards;
      cardsByProgram[p.id] = (cardsByProgram[p.id] ?? 0) + 1;
    }

    final statusCounts = {for (final s in ClientStatus.values) s: 0};
    for (final c in clients) {
      final s = c.statusAt(now);
      statusCounts[s] = statusCounts[s]! + 1;
    }

    final active = visitsByClient.keys.toSet();
    return Insights._(
      start: start,
      days: days,
      stampsPerDay: stampsPerDay,
      redemptionsPerDay: redemptionsPerDay,
      newClientsPerDay: newClientsPerDay,
      heatmap: heatmap,
      activeClients: active.length,
      newClients: joinedInPeriod.length,
      returningClients: active.difference(joinedInPeriod).length,
      visitsPerClient: active.isEmpty ? 0 : stampsPerDay.fold(0, (a, b) => a + b) / active.length,
      daysBetweenVisits: gapCount == 0 ? null : gapSum / gapCount,
      returnRate: settled.isEmpty ? null : cameBack.length / settled.length,
      rewardsWaiting: rewardsWaiting,
      progress: progress,
      perProgram: [
        for (final p in programs.values)
          ProgramInsight(
            program: p,
            clients: cardsByProgram[p.id] ?? 0,
            stamps: stampsByProgram[p.id] ?? 0,
            redemptions: redemptionsByProgram[p.id] ?? 0,
          ),
      ]..sort((a, b) => b.stamps.compareTo(a.stamps)),
      statusCounts: statusCounts,
      capped: capped,
    );
  }
}

class ProgramInsight {
  const ProgramInsight({required this.program, required this.clients, required this.stamps, required this.redemptions});

  final Program program;
  final int clients;
  final int stamps;
  final int redemptions;
}

/// Sums [values] into buckets of [size] (e.g. days into weeks), keeping the last bucket complete.
List<int> bucket(List<int> values, int size) {
  final out = <int>[];
  for (var end = values.length; end > 0; end -= size) {
    out.insert(0, values.sublist(math.max(0, end - size), end).fold(0, (a, b) => a + b));
  }
  return out;
}

/// Percentage change from [before] to [now], or null when there's nothing to compare.
double? change(num now, num before) => before == 0 ? null : (now - before) / before;

DateTime? _min(Iterable<DateTime?> xs) =>
    xs.whereType<DateTime>().fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);

DateTime? _max(Iterable<DateTime?> xs) =>
    xs.whereType<DateTime>().fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
