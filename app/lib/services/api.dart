import 'package:cloud_functions/cloud_functions.dart';

import '../config.dart';

enum TapOutcome { joined, alreadyMember, stamped, cooldown }

class TapResult {
  const TapResult({
    required this.cardId,
    required this.outcome,
    required this.completedCard,
    required this.retryAfter,
    required this.stamps,
    required this.stampsRequired,
  });

  final String cardId;
  final TapOutcome outcome;
  final bool completedCard;
  final Duration retryAfter;
  final int stamps;
  final int stampsRequired;

  factory TapResult.fromMap(Map<String, dynamic> m) => TapResult(
    cardId: m['cardId'] as String,
    outcome: switch (m['outcome']) {
      'joined' => TapOutcome.joined,
      'stamped' => TapOutcome.stamped,
      'cooldown' => TapOutcome.cooldown,
      _ => TapOutcome.alreadyMember,
    },
    completedCard: m['completedCard'] as bool? ?? false,
    retryAfter: Duration(milliseconds: (m['retryAfterMs'] as num?)?.toInt() ?? 0),
    stamps: (m['stamps'] as num).toInt(),
    stampsRequired: (m['stampsRequired'] as num).toInt(),
  );
}

class RedeemResult {
  const RedeemResult({required this.rewardTitle, required this.redeemedAt});

  final String rewardTitle;
  final DateTime redeemedAt;
}

/// Server-side actions (Cloud Functions). Stamps can only change through here.
class Api {
  FirebaseFunctions get _fn => FirebaseFunctions.instanceFor(region: functionsRegion);

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    final result = await _fn.httpsCallable(name).call<Map<String, dynamic>>(data);
    return Map<String, dynamic>.from(result.data);
  }

  Future<TapResult> tap(String tagId) async => TapResult.fromMap(await _call('tap', {'tagId': tagId}));

  Future<RedeemResult> redeem({required String cardId, required String rewardId}) async {
    final m = await _call('redeem', {'cardId': cardId, 'rewardId': rewardId});
    return RedeemResult(
      rewardTitle: m['rewardTitle'] as String,
      redeemedAt: DateTime.fromMillisecondsSinceEpoch((m['redeemedAt'] as num).toInt()),
    );
  }

  Future<void> mergeAccount(String anonIdToken) => _call('mergeAccount', {'anonIdToken': anonIdToken});
}

final api = Api();

/// Readable message for errors thrown by Cloud Functions and Firebase.
String friendlyError(Object error) => switch (error) {
  FirebaseFunctionsException(:final message?) when message.isNotEmpty => message,
  _ => 'Something went wrong. Please try again.',
};
