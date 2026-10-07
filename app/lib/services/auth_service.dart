import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../models.dart';
import 'api.dart';
import 'billing.dart';
import 'language.dart';
import 'repo.dart';
import 'stamping.dart';

/// How a signed-in user proves it's them before deleting their account.
enum ReauthMethod { none, password, apple, google }

/// Clients start as anonymous users (no sign-up at the counter) and can later
/// save their cards with Google, Apple or email + password. Businesses sign in
/// with email + password, Google or Apple, then pick their brand colours and subscribe.
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

  /// Step 1 of business sign-up: the account plus the shop's name. If creating
  /// the shop fails, the dashboard asks for the name again.
  Future<void> businessSignUp(String email, String password, String businessName) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    try {
      await repo.createBusiness(ownerUid: credential.user!.uid, name: businessName);
    } catch (e) {
      debugPrint('Creating the business failed, the dashboard will ask again: $e');
    }
  }

  /// Sign in with Google; creates the account on first use (the dashboard then
  /// asks for the shop's name).
  Future<void> businessSignInWithGoogle() => _signInWith(_google());

  /// Sign in with Apple; creates the account on first use.
  Future<void> businessSignInWithApple() => _signInWith(_apple());

  Future<void> signOut() => _auth.signOut();

  /// Email with a link to choose a new password (Spark: 150 emails/day).
  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  // ── Client: keep cards beyond this browser ─────────────────────────────────

  /// Links this device's anonymous account to Google (same user id, nothing to
  /// move). If that Google account already has Loyi cards, signs into it and
  /// merges this device's cards.
  Future<void> saveWithGoogle() => _saveWith(_google());

  /// Same as [saveWithGoogle], with Apple.
  Future<void> saveWithApple() => _saveWith(_apple());

  AppleAuthProvider _apple() => AppleAuthProvider()
    ..addScope('email')
    ..addScope('name');

  /// Google asks which account to use every time, so a shop on a shared
  /// computer doesn't land in someone else's Google account by accident.
  GoogleAuthProvider _google() => GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});

  Future<UserCredential> _signInWith(AuthProvider provider) =>
      kIsWeb ? _auth.signInWithPopup(provider) : _auth.signInWithProvider(provider);

  Future<void> _saveWith(AuthProvider provider) async {
    final current = user;
    if (current == null || !current.isAnonymous) {
      await _signInWith(provider);
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

  // ── Account settings ──────────────────────────────────────────────────────

  /// True for accounts with a Loyi password (not only Apple/Google).
  bool get hasPassword => user?.providerData.any((p) => p.providerId == 'password') ?? false;

  Future<void> _reauthenticate(String password) {
    final u = user!;
    return u.reauthenticateWithCredential(EmailAuthProvider.credential(email: u.email!, password: password));
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _reauthenticate(currentPassword);
    await user!.updatePassword(newPassword);
  }

  /// Sends a confirmation link to [newEmail]; the address changes once it's opened.
  Future<void> changeEmail(String password, String newEmail) async {
    await _reauthenticate(password);
    await user!.verifyBeforeUpdateEmail(newEmail);
  }

  // ── Account deletion (App Store / Google Play requirement, GDPR) ─────────

  ReauthMethod get reauthMethod {
    final u = user;
    if (u == null || u.isAnonymous) return ReauthMethod.none;
    final providers = {for (final p in u.providerData) p.providerId};
    if (providers.contains('password')) return ReauthMethod.password;
    if (providers.contains('apple.com')) return ReauthMethod.apple;
    if (providers.contains('google.com')) return ReauthMethod.google;
    return ReauthMethod.none;
  }

  /// Deletes the signed-in account and everything it created. Signing in again
  /// comes first ([password] for email accounts), so a wrong password or a
  /// cancelled Apple/Google sheet throws before anything is deleted.
  Future<void> deleteAccount({String? password}) async {
    final u = user;
    if (u == null) return;

    String? appleCode;
    switch (reauthMethod) {
      case ReauthMethod.password:
        await _reauthenticate(password ?? '');
      case ReauthMethod.apple:
        final credential = kIsWeb
            ? await u.reauthenticateWithPopup(_apple())
            : await u.reauthenticateWithProvider(_apple());
        appleCode = credential.additionalUserInfo?.authorizationCode;
      case ReauthMethod.google:
        await (kIsWeb
            ? u.reauthenticateWithPopup(GoogleAuthProvider())
            : u.reauthenticateWithProvider(GoogleAuthProvider()));
      case ReauthMethod.none:
        break;
    }

    if (!u.isAnonymous) {
      // Stop the subscription first: if that fails, nothing is deleted and the shop can retry.
      try {
        await billing.cancelForAccountDeletion();
      } catch (e) {
        throw LoyiException(l10n.couldNotCancelSubscription);
      }
      await repo.deleteBusinessData(u.uid);
    }
    await repo.deleteClientData(u.uid);
    // Apple requires apps to revoke Sign in with Apple tokens when the account is deleted.
    if (appleCode != null) {
      try {
        await _auth.revokeTokenWithAuthorizationCode(appleCode);
      } catch (e) {
        debugPrint('Apple token revoke failed: $e');
      }
    }
    try {
      await u.delete();
    } on FirebaseAuthException catch (e) {
      // An old anonymous session can't sign in again; its data is gone, so just leave it.
      if (e.code != 'requires-recent-login' || !u.isAnonymous) rethrow;
      await _auth.signOut();
    }
  }
}

final auth = AuthService();
