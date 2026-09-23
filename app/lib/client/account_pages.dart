import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api.dart';
import '../services/auth_service.dart';
import '../theme.dart';

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
    final text = Theme.of(context).textTheme;
    final user = auth.user;
    final signedInEmail = user != null && !user.isAnonymous ? user.email : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (signedInEmail != null) ...[
                  Text('Your cards are saved', style: text.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Signed in as $signedInEmail'),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () async {
                      await auth.signOut();
                      if (context.mounted) context.go('/cards');
                    },
                    child: const Text('Sign out'),
                  ),
                ] else if (_sentTo != null) ...[
                  const Icon(Icons.mark_email_read_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text('Check your inbox', style: text.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a sign-in link to $_sentTo. Open it on this phone to save your cards.',
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text('Keep your cards safe', style: text.headlineSmall),
                  const SizedBox(height: 8),
                  const Text(
                    "Your stamps are stored on this phone. Add your email and we'll send you a link. "
                    'No password needed. You can then open your cards on any device.',
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(labelText: 'Email', errorText: _error),
                    onSubmitted: (_) => _send(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _busy ? null : _send, child: const Text('Send me a link')),
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
