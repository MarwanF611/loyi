import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';
import 'auth_service.dart';
import 'stamping.dart';

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
}

class RedeemResult {
  const RedeemResult({required this.rewardTitle, required this.redeemedAt});

  final String rewardTitle;
  final DateTime redeemedAt;
}

/// A problem the client should see as-is.
class LoyiException implements Exception {
  const LoyiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Tag taps and reward redemptions.
///
/// Loyi runs on Firebase's free Spark plan (no Cloud Functions), so these are
/// Firestore transactions from the client. firestore.rules only accepts writes
/// that match exactly what this code does: +1 stamp from an active stamp tag,
/// cooldown respected, one log entry per stamp, a reward only when available.
class Api {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<TapResult> tap(String tagId) async {
    final uid = auth.user!.uid;
    final tagRef = _db.doc('tags/$tagId');

    final DocumentSnapshot<Map<String, dynamic>> tagSnap;
    try {
      tagSnap = await tagRef.get();
    } on FirebaseException {
      throw const LoyiException('This tag is not active.');
    }
    if (!tagSnap.exists || tagSnap.get('active') != true) throw const LoyiException('This tag is not active.');
    final tag = LoyiTag.fromDoc(tagSnap);

    final programSnap = await _db.doc('programs/${tag.programId}').get();
    if (!programSnap.exists) throw const LoyiException('This tag is not active.');
    final program = Program.fromDoc(programSnap);
    if (!program.active) throw const LoyiException('This loyalty card is paused.');

    final cardId = '${program.id}_$uid';
    final cardRef = _db.doc('cards/$cardId');
    try {
      return await _db.runTransaction((tx) async {
        final cardSnap = await tx.get(cardRef);
        final existing = cardSnap.exists ? LoyaltyCard.fromDoc(cardSnap) : null;
        final now = FieldValue.serverTimestamp();

        if (tag.type == TagType.join) {
          if (existing != null) {
            return _result(cardId, TapOutcome.alreadyMember, existing.stamps, program);
          }
          tx.set(cardRef, {
            ..._cardBase(uid, program),
            'stamps': 0,
            'rewardsAvailable': 0,
            'totalStamps': 0,
            'totalRedeemed': 0,
            'lastStampAt': null,
            'lastTagId': tagId,
            'createdAt': now,
            'updatedAt': now,
          });
          tx.update(tagRef, {'tapCount': FieldValue.increment(1), 'lastTapAt': now});
          return _result(cardId, TapOutcome.joined, 0, program);
        }

        // Stamp tag. The rules enforce the cooldown with server time; this is the friendly pre-check.
        final wait = cooldownRemaining(existing?.lastStampAt, program.stampCooldownMinutes, DateTime.now());
        if (wait > Duration.zero) {
          return _result(cardId, TapOutcome.cooldown, existing!.stamps, program, retryAfter: wait);
        }
        final next = addStamp(existing?.stamps ?? 0, existing?.rewardsAvailable ?? 0, program.stampsRequired);
        final totalStamps = (existing?.totalStamps ?? 0) + 1;
        final stamp = {
          'stamps': next.stamps,
          'rewardsAvailable': next.rewards,
          'totalStamps': totalStamps,
          'lastStampAt': now,
          'lastTagId': tagId,
          'updatedAt': now,
        };
        if (existing == null) {
          tx.set(cardRef, {..._cardBase(uid, program), ...stamp, 'totalRedeemed': 0, 'createdAt': now});
        } else {
          tx.update(cardRef, stamp);
        }
        tx.set(_db.doc('stampEvents/${cardId}_$totalStamps'), {
          'businessId': program.businessId,
          'ownerUid': program.ownerUid,
          'programId': program.id,
          'cardId': cardId,
          'clientUid': uid,
          'tagId': tagId,
          'createdAt': now,
        });
        tx.update(tagRef, {'tapCount': FieldValue.increment(1), 'lastTapAt': now});
        return _result(
          cardId,
          existing == null ? TapOutcome.joined : TapOutcome.stamped,
          next.stamps,
          program,
          completedCard: next.rewards > (existing?.rewardsAvailable ?? 0),
          stampedOnJoin: existing == null,
        );
      });
    } on FirebaseException catch (e) {
      // The rules refused, most likely the cooldown by server clock (device clock differs).
      if (e.code == 'permission-denied' && tag.type == TagType.stamp) {
        return _result(cardId, TapOutcome.cooldown, 0, program, retryAfter: Duration.zero);
      }
      rethrow;
    }
  }

  Map<String, dynamic> _cardBase(String uid, Program program) => {
    'clientUid': uid,
    'businessId': program.businessId,
    'ownerUid': program.ownerUid,
    'programId': program.id,
  };

  TapResult _result(
    String cardId,
    TapOutcome outcome,
    int stamps,
    Program program, {
    bool completedCard = false,
    bool stampedOnJoin = false,
    Duration retryAfter = Duration.zero,
  }) => TapResult(
    cardId: cardId,
    // A first tap on a stamp tag both joins and stamps; show it as a stamp.
    outcome: stampedOnJoin ? TapOutcome.stamped : outcome,
    completedCard: completedCard,
    retryAfter: retryAfter,
    stamps: stamps,
    stampsRequired: program.stampsRequired,
  );

  /// Spends one banked full card on an active reward of the client's choice.
  Future<RedeemResult> redeem({required String cardId, required String rewardId}) async {
    final cardRef = _db.doc('cards/$cardId');
    return _db.runTransaction((tx) async {
      final cardSnap = await tx.get(cardRef);
      if (!cardSnap.exists) throw const LoyiException('Card not found.');
      final card = LoyaltyCard.fromDoc(cardSnap);
      final program = Program.fromDoc(await tx.get(_db.doc('programs/${card.programId}')));
      if (card.rewardsAvailable < 1) throw const LoyiException('No full card to redeem yet.');
      final reward = program.activeRewards.where((r) => r.id == rewardId).firstOrNull;
      if (reward == null) throw const LoyiException('This reward is no longer available.');

      final totalRedeemed = card.totalRedeemed + 1;
      final now = FieldValue.serverTimestamp();
      tx.update(cardRef, {
        'rewardsAvailable': card.rewardsAvailable - 1,
        'totalRedeemed': totalRedeemed,
        'updatedAt': now,
      });
      tx.set(_db.doc('redemptions/${cardId}_r$totalRedeemed'), {
        'businessId': card.businessId,
        'ownerUid': card.ownerUid,
        'programId': card.programId,
        'cardId': cardId,
        'clientUid': card.clientUid,
        'rewardId': reward.id,
        'rewardTitle': reward.title,
        'createdAt': now,
      });
      return RedeemResult(rewardTitle: reward.title, redeemedAt: DateTime.now());
    });
  }
}

final api = Api();

/// Readable message for errors from the API and Firebase.
String friendlyError(Object error) => switch (error) {
  LoyiException(:final message) => message,
  FirebaseException(code: 'unavailable') => 'No connection. Check your internet and try again.',
  _ => 'Something went wrong. Please try again.',
};
