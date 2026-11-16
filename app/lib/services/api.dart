import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';
import 'auth_service.dart';
import 'language.dart';
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
    this.newCard = false,
    this.card,
    this.program,
    this.business,
  });

  final String cardId;
  final TapOutcome outcome;
  final bool completedCard;
  final Duration retryAfter;
  final int stamps;
  final int stampsRequired;

  /// This tap created the card (a first tap on a stamp tag also gives the first stamp).
  final bool newCard;

  /// What the tap read and wrote, so the card shows at once; the live listeners take over after.
  final LoyaltyCard? card;
  final Program? program;
  final Business? business;
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

  /// One tap on a tag. A secure tag's stamp also spends the server's [ticketId]
  /// for this tap (see Billing.kitTap); firestore.rules require it.
  ///
  /// Everything is read inside the transaction: those are plain requests, so a
  /// tap never waits for the realtime channel to open, and after the tag the
  /// other documents load in parallel.
  Future<TapResult> tap(String tagId, {String? ticketId}) async {
    final uid = auth.user!.uid;
    final tagRef = _db.doc('tags/$tagId');
    LoyiTag? tag;
    Program? program;
    // Set instead of thrown: on the web an exception thrown inside the
    // transaction comes back out as a generic error.
    LoyiException? refusal;
    TapResult? refuse(String message) {
      refusal = LoyiException(message);
      return null;
    }

    try {
      final result = await _db.runTransaction<TapResult?>((tx) async {
        final DocumentSnapshot<Map<String, dynamic>> tagSnap;
        try {
          tagSnap = await tx.get(tagRef);
        } on FirebaseException {
          return refuse(l10n.tagNotActive);
        }
        if (!tagSnap.exists || tagSnap.get('active') != true) return refuse(l10n.tagNotActive);
        final t = tag = LoyiTag.fromDoc(tagSnap);

        final cardId = '${t.programId}_$uid';
        final cardRef = _db.doc('cards/$cardId');
        final (programSnap, subscriptionSnap, businessSnap, cardSnap) = await (
          tx.get(_db.doc('programs/${t.programId}')),
          tx.get(_db.doc('subscriptions/${tagSnap.get('ownerUid')}')),
          tx.get(_db.doc('businesses/${tagSnap.get('businessId')}')),
          tx.get(cardRef),
        ).wait;
        if (!programSnap.exists || !businessSnap.exists) return refuse(l10n.tagNotActive);
        final p = program = Program.fromDoc(programSnap);
        if (!p.active) return refuse(l10n.cardPaused);
        if (!subscriptionSnap.exists || !Subscription.fromDoc(subscriptionSnap).isActive) {
          return refuse(l10n.shopNotActive);
        }
        final business = Business.fromDoc(businessSnap);
        final existing = cardSnap.exists ? LoyaltyCard.fromDoc(cardSnap) : null;
        final now = FieldValue.serverTimestamp();

        if (t.type == TagType.join) {
          if (existing != null) {
            return _result(TapOutcome.alreadyMember, existing, p, business);
          }
          tx.set(cardRef, {
            ..._cardBase(uid, p),
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
          return _result(TapOutcome.joined, _newCard(cardId, uid, p), p, business, newCard: true);
        }

        // Stamp tag. The rules enforce the cooldown with server time; this is the friendly pre-check.
        final wait = cooldownRemaining(existing?.lastStampAt, p.stampCooldownMinutes, DateTime.now());
        if (wait > Duration.zero) {
          return _result(TapOutcome.cooldown, existing!, p, business, retryAfter: wait);
        }
        final next = addStamp(existing?.stamps ?? 0, existing?.rewardsAvailable ?? 0, p.stampsRequired);
        final totalStamps = (existing?.totalStamps ?? 0) + 1;
        final stamp = {
          'stamps': next.stamps,
          'rewardsAvailable': next.rewards,
          'totalStamps': totalStamps,
          'lastStampAt': now,
          'lastTagId': tagId,
          'updatedAt': now,
          'lastTicketId': ?ticketId,
        };
        if (ticketId != null) tx.delete(_db.doc('stampTickets/$ticketId'));
        if (existing == null) {
          tx.set(cardRef, {..._cardBase(uid, p), ...stamp, 'totalRedeemed': 0, 'createdAt': now});
        } else {
          tx.update(cardRef, stamp);
        }
        tx.set(_db.doc('stampEvents/${cardId}_$totalStamps'), {
          'businessId': p.businessId,
          'ownerUid': p.ownerUid,
          'programId': p.id,
          'cardId': cardId,
          'clientUid': uid,
          'tagId': tagId,
          'createdAt': now,
        });
        tx.update(tagRef, {'tapCount': FieldValue.increment(1), 'lastTapAt': now});
        final stampedAt = DateTime.now();
        final base = existing ?? _newCard(cardId, uid, p);
        return _result(
          // A first tap on a stamp tag both joins and stamps; show it as a stamp.
          TapOutcome.stamped,
          LoyaltyCard(
            id: cardId,
            clientUid: uid,
            businessId: p.businessId,
            programId: p.id,
            ownerUid: p.ownerUid,
            stamps: next.stamps,
            rewardsAvailable: next.rewards,
            totalStamps: totalStamps,
            totalRedeemed: base.totalRedeemed,
            lastStampAt: stampedAt,
            createdAt: base.createdAt,
            updatedAt: stampedAt,
          ),
          p,
          business,
          completedCard: next.rewards > (existing?.rewardsAvailable ?? 0),
          newCard: existing == null,
        );
      });
      if (refusal case final r?) throw r;
      return result!;
    } on FirebaseException catch (e) {
      // The rules refused, most likely the cooldown by server clock (device clock differs).
      final p = program;
      if (e.code == 'permission-denied' && tag?.type == TagType.stamp && p != null) {
        return TapResult(
          cardId: '${p.id}_$uid',
          outcome: TapOutcome.cooldown,
          completedCard: false,
          retryAfter: Duration.zero,
          stamps: 0,
          stampsRequired: p.stampsRequired,
        );
      }
      rethrow;
    }
  }

  LoyaltyCard _newCard(String cardId, String uid, Program program) => LoyaltyCard(
    id: cardId,
    clientUid: uid,
    businessId: program.businessId,
    programId: program.id,
    ownerUid: program.ownerUid,
    stamps: 0,
    rewardsAvailable: 0,
    totalStamps: 0,
    totalRedeemed: 0,
    createdAt: DateTime.now(),
  );

  Map<String, dynamic> _cardBase(String uid, Program program) => {
    'clientUid': uid,
    'businessId': program.businessId,
    'ownerUid': program.ownerUid,
    'programId': program.id,
  };

  TapResult _result(
    TapOutcome outcome,
    LoyaltyCard card,
    Program program,
    Business business, {
    bool completedCard = false,
    bool newCard = false,
    Duration retryAfter = Duration.zero,
  }) => TapResult(
    cardId: card.id,
    outcome: outcome,
    completedCard: completedCard,
    newCard: newCard,
    retryAfter: retryAfter,
    stamps: card.stamps,
    stampsRequired: program.stampsRequired,
    card: card,
    program: program,
    business: business,
  );

  /// Spends one banked full card on an active reward of the client's choice.
  Future<RedeemResult> redeem({required String cardId, required String rewardId}) async {
    final cardRef = _db.doc('cards/$cardId');
    return _db.runTransaction((tx) async {
      final cardSnap = await tx.get(cardRef);
      if (!cardSnap.exists) throw LoyiException(l10n.cardNotFound);
      final card = LoyaltyCard.fromDoc(cardSnap);
      final program = Program.fromDoc(await tx.get(_db.doc('programs/${card.programId}')));
      if (card.rewardsAvailable < 1) throw LoyiException(l10n.noFullCardYet);
      final reward = program.activeRewards.where((r) => r.id == rewardId).firstOrNull;
      if (reward == null) throw LoyiException(l10n.rewardNoLongerAvailable);

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
  FirebaseException(code: 'unavailable') => l10n.noConnection,
  FirebaseException(code: 'permission-denied') => l10n.noPermission,
  _ => l10n.somethingWentWrong,
};
