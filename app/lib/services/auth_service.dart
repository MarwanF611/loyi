import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'api.dart';

/// Clients start as anonymous users (no sign-up at the counter) and can later
/// attach an email via a magic link so their cards survive a new phone.
/// Businesses sign in with email + password.
class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  static const _pendingEmailKey = 'loyi.pendingEmail';

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

  // ── Client email link ─────────────────────────────────────────────────────

  Future<void> sendClientEmailLink(String email) async {
    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: ActionCodeSettings(url: '$publicBaseUrl/account/finish', handleCodeInApp: true),
    );
    await (await SharedPreferences.getInstance()).setString(_pendingEmailKey, email);
  }

  bool isEmailLink(String link) => _auth.isSignInWithEmailLink(link);

  Future<String?> pendingEmail() async => (await SharedPreferences.getInstance()).getString(_pendingEmailKey);

  /// Signs in with the email link and moves any cards collected anonymously on
  /// this device into the (new or existing) email account.
  Future<void> completeEmailLink({required String email, required String link}) async {
    final previous = user;
    final anonToken = previous != null && previous.isAnonymous ? await previous.getIdToken() : null;

    await _auth.signInWithEmailLink(email: email, emailLink: link);
    if (anonToken != null) await api.mergeAccount(anonToken);
    await (await SharedPreferences.getInstance()).remove(_pendingEmailKey);
  }
}

final auth = AuthService();
