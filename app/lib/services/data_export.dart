import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../config.dart';
import 'auth_service.dart';
import 'language.dart';

/// Everything Loyi stores about the signed-in user, as JSON (GDPR art. 15 and 20:
/// access and portability). Businesses also get their shop, cards, tags,
/// subscription and activity log.
Future<Uint8List> exportMyData() async {
  final user = auth.user!;
  final db = FirebaseFirestore.instance;
  final uid = user.uid;

  Future<List<Map<String, Object?>>> all(String collection, String field) async {
    final docs = (await db.collection(collection).where(field, isEqualTo: uid).get()).docs;
    return [
      for (final d in docs) {'id': d.id, ..._plain(d.data()) as Map<String, Object?>},
    ];
  }

  final data = <String, Object?>{
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'about': l10n.exportAbout(privacyUrl),
    'account': {
      'id': uid,
      'email': user.email,
      'emailVerified': user.emailVerified,
      'signInMethods': [for (final p in user.providerData) p.providerId],
      'anonymous': user.isAnonymous,
      'createdAt': user.metadata.creationTime?.toUtc().toIso8601String(),
      'lastSignInAt': user.metadata.lastSignInTime?.toUtc().toIso8601String(),
    },
    'myLoyaltyCards': await all('cards', 'clientUid'),
    'myStamps': await all('stampEvents', 'clientUid'),
    'myRewardsUsed': await all('redemptions', 'clientUid'),
  };

  if (!user.isAnonymous) {
    final businesses = await all('businesses', 'ownerUid');
    if (businesses.isNotEmpty) {
      final subscription = await db.doc('subscriptions/$uid').get();
      data['business'] = {
        'shops': businesses,
        'loyaltyCards': await all('programs', 'ownerUid'),
        'nfcTags': await all('tags', 'ownerUid'),
        'subscription': subscription.exists ? _plain(subscription.data()) : null,
        'clientCards': await all('cards', 'ownerUid'),
        'stampsGiven': await all('stampEvents', 'ownerUid'),
        'rewardsGiven': await all('redemptions', 'ownerUid'),
        'followUpMessages': await all('messages', 'ownerUid'),
        'note': l10n.exportBusinessNote,
      };
    }
  }
  return Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(data)));
}

/// Fields holding ARGB colours, written as #RRGGBB so the export is readable.
const _colorFields = {'color', 'colors', 'background', 'background2', 'stampColor'};

/// Firestore values → JSON-friendly values.
Object? _plain(Object? v, [String? key]) => switch (v) {
  Timestamp t => t.toDate().toUtc().toIso8601String(),
  Blob _ => '(image)',
  GeoPoint g => {'lat': g.latitude, 'lng': g.longitude},
  DocumentReference r => r.path,
  int i when _colorFields.contains(key) => '#${(i & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
  Map m => {for (final e in m.entries) '${e.key}': _plain(e.value, '${e.key}')},
  List l => [for (final e in l) _plain(e, key)],
  _ => v,
};
