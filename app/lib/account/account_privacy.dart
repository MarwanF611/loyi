import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../config.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../services/data_export.dart';
import '../services/save_file/save_file.dart';
import '../theme.dart';
import '../widgets/account_widgets.dart';
import '../widgets/ui.dart';

/// Account & privacy for shops and clients: what we store, email and password,
/// a copy of your data, and deleting everything (GDPR art. 15–17 and 20).
class AccountPrivacySections extends StatelessWidget {
  const AccountPrivacySections({super.key, required this.business, required this.onDeleted});

  final bool business;

  /// Called after the account is deleted, to leave the page.
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();
    final anonymous = user.isAnonymous;
    final providers = {for (final p in user.providerData) p.providerId};
    final method = providers.contains('password')
        ? 'Email and password'
        : providers.contains('apple.com')
        ? 'Sign in with Apple'
        : providers.contains('google.com')
        ? 'Google'
        : 'Not saved (this browser only)';
    final since = user.metadata.creationTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          title: 'Your account',
          children: [
            if (!anonymous) _Row(label: 'Email', value: user.email ?? '—'),
            _Row(label: 'Sign-in', value: method),
            if (since != null) _Row(label: 'Member since', value: DateFormat('d MMMM y').format(since)),
          ],
        ),
        if (!anonymous) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Sign-in & security',
            children: auth.hasPassword
                ? [
                    _ActionTile(
                      icon: Icons.alternate_email_rounded,
                      title: 'Change email',
                      onTap: () => showDialog<void>(context: context, builder: (_) => const _ChangeEmailDialog()),
                    ),
                    _ActionTile(
                      icon: Icons.password_rounded,
                      title: 'Change password',
                      onTap: () => showDialog<void>(context: context, builder: (_) => const _ChangePasswordDialog()),
                    ),
                  ]
                : [
                    Text(
                      'You sign in with ${method == 'Google' ? 'Google' : 'Apple'}, so there is no Loyi password. '
                      'Manage your email and security in your ${method == 'Google' ? 'Google' : 'Apple'} account.',
                      style: context.text.bodyMedium,
                    ),
                  ],
          ),
        ],
        const SizedBox(height: 16),
        _Section(
          title: 'Your data',
          children: [
            Text(
              business
                  ? 'Loyi stores your account, your shop (name, colours, logo), your loyalty cards and tags, your '
                        'subscription status and your clients\' stamps and rewards under anonymous IDs.'
                  : 'Loyi stores your cards, stamps and rewards per shop${anonymous ? '' : ', and your email'}. '
                        'Shops only see an anonymous ID, never your email.',
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: 12),
            const _DownloadButton(),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => openUrl(privacyUrl), child: const Text('Read the privacy policy')),
            ),
          ],
        ),
        if (business) ...[
          const SizedBox(height: 16),
          Panel(
            onTap: () => context.go('/business/subscribe'),
            child: Row(
              children: [
                IconBadge(
                  icon: Icons.workspace_premium_rounded,
                  background: context.loyi.sunSoft,
                  foreground: context.loyi.ink,
                ),
                const SizedBox(width: 14),
                Expanded(child: Text('Subscription', style: context.text.titleMedium)),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (!anonymous)
          OutlinedButton(
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) context.go(business ? '/business/login' : '/cards');
            },
            child: const Text('Sign out'),
          ),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          onPressed: () async {
            if (await showDeleteAccountDialog(context, business: business)) onDeleted();
          },
          child: Text(anonymous ? 'Delete the cards on this device' : 'Delete account'),
        ),
        const SizedBox(height: 8),
        const LegalLinks(),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: context.text.titleLarge),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.bodySmall),
        Text(value, style: context.text.bodyLarge?.copyWith(color: context.loyi.ink)),
      ],
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: context.loyi.ink),
    title: Text(title, style: context.text.titleMedium),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _DownloadButton extends StatefulWidget {
  const _DownloadButton();

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  bool _busy = false;

  Future<void> _download() async {
    setState(() => _busy = true);
    try {
      final bytes = await exportMyData();
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await saveFile('loyi-data-$date.json', bytes, mimeType: 'application/json', origin: origin);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: _busy ? null : _download,
    icon: _busy
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : const Icon(Icons.download_rounded),
    label: const Text('Download my data'),
  );
}

String _authMessage(FirebaseAuthException e) => switch (e.code) {
  'wrong-password' || 'invalid-credential' => 'Wrong password.',
  'weak-password' => 'Use at least 8 characters for your new password.',
  'email-already-in-use' => 'Another account already uses this email.',
  'invalid-email' => 'Enter a valid email address.',
  'too-many-requests' => 'Too many attempts. Try again in a few minutes.',
  'requires-recent-login' => 'Please sign in again and retry.',
  _ => e.message ?? 'That didn\'t work. Please try again.',
};

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final error = _next.text.length < 8
        ? 'Use at least 8 characters for your new password.'
        : _next.text != _repeat.text
        ? 'The new passwords don\'t match.'
        : null;
    setState(() => _error = error);
    if (error != null) return;
    setState(() => _busy = true);
    try {
      await auth.changePassword(_current.text, _next.text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your password is changed.')));
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _authMessage(e));
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Change password'),
    content: AutofillGroup(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _current,
              obscureText: true,
              autofocus: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _next,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repeat,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(labelText: 'Repeat new password', errorText: _error, errorMaxLines: 3),
              onSubmitted: (_) => _busy ? null : _save(),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _busy ? null : _save, child: const Text('Save')),
    ],
  );
}

class _ChangeEmailDialog extends StatefulWidget {
  const _ChangeEmailDialog();

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
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
      await auth.changeEmail(_password.text, email);
      if (mounted) setState(() => _sentTo = email);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _authMessage(e));
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sentTo != null) {
      return AlertDialog(
        title: const Text('Check your inbox'),
        content: Text(
          'We sent a link to $_sentTo. Your email changes as soon as you open it. Until then, keep signing in '
          'with ${auth.user?.email}.',
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      );
    }
    return AlertDialog(
      title: const Text('Change email'),
      content: AutofillGroup(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _email,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'New email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(labelText: 'Your password', errorText: _error, errorMaxLines: 3),
                onSubmitted: (_) => _busy ? null : _save(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Send link')),
      ],
    );
  }
}
