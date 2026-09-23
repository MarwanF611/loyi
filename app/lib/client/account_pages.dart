import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// Lets an anonymous client attach an email (magic link) so cards survive a new phone.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _sentTo;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.sendClientEmailLink(email);
      setState(() => _sentTo = email);
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    final user = auth.user;
    final signedInEmail = user != null && !user.isAnonymous ? user.email : null;

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
                if (signedInEmail != null) ...[
                  header(
                    Icons.verified_user_rounded,
                    p.mintSoft,
                    p.mint,
                    'Your cards are saved',
                    'Open Loyi on any device and sign in with this email to see your cards.',
                  ),
                  Panel(
                    child: Row(
                      children: [
                        Icon(Icons.mail_outline_rounded, color: p.inkMuted),
                        const SizedBox(width: 12),
                        Expanded(child: Text(signedInEmail, style: context.text.titleMedium)),
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
                ] else if (_sentTo != null) ...[
                  header(
                    Icons.mark_email_read_rounded,
                    p.accentSoft,
                    p.accent,
                    'Check your inbox',
                    'We sent a sign-in link to $_sentTo. Open it on this phone to save your cards.',
                  ),
                  TextButton(onPressed: () => setState(() => _sentTo = null), child: const Text('Use another email')),
                ] else ...[
                  header(
                    Icons.cloud_done_rounded,
                    p.mintSoft,
                    p.mint,
                    'Keep your cards safe',
                    "Your stamps are stored in this browser. Add your email and we'll send you a link: "
                        'no password needed, and your cards follow you to any device.',
                  ),
                  Panel(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.alternate_email_rounded),
                            errorText: _error,
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _busy ? null : _send, child: const Text('Send me a link')),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Target of the email magic link (`/account/finish?...`).
class FinishAccountPage extends StatefulWidget {
  const FinishAccountPage({super.key});

  @override
  State<FinishAccountPage> createState() => _FinishAccountPageState();
}

class _FinishAccountPageState extends State<FinishAccountPage> {
  final _email = TextEditingController();
  final _link = Uri.base.toString();
  bool _needsEmail = false;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!auth.isEmailLink(_link)) {
      setState(() {
        _busy = false;
        _error = 'This link is invalid or has expired.';
      });
      return;
    }
    final email = await auth.pendingEmail();
    if (email == null) {
      // Link opened on a different device/browser: ask again (Firebase requires it).
      setState(() {
        _busy = false;
        _needsEmail = true;
      });
      return;
    }
    await _complete(email);
  }

  Future<void> _complete(String email) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.completeEmailLink(email: email, link: _link);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your cards are saved.')));
      context.go('/cards');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'This link is invalid or has expired.');
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Saving your cards')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_busy) const Center(child: CircularProgressIndicator()),
              if (_error != null) ...[
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => context.go('/account'), child: const Text('Send a new link')),
              ],
              if (_needsEmail && !_busy && _error == null) ...[
                const Text('Confirm the email address you used:'),
                const SizedBox(height: 16),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => _complete(_email.text.trim()), child: const Text('Continue')),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
