import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/language.dart';
import '../theme.dart';
import '../widgets/account_widgets.dart';
import '../widgets/loyalty_card_view.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/ui.dart';

class BusinessLoginPage extends StatefulWidget {
  const BusinessLoginPage({super.key, this.signUp = false});

  /// Open on "Create account" (the website's Get started buttons link to ?signup=1).
  final bool signUp;

  @override
  State<BusinessLoginPage> createState() => _BusinessLoginPageState();
}

class _BusinessLoginPageState extends State<BusinessLoginPage> {
  final _businessName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late bool _signUp = widget.signUp;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _businessName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (_signUp) {
      final name = _businessName.text.trim();
      final problem = name.isEmpty
          ? context.l10n.enterBusinessName
          : _password.text.length < 8
          ? context.l10n.passwordTooShort
          : null;
      if (problem != null) {
        setState(() => _error = problem);
        return;
      }
      return _run(() => auth.businessSignUp(email, _password.text, name));
    }
    return _run(() => auth.businessSignIn(email, _password.text));
  }

  Future<void> _run(Future<void> Function() signIn) async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await signIn();
      // The router redirects to /business once the auth state changes.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(
        () => _error = switch (e.code) {
          'invalid-credential' || 'wrong-password' || 'user-not-found' => l10n.wrongEmailOrPassword,
          'email-already-in-use' => l10n.emailInUse,
          'account-exists-with-different-credential' => l10n.emailHasAccount,
          'weak-password' => l10n.passwordTooShort,
          'invalid-email' => l10n.invalidEmail,
          'operation-not-allowed' => l10n.signInMethodDisabled,
          'too-many-requests' => l10n.tooManyAttempts,
          // Closing the Google popup isn't an error.
          'canceled' || 'web-context-canceled' || 'popup-closed-by-user' || 'cancelled-popup-request' => null,
          _ => e.message ?? l10n.couldNotSignIn,
        },
      );
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
    setState(() {
      _error = null;
      _info = null;
    });
    try {
      await auth.sendPasswordReset(email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        setState(() => _error = l10n.invalidEmail);
        return;
      }
      // Other errors (e.g. unknown email) get the same answer, so accounts can't be probed.
    }
    if (mounted) setState(() => _info = l10n.resetLinkSent(email));
  }

  Widget _form(BuildContext context) {
    final p = context.loyi;
    final l = context.l10n;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(alignment: Alignment.centerRight, child: LanguageMenu()),
          Text(_signUp ? l.startWithLoyi : l.welcomeBack, style: context.text.headlineLarge),
          const SizedBox(height: 6),
          Text(_signUp ? l.signUpSteps : l.signInSub, style: context.text.bodyMedium),
          const SizedBox(height: 28),
          GoogleSignInButton(onPressed: _busy ? null : () => _run(auth.businessSignInWithGoogle)),
          const SizedBox(height: 20),
          LabeledDivider(l.orWithEmail),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text(l.signIn)),
              ButtonSegment(value: true, label: Text(l.createAccount)),
            ],
            selected: {_signUp},
            onSelectionChanged: (s) => setState(() {
              _signUp = s.first;
              _error = null;
              _info = null;
            }),
          ),
          const SizedBox(height: 20),
          if (_signUp) ...[
            TextField(
              controller: _businessName,
              autocorrect: false,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l.businessName,
                hintText: l.businessNameHint,
                prefixIcon: const Icon(LoyiIcons.store),
                counterText: '',
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l.email, prefixIcon: const Icon(LoyiIcons.atSign)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            obscureText: !_showPassword,
            autofillHints: [_signUp ? AutofillHints.newPassword : AutofillHints.password],
            decoration: InputDecoration(
              labelText: l.password,
              prefixIcon: const Icon(LoyiIcons.lock),
              suffixIcon: IconButton(
                tooltip: _showPassword ? l.hidePassword : l.showPassword,
                icon: Icon(_showPassword ? LoyiIcons.eyeOff : LoyiIcons.eye),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (!_signUp)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _resetPassword, child: Text(l.forgotPassword)),
            ),
          if (_info != null) ...[
            const SizedBox(height: 8),
            Panel(
              color: p.mintSoft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              radius: Radii.md,
              child: Row(
                children: [
                  Icon(LoyiIcons.mailCheck, color: p.mint, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_info!, style: context.text.labelMedium)),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Panel(
              color: p.accentSoft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              radius: Radii.md,
              child: Row(
                children: [
                  Icon(LoyiIcons.circleAlert, color: p.onAccentSoft, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_error!, style: context.text.labelMedium?.copyWith(color: p.onAccentSoft)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : Text(_signUp ? l.createAccount : l.signIn),
          ),
          const SizedBox(height: 16),
          if (_signUp) Text(l.agreeToTerms, style: context.text.bodySmall, textAlign: TextAlign.center),
          const LegalLinks(),
          // Clients land here by mistake on the website; send them back to their cards.
          if (kIsWeb)
            TextButton.icon(
              onPressed: () => context.go('/cards'),
              icon: const Icon(LoyiIcons.walletCards, size: 20),
              label: Text(l.collectingStamps),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        final form = Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!wide) ...[const LoyiWordmark(size: 34), const SizedBox(height: 40)],
                  _form(context),
                ],
              ),
            ),
          ),
        );
        if (!wide) return SafeArea(child: form);
        return Row(
          children: [
            const Expanded(flex: 11, child: _BrandPanel()),
            Expanded(flex: 10, child: form),
          ],
        );
      },
    ),
  );
}

/// Coral showcase panel on wide screens: wordmark, promise and example cards.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    const white = Colors.white;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.accent, Color.lerp(p.accent, const Color(0xFF7A1D0C), 0.35)!],
        ),
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoyiWordmark(size: 36, color: white),
          const Spacer(),
          Text(context.l10n.heroTitle, style: context.text.displayMedium?.copyWith(color: white)),
          const SizedBox(height: 16),
          Text(context.l10n.heroSub, style: context.text.bodyLarge?.copyWith(color: white.withValues(alpha: 0.85))),
          const SizedBox(height: 40),
          SizedBox(
            height: 250,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 150,
                  top: 0,
                  width: 340,
                  child: Transform.rotate(
                    angle: math.pi / 40,
                    child: const LoyaltyCardView(
                      businessName: 'Koffiebar Mokka',
                      programName: 'Koffiekaart',
                      design: CardDesign(
                        background: 0xFF263238,
                        style: CardStyle.pattern,
                        stampColor: 0xFFFFD699,
                        stampIcon: 'coffee',
                      ),
                      stamps: 6,
                      stampsRequired: 8,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 40,
                  width: 340,
                  child: Transform.rotate(
                    angle: -math.pi / 50,
                    child: const LoyaltyCardView(
                      businessName: 'Bakkerij Peeters',
                      programName: 'Broodjeskaart',
                      design: CardDesign(
                        background: 0xFFFFFFFF,
                        style: CardStyle.solid,
                        stampColor: 0xFFFF5A3C,
                        stampIcon: 'croissant',
                      ),
                      stamps: 3,
                      stampsRequired: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
