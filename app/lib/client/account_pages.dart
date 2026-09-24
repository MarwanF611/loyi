import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// Lets a client save their cards (so they survive a new phone or browser)
/// with Google or email + password.
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your cards are saved.')));
      context.go('/cards');
    } on FirebaseAuthException catch (e) {
      setState(
        () => _error = switch (e.code) {
          'popup-closed-by-user' || 'cancelled-popup-request' => null,
          'email-already-in-use' ||
          'credential-already-in-use' => 'This email already has an account. Choose "I have an account".',
          'invalid-credential' || 'wrong-password' || 'user-not-found' => 'Wrong email or password.',
          'weak-password' => 'Use at least 6 characters for your password.',
          'invalid-email' => 'Enter a valid email address.',
          'operation-not-allowed' => 'This sign-in method is not enabled yet.',
          _ => e.message ?? 'Could not sign in.',
        },
      );
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
                    Icons.verified_user_rounded,
                    p.mintSoft,
                    p.mint,
                    'Your cards are saved',
                    'Sign in with this account on any device to see your cards.',
                  ),
                  Panel(
                    child: Row(
                      children: [
                        Icon(Icons.person_outline_rounded, color: p.inkMuted),
                        const SizedBox(width: 12),
                        Expanded(child: Text(user.email ?? user.displayName ?? '', style: context.text.titleMedium)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () async {
                      await auth.signOut();
                      if (context.mounted) context.go('/cards');
                    },
                    child: const Text('Sign out'),
                  ),
                ] else ...[
                  header(
                    Icons.cloud_done_rounded,
                    p.mintSoft,
                    p.mint,
                    'Keep your cards safe',
                    'Your stamps are stored in this browser. Save them to an account and they '
                        'follow you to any phone. Already have an account? Your cards from this '
                        'device are added to it.',
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run(auth.saveWithGoogle),
                    icon: const _GoogleMark(),
                    label: const Text('Continue with Google'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or with email', style: context.text.bodySmall),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),
                  Panel(
                    padding: const EdgeInsets.all(20),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(value: false, label: Text('New account')),
                              ButtonSegment(value: true, label: Text('I have an account')),
                            ],
                            selected: {_existing},
                            onSelectionChanged: (s) => setState(() {
                              _existing = s.first;
                              _error = null;
                            }),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _password,
                            obscureText: true,
                            autofillHints: [_existing ? AutofillHints.password : AutofillHints.newPassword],
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                            onSubmitted: (_) => _submitPassword(),
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
                                : Text(_existing ? 'Sign in' : 'Save my cards'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: context.text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Google's multicolour "G", drawn so no image asset is needed.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GPainter()));
}

class _GPainter extends CustomPainter {
  const _GPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: Offset(r, r), radius: r * 0.78);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.42;
    const deg = 3.14159265 / 180;
    for (final (start, sweep, color) in const [
      (-40.0, -95.0, Color(0xFFEA4335)),
      (-135.0, -90.0, Color(0xFFFBBC05)),
      (135.0, -95.0, Color(0xFF34A853)),
      (40.0, -80.0, Color(0xFF4285F4)),
    ]) {
      canvas.drawArc(rect, start * deg, sweep * deg, false, stroke..color = color);
    }
    canvas.drawRect(Rect.fromLTWH(r, r - r * 0.21, r * 0.98, r * 0.42), Paint()..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
