import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/loyalty_card_view.dart';
import '../widgets/ui.dart';

class BusinessLoginPage extends StatefulWidget {
  const BusinessLoginPage({super.key});

  @override
  State<BusinessLoginPage> createState() => _BusinessLoginPageState();
}

class _BusinessLoginPageState extends State<BusinessLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = _email.text.trim();
      if (_signUp) {
        await auth.businessSignUp(email, _password.text);
      } else {
        await auth.businessSignIn(email, _password.text);
      }
      // The router redirects to /business once the auth state changes.
    } on FirebaseAuthException catch (e) {
      setState(
        () => _error = switch (e.code) {
          'invalid-credential' || 'wrong-password' || 'user-not-found' => 'Wrong email or password.',
          'email-already-in-use' => 'An account with this email already exists. Sign in instead.',
          'weak-password' => 'Use at least 6 characters for your password.',
          'invalid-email' => 'Enter a valid email address.',
          _ => e.message ?? 'Could not sign in.',
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _form(BuildContext context) {
    final p = context.loyi;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_signUp ? 'Start with Loyi' : 'Welcome back', style: context.text.headlineLarge),
          const SizedBox(height: 6),
          Text(
            _signUp
                ? 'Create your shop account. Your first card is ready in 2 minutes.'
                : 'Sign in to manage your loyalty cards.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: 28),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('Sign in')),
              ButtonSegment(value: true, label: Text('Create account')),
            ],
            selected: {_signUp},
            onSelectionChanged: (s) => setState(() {
              _signUp = s.first;
              _error = null;
            }),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email_rounded)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            obscureText: !_showPassword,
            autofillHints: [_signUp ? AutofillHints.newPassword : AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _showPassword ? 'Hide password' : 'Show password',
                icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Panel(
              color: p.accentSoft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              radius: Radii.md,
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: p.onAccentSoft, size: 20),
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
                : Text(_signUp ? 'Create account' : 'Sign in'),
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
          Text('Stamp cards your\nclients actually keep.', style: context.text.displayMedium?.copyWith(color: white)),
          const SizedBox(height: 16),
          Text(
            'One tap on an NFC tag. No app to install. Your logo, your colours, your rewards.',
            style: context.text.bodyLarge?.copyWith(color: white.withValues(alpha: 0.85)),
          ),
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
