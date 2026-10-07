import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';
import 'language.dart';

/// Firestore reads, plus the business-side writes that security rules allow.
/// Everything that changes stamps goes through [Api] instead.
class Repo {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _businesses => _db.collection('businesses');
  CollectionReference<Map<String, dynamic>> get _programs => _db.collection('programs');
  CollectionReference<Map<String, dynamic>> get _tags => _db.collection('tags');
  CollectionReference<Map<String, dynamic>> get _cards => _db.collection('cards');

  String newId() => _db.collection('_').doc().id;

  // ── Business ──────────────────────────────────────────────────────────────

  /// MVP: one business per owner account.
  Stream<Business?> businessForOwner(String uid) => _businesses
      .where('ownerUid', isEqualTo: uid)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : Business.fromDoc(s.docs.first));

  Stream<Business?> business(String id) =>
      _businesses.doc(id).snapshots().map((d) => d.exists ? Business.fromDoc(d) : null);

  /// Step 1 of sign-up. Brand colours follow in step 2 ([setBrandColors]).
  Future<void> createBusiness({required String ownerUid, required String name}) => _businesses.add({
    'ownerUid': ownerUid,
    'name': name,
    'color': 0xFFFF5A3C,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> setBrandColors(String id, List<int> colors) =>
      _businesses.doc(id).update({'colors': colors, 'color': colors.first});

  Future<void> updateBusiness(String id, {required String name, required List<int> colors}) =>
      _businesses.doc(id).update({'name': name, 'colors': colors, 'color': colors.first});

  static const maxLogoBytes = 200 * 1024;

  /// Stores the logo in `logos/{businessId}` (PNG/JPEG/WebP, max 200 KB) and bumps
  /// `logoVersion` so every client reloads it. Firestore instead of Storage keeps
  /// Loyi on the free Spark plan.
  Future<void> uploadLogo(Business business, Uint8List bytes) async {
    final type = imageContentType(bytes);
    if (type == null) throw FormatException(l10n.logoWrongType);
    if (bytes.length > maxLogoBytes) throw FormatException(l10n.logoTooBig);
    final batch = _db.batch()
      ..set(_db.doc('logos/${business.id}'), {
        'data': Blob(bytes),
        'contentType': type,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..update(_businesses.doc(business.id), {'logoVersion': DateTime.now().millisecondsSinceEpoch});
    await batch.commit();
  }

  Future<void> removeLogo(Business business) async {
    final batch = _db.batch()
      ..update(_businesses.doc(business.id), {'logoVersion': FieldValue.delete()})
      ..delete(_db.doc('logos/${business.id}'));
    await batch.commit();
  }

  final _logoCache = <LogoRef, Future<Uint8List?>>{};

  /// Logo image bytes, fetched once per logo version.
  Future<Uint8List?> logoBytes(LogoRef ref) => _logoCache[ref] ??= _db
      .doc('logos/${ref.businessId}')
      .get()
      .then((d) => (d.data()?['data'] as Blob?)?.bytes)
      .catchError((Object _) => null);

  // ── Programs (loyalty cards the business offers) ─────────────────────────

  Stream<List<Program>> programsForBusiness(String businessId) =>
      _programs.where('businessId', isEqualTo: businessId).snapshots().map((s) {
        final list = s.docs.map(Program.fromDoc).toList();
        list.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
        return list;
      });

  Stream<Program?> program(String id) => _programs.doc(id).snapshots().map((d) => d.exists ? Program.fromDoc(d) : null);

  /// Creates the program when [Program.id] is empty; returns its id.
  Future<String> saveProgram(Program program) async {
    if (program.id.isEmpty) {
      final ref = await _programs.add({...program.toMap(), 'createdAt': FieldValue.serverTimestamp()});
      return ref.id;
    }
    await _programs.doc(program.id).update(program.toMap());
    return program.id;
  }

  // ── Tags ──────────────────────────────────────────────────────────────────

  Stream<List<LoyiTag>> tagsForProgram({required String ownerUid, required String programId}) => _tags
      .where('ownerUid', isEqualTo: ownerUid)
      .where('programId', isEqualTo: programId)
      .snapshots()
      .map((s) => s.docs.map(LoyiTag.fromDoc).toList()..sort((a, b) => a.type.index.compareTo(b.type.index)));

  Future<void> createTag(Program program, TagType type, String label) => _tags.add({
    'businessId': program.businessId,
    'ownerUid': program.ownerUid,
    'programId': program.id,
    'type': type.name,
    'label': label,
    'active': true,
    'tapCount': 0,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> setTagActive(LoyiTag tag, {required bool active}) => _tags.doc(tag.id).update({'active': active});

  // ── Client cards ──────────────────────────────────────────────────────────

  Stream<List<LoyaltyCard>> cardsForClient(String uid) => _cards
      .where('clientUid', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map(LoyaltyCard.fromDoc).toList()..sort(_byRelevance));

  /// Cards with a reward ready first, then the most recently used.
  static int _byRelevance(LoyaltyCard a, LoyaltyCard b) {
    final ready = (b.rewardsAvailable > 0 ? 1 : 0) - (a.rewardsAvailable > 0 ? 1 : 0);
    if (ready != 0) return ready;
    return (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0));
  }

  Stream<LoyaltyCard?> card(String id) =>
      _cards.doc(id).snapshots().map((d) => d.exists ? LoyaltyCard.fromDoc(d) : null);

  // ── Subscription ──────────────────────────────────────────────────────────

  /// Null when the owner never subscribed.
  Stream<Subscription?> subscription(String ownerUid) =>
      _db.doc('subscriptions/$ownerUid').snapshots().map((d) => d.exists ? Subscription.fromDoc(d) : null);

  Future<bool> isSubscribed(String ownerUid) async {
    final d = await _db.doc('subscriptions/$ownerUid').get();
    return d.exists && Subscription.fromDoc(d).isActive;
  }

  // ── Account deletion ──────────────────────────────────────────────────────

  /// Removes everything a business owner created: its clients' cards, the
  /// logs, tags, cards (programs), logo and the business. The business goes
  /// last because the rules for the logo check who owns it.
  Future<void> deleteBusinessData(String ownerUid) async {
    for (final c in ['stampEvents', 'redemptions', 'messages', 'cards', 'tags', 'programs']) {
      await _deleteAll(_db.collection(c).where('ownerUid', isEqualTo: ownerUid));
    }
    final businesses = await _businesses.where('ownerUid', isEqualTo: ownerUid).get();
    for (final b in businesses.docs) {
      await _db.doc('logos/${b.id}').delete();
      await b.reference.delete();
    }
  }

  /// Removes a client's own cards and device hand-off.
  Future<void> deleteClientData(String uid) async {
    await _deleteAll(_cards.where('clientUid', isEqualTo: uid));
    await _db.doc('transfers/$uid').delete().catchError((Object _) {}); // usually never written
  }

  Future<void> _deleteAll(Query<Map<String, dynamic>> query) async {
    while (true) {
      final page = await query.limit(400).get();
      if (page.docs.isEmpty) return;
      final batch = _db.batch();
      for (final d in page.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  // ── Business insights ─────────────────────────────────────────────────────

  Query<Map<String, dynamic>> _owned(String collection, String ownerUid, String businessId) =>
      _db.collection(collection).where('ownerUid', isEqualTo: ownerUid).where('businessId', isEqualTo: businessId);

  Future<({int clients, int stampsToday, int redeemed})> stats(String ownerUid, String businessId) async {
    final now = DateTime.now();
    final startOfDay = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    final results = await Future.wait([
      _owned('cards', ownerUid, businessId).count().get(),
      _owned('stampEvents', ownerUid, businessId).where('createdAt', isGreaterThanOrEqualTo: startOfDay).count().get(),
      _owned('redemptions', ownerUid, businessId).count().get(),
    ]);
    return (clients: results[0].count ?? 0, stampsToday: results[1].count ?? 0, redeemed: results[2].count ?? 0);
  }

  /// Stamps given per day for the last [days] days (oldest first), for the dashboard chart.
  Future<List<int>> stampsPerDay(String ownerUid, String businessId, {int days = 7}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final counts = await Future.wait([
      for (var i = days - 1; i >= 0; i--)
        _owned('stampEvents', ownerUid, businessId)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(today.subtract(Duration(days: i))))
            .where('createdAt', isLessThan: Timestamp.fromDate(today.subtract(Duration(days: i - 1))))
            .count()
            .get(),
    ]);
    return [for (final c in counts) c.count ?? 0];
  }

  /// Emits when a client joins (the newest card changes), so the dashboard can refresh its counts.
  Stream<Object?> newestCard(String ownerUid, String businessId) => _owned(
    'cards',
    ownerUid,
    businessId,
  ).orderBy('createdAt', descending: true).limit(1).snapshots().map((s) => s.docs.firstOrNull?.id);

  Stream<List<ActivityItem>> recentStamps(String ownerUid, String businessId) =>
      _owned('stampEvents', ownerUid, businessId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .map((s) => [for (final d in s.docs) ActivityItem.fromDoc(d, isRedemption: false)]);

  /// Every client card of the business (one per client per loyalty card), live.
  Stream<List<LoyaltyCard>> cardsForBusiness(String ownerUid, String businessId) =>
      _owned('cards', ownerUid, businessId).snapshots().map((s) => s.docs.map(LoyaltyCard.fromDoc).toList());

  /// Safety cap for one insights load, to stay well inside the free Firestore quota.
  static const maxInsightEvents = 5000;

  /// Stamps since [since], oldest first.
  Future<List<ActivityItem>> stampsSince(String ownerUid, String businessId, DateTime since) async {
    final s = await _owned('stampEvents', ownerUid, businessId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('createdAt')
        .limit(maxInsightEvents)
        .get();
    return [for (final d in s.docs) ActivityItem.fromDoc(d, isRedemption: false)];
  }

  /// Redeemed rewards since [since], newest first.
  Future<List<ActivityItem>> redemptionsSince(String ownerUid, String businessId, DateTime since) async {
    final s = await _owned('redemptions', ownerUid, businessId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: true)
        .limit(maxInsightEvents)
        .get();
    return [for (final d in s.docs) ActivityItem.fromDoc(d, isRedemption: true)];
  }

  /// Stamps between [from] and [to] (a count, so it costs one read per 1000).
  Future<int> countStamps(String ownerUid, String businessId, DateTime from, DateTime to) async {
    final c = await _owned('stampEvents', ownerUid, businessId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('createdAt', isLessThan: Timestamp.fromDate(to))
        .count()
        .get();
    return c.count ?? 0;
  }

  /// The latest visits on a client's cards, newest first.
  Future<List<ActivityItem>> visitsOfCards(String ownerUid, List<String> cardIds, {int limit = 30}) async {
    if (cardIds.isEmpty) return const [];
    final s = await _db
        .collection('stampEvents')
        .where('ownerUid', isEqualTo: ownerUid)
        .where('cardId', whereIn: cardIds.take(10).toList())
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return [for (final d in s.docs) ActivityItem.fromDoc(d, isRedemption: false)];
  }

  /// How long Loyi keeps a shop's stamp and reward logs, and cards nobody used
  /// (GDPR storage limitation; stated in the privacy policy).
  static const retention = Duration(days: 730);

  /// Deletes stamp and reward log entries older than [retention], and client cards
  /// that haven't been used for that long. Loyi has no server on the free plan, so
  /// the owner's app does this when it opens (a few hundred documents per run).
  Future<void> applyRetention(String ownerUid, String businessId) async {
    final cutoff = Timestamp.fromDate(DateTime.now().subtract(retention));
    for (final (collection, field) in [
      ('stampEvents', 'createdAt'),
      ('redemptions', 'createdAt'),
      ('cards', 'updatedAt'),
    ]) {
      final page = await _owned(collection, ownerUid, businessId).where(field, isLessThan: cutoff).limit(400).get();
      if (page.docs.isEmpty) continue;
      final batch = _db.batch();
      for (final d in page.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  // ── Follow-up messages ────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _messages => _db.collection('messages');

  /// All of a shop's messages, newest first.
  Stream<List<ShopMessage>> messagesForBusiness(String ownerUid, String businessId) =>
      _owned('messages', ownerUid, businessId).snapshots().map(
        (s) =>
            s.docs.map(ShopMessage.fromDoc).toList()
              ..sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now())),
      );

  /// The messages a shop has switched on; the client's device picks the ones meant for it.
  Stream<List<ShopMessage>> activeMessages(String businessId) => _messages
      .where('businessId', isEqualTo: businessId)
      .where('active', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map(ShopMessage.fromDoc).toList());

  Future<void> saveMessage(ShopMessage message) async {
    final data = {...message.toMap(), 'updatedAt': FieldValue.serverTimestamp()};
    if (message.id.isEmpty) {
      await _messages.add({...data, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await _messages.doc(message.id).update(data);
    }
  }

  Future<void> setMessageActive(ShopMessage message, {required bool active}) =>
      _messages.doc(message.id).update({'active': active, 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> deleteMessage(ShopMessage message) => _messages.doc(message.id).delete();

  Stream<List<ActivityItem>> recentRedemptions(String ownerUid, String businessId) =>
      _owned('redemptions', ownerUid, businessId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .map((s) => [for (final d in s.docs) ActivityItem.fromDoc(d, isRedemption: true)]);
}

final repo = Repo();

/// Detects PNG/JPEG/WebP from the file header (browsers don't always report a MIME type).
String? imageContentType(Uint8List b) {
  if (b.length > 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return 'image/png';
  if (b.length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return 'image/jpeg';
  if (b.length > 12 &&
      String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}
