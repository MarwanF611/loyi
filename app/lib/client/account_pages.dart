import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../account/account_privacy.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../services/language.dart';
import '../theme.dart';
import '../widgets/account_widgets.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/ui.dart';

/// Lets a client save their cards (so they survive a new phone or browser)
/// with Google, Apple or email + password, and delete their data.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _existing = false;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.cardsSaved)));
      context.go('/cards');
    } on FirebaseAuthException catch (e) {
      final apple = appleSignInMessage(e);
      setState(
        () => _error = apple != null
            ? (apple.isEmpty ? null : apple)
            : switch (e.code) {
                'popup-closed-by-user' || 'cancelled-popup-request' || 'canceled' || 'web-context-canceled' => null,
                'account-exists-with-different-credential' => l10n.emailOtherMethod,
                'email-already-in-use' || 'credential-already-in-use' => l10n.emailHasAccountChoose,
                'invalid-credential' || 'wrong-password' || 'user-not-found' => l10n.wrongEmailOrPassword,
                'weak-password' => l10n.passwordTooShort6,
                'invalid-email' => l10n.invalidEmail,
                'operation-not-allowed' => l10n.signInMethodDisabled,
                _ => e.message ?? l10n.couldNotSignIn,
              },
      );
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = l10n.enterEmailFirst);
      return;
    }
    try {
      await auth.sendPasswordReset(email);
    } on FirebaseAuthException catch (_) {
      // Same answer for unknown emails, so accounts can't be probed.
    }
    if (mounted) {
      setState(() {
        _error = null;
        _info = l10n.resetLinkSent(email);
      });
    }
  }

  void _onDeleted() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.accountAndCardsDeleted)));
    context.go('/cards');
  }

  void _submitPassword() {
    final email = _email.text.trim();
    final password = _password.text;
    _run(() => _existing ? auth.clientSignIn(email, password) : auth.createClientAccount(email, password));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    final user = auth.user;
    final signedIn = user != null && !user.isAnonymous;

    Widget header(IconData icon, Color bg, Color fg, String title, String body) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBadge(icon: icon, background: bg, foreground: fg, size: 56),
        const SizedBox(height: 18),
        Text(title, style: context.text.headlineLarge),
        const SizedBox(height: 8),
        Text(body, style: context.text.bodyMedium),
        const SizedBox(height: 24),
      ],
    );

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (signedIn) ...[
                  header(
                    LoyiIcons.shieldCheck,
                    p.mintSoft,
                    p.mint,
                    context.l10n.yourCardsAreSaved,
                    context.l10n.yourCardsAreSavedSub,
                  ),
                  AccountPrivacySections(business: false, onDeleted: _onDeleted),
                ] else ...[
                  header(
                    LoyiIcons.cloudCheck,
                    p.mintSoft,
                    p.mint,
                    context.l10n.keepCardsSafe,
                    context.l10n.keepCardsSafeSub,
                  ),
                  GoogleSignInButton(onPressed: _busy ? null : () => _run(auth.saveWithGoogle)),
                  const SizedBox(height: 12),
                  AppleSignInButton(onPressed: _busy ? null : () => _run(auth.saveWithApple)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: LabeledDivider(context.l10n.orWithEmail),
                  ),
                  Panel(
                    padding: const EdgeInsets.all(20),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(value: false, label: Text(context.l10n.newAccount)),
                              ButtonSegment(value: true, label: Text(context.l10n.iHaveAnAccount)),
                            ],
                            selected: {_existing},
                            onSelectionChanged: (s) => setState(() {
                              _existing = s.first;
                              _error = null;
                              _info = null;
                            }),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: context.l10n.email,
                              prefixIcon: const Icon(LoyiIcons.atSign),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _password,
                            obscureText: true,
                            autofillHints: [_existing ? AutofillHints.password : AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: context.l10n.password,
                              prefixIcon: const Icon(LoyiIcons.lock),
                            ),
                            onSubmitted: (_) => _submitPassword(),
                          ),
                          if (_existing)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(onPressed: _resetPassword, child: Text(context.l10n.forgotPassword)),
                            ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _busy ? null : _submitPassword,
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5),
                                  )
                                : Text(_existing ? context.l10n.signIn : context.l10n.saveMyCards),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_info != null) ...[
                    const SizedBox(height: 14),
                    Text(_info!, style: context.text.labelMedium?.copyWith(color: p.mint)),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: context.text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 32),
                  AccountPrivacySections(business: false, onDeleted: _onDeleted),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
