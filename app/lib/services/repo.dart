import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models.dart';

/// Firestore reads, plus the business-side writes that security rules allow.
/// Everything that changes stamps goes through [Api] (Cloud Functions) instead.
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

  Future<void> createBusiness({required String ownerUid, required String name, required int color}) =>
      _businesses.add({'ownerUid': ownerUid, 'name': name, 'color': color, 'createdAt': FieldValue.serverTimestamp()});

  Future<void> updateBusiness(String id, {required String name, required int color}) =>
      _businesses.doc(id).update({'name': name, 'color': color});

  /// Uploads a new logo (PNG/JPEG/WebP, max 1 MB) and removes the previous one.
  Future<void> uploadLogo(Business business, Uint8List bytes) async {
    final type = imageContentType(bytes);
    if (type == null) throw const FormatException('Use a PNG, JPG or WebP image.');
    if (bytes.length > 1024 * 1024) throw const FormatException('The logo must be smaller than 1 MB.');

    final path = 'logos/${business.id}/${DateTime.now().millisecondsSinceEpoch}.${type.split('/').last}';
    final ref = FirebaseStorage.instance.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: type, cacheControl: 'public, max-age=31536000'));
    await _businesses.doc(business.id).update({'logoUrl': await ref.getDownloadURL(), 'logoPath': path});
    await _deleteQuietly(business.logoPath);
  }

  Future<void> removeLogo(Business business) async {
    await _businesses.doc(business.id).update({'logoUrl': FieldValue.delete(), 'logoPath': FieldValue.delete()});
    await _deleteQuietly(business.logoPath);
  }

  Future<void> _deleteQuietly(String? path) async {
    if (path == null) return;
    try {
      await FirebaseStorage.instance.ref(path).delete();
    } catch (_) {
      // An orphaned old logo is harmless.
    }
  }

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

  Stream<List<ActivityItem>> recentStamps(String ownerUid, String businessId) =>
      _owned('stampEvents', ownerUid, businessId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .map((s) => [for (final d in s.docs) ActivityItem.fromDoc(d, isRedemption: false)]);

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
