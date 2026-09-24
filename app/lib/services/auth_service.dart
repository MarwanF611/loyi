import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../models.dart';
import 'stamping.dart';

/// Clients start as anonymous users (no sign-up at the counter) and can later
/// save their cards with Google or email + password. Businesses sign in with
/// email + password.
///
/// No email links: on the free Spark plan Firebase sends only 5 per day.
class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  User? get user => _auth.currentUser;
  Stream<User?> get userChanges => _auth.userChanges();
  bool get isBusinessUser => user != null && !user!.isAnonymous;

  Future<User> ensureClientSession() async => user ?? (await _auth.signInAnonymously()).user!;

  // ── Business ──────────────────────────────────────────────────────────────

  Future<void> businessSignIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> businessSignUp(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  // ── Client: keep cards beyond this browser ─────────────────────────────────

  /// Links this device's anonymous account to Google (same user id, nothing to
  /// move). If that Google account already has Loyi cards, signs into it and
  /// merges this device's cards.
  Future<void> saveWithGoogle() async {
    final provider = GoogleAuthProvider();
    final current = user;
    if (current == null || !current.isAnonymous) {
      await (kIsWeb ? _auth.signInWithPopup(provider) : _auth.signInWithProvider(provider));
      return;
    }
    try {
      await (kIsWeb ? current.linkWithPopup(provider) : current.linkWithProvider(provider));
    } on FirebaseAuthException catch (e) {
      final credential = e.credential;
      if (e.code != 'credential-already-in-use' || credential == null) rethrow;
      await _signInAndMerge((a) => a.signInWithCredential(credential));
    }
  }

  /// New email + password account that keeps this device's cards.
  /// Throws `email-already-in-use` when the client should sign in instead.
  Future<void> createClientAccount(String email, String password) async {
    final current = user;
    if (current != null && current.isAnonymous) {
      await current.linkWithCredential(EmailAuthProvider.credential(email: email, password: password));
    } else {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    }
  }

  /// Signs into an existing client account and brings this device's cards along.
  Future<void> clientSignIn(String email, String password) =>
      _signInAndMerge((a) => a.signInWithEmailAndPassword(email: email, password: password));

  /// Signs in with [signIn] and moves this device's anonymous cards into that
  /// account. firestore.rules check every step:
  ///  1. a helper app signs in to learn the target user id (the anonymous
  ///     session stays active),
  ///  2. the anonymous session writes `transfers/{anonUid} = {toUid}`,
  ///  3. after signing in, each source card is merged into the target card and
  ///     deleted in one transaction.
  Future<void> _signInAndMerge(Future<UserCredential> Function(FirebaseAuth auth) signIn) async {
    final anon = user;
    if (anon == null || !anon.isAnonymous) {
      await signIn(_auth);
      return;
    }
    final cards = (await _db.collection('cards').where('clientUid', isEqualTo: anon.uid).get()).docs;
    if (cards.isEmpty) {
      await signIn(_auth);
      return;
    }

    final helper = await Firebase.initializeApp(
      name: 'loyi-merge-${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    try {
      final helperAuth = FirebaseAuth.instanceFor(app: helper);
      if (useEmulators) await helperAuth.useAuthEmulator(emulatorHost, 9099);
      final toUid = (await signIn(helperAuth)).user!.uid;
      await helperAuth.signOut();
      if (toUid == anon.uid) return;
      await _db.doc('transfers/${anon.uid}').set({'toUid': toUid, 'createdAt': FieldValue.serverTimestamp()});
    } finally {
      await helper.delete();
    }

    await signIn(_auth);
    final me = user!.uid;
    for (final source in cards) {
      final programId = source.get('programId') as String;
      final program = Program.fromDoc(await _db.doc('programs/$programId').get());
      final targetRef = _db.doc('cards/${programId}_$me');
      await _db.runTransaction((tx) async {
        final src = await tx.get(source.reference);
        if (!src.exists) return; // already merged
        final s = LoyaltyCard.fromDoc(src);
        final target = await tx.get(targetRef);
        final now = FieldValue.serverTimestamp();
        if (target.exists) {
          final t = LoyaltyCard.fromDoc(target);
          final merged = mergeProgress(
            (stamps: t.stamps, rewards: t.rewardsAvailable),
            (stamps: s.stamps, rewards: s.rewardsAvailable),
            program.stampsRequired,
          );
          tx.update(targetRef, {
            'stamps': merged.stamps,
            'rewardsAvailable': merged.rewards,
            'totalStamps': t.totalStamps + s.totalStamps,
            'totalRedeemed': t.totalRedeemed + s.totalRedeemed,
            'mergedFrom': anon.uid,
            'updatedAt': now,
          });
        } else {
          tx.set(targetRef, {
            'clientUid': me,
            'businessId': s.businessId,
            'ownerUid': s.ownerUid,
            'programId': programId,
            'stamps': s.stamps,
            'rewardsAvailable': s.rewardsAvailable,
            'totalStamps': s.totalStamps,
            'totalRedeemed': s.totalRedeemed,
            'lastStampAt': src.data()!['lastStampAt'],
            'mergedFrom': anon.uid,
            'createdAt': now,
            'updatedAt': now,
          });
        }
        tx.delete(source.reference);
      });
    }
  }
}

final auth = AuthService();
