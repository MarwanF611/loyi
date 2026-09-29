import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../theme.dart';

/// "Sign in with Apple" in Apple's style: black in light mode, white in dark mode.
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({super.key, required this.onPressed, this.label = 'Continue with Apple'});

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? Colors.white : Colors.black;
    final fg = dark ? Colors.black : Colors.white;
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: 0.4),
        disabledForegroundColor: fg.withValues(alpha: 0.7),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.apple, size: 24),
      label: Text(label),
    );
  }
}

/// Sign in with Apple errors arrive as raw AuthenticationServices errors:
/// 1001 is the user cancelling, 1000 usually means no Apple Account on the device.
/// Returns null when [e] isn't one of those, '' for a cancel (show nothing).
String? appleSignInMessage(FirebaseAuthException e) {
  final message = e.message ?? '';
  if (!message.contains('AuthorizationError')) return null;
  if (message.contains('1001')) return '';
  return 'Sign in with Apple didn\'t work. Check that you\'re signed in to your Apple Account in Settings, '
      'or use email.';
}

/// Divider with a short label in the middle ("or with email").
class LabeledDivider extends StatelessWidget {
  const LabeledDivider(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label, style: context.text.bodySmall),
      ),
      const Expanded(child: Divider()),
    ],
  );
}

Future<void> openUrl(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Privacy policy and terms, required on sign-up and purchase screens by both stores.
class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key, this.alignment = WrapAlignment.center});

  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      textStyle: context.text.labelMedium,
      foregroundColor: context.loyi.inkMuted,
    );
    return Wrap(
      alignment: alignment,
      children: [
        TextButton(style: style, onPressed: () => openUrl(privacyUrl), child: const Text('Privacy policy')),
        TextButton(style: style, onPressed: () => openUrl(termsUrl), child: const Text('Terms of use')),
      ],
    );
  }
}

/// Asks for confirmation (and the password, for email accounts), then deletes
/// the account and all its data. Returns true when the account is gone.
Future<bool> showDeleteAccountDialog(BuildContext context, {required bool business}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteAccountDialog(business: business),
    ) ??
    false;

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.business});

  final bool business;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  final _method = auth.reauthMethod;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.deleteAccount(password: _password.text);
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final apple = appleSignInMessage(e);
      setState(
        () => _error = apple != null
            ? (apple.isEmpty ? null : apple)
            : switch (e.code) {
                'wrong-password' || 'invalid-credential' => 'Wrong password.',
                'popup-closed-by-user' || 'cancelled-popup-request' || 'web-context-canceled' || 'canceled' => null,
                'user-mismatch' => 'Confirm with the same account you are signed in with.',
                'too-many-requests' => 'Too many attempts. Try again in a few minutes.',
                _ => e.message ?? 'Could not delete your account.',
              },
      );
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return AlertDialog(
      title: const Text('Delete account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.business
                  ? 'Your shop, its loyalty cards and tags, your clients\' stamps for your shop and your '
                        'activity history are permanently deleted. Your tags stop working.'
                  : 'Your saved cards, stamps and rewards are permanently deleted. This can\'t be undone.',
              style: context.text.bodyMedium,
            ),
            if (widget.business) ...[
              const SizedBox(height: 12),
              Text(
                'Deleting your account doesn\'t cancel a subscription. If you subscribed, cancel it first '
                'under Subscription → Manage subscription.',
                style: context.text.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            switch (_method) {
              ReauthMethod.password => TextField(
                controller: _password,
                obscureText: true,
                autofocus: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Your password'),
                onSubmitted: (_) => _busy ? null : _delete(),
              ),
              ReauthMethod.apple => Text('You\'ll confirm with Apple.', style: context.text.bodySmall),
              ReauthMethod.google => Text('You\'ll confirm with Google.', style: context.text.bodySmall),
              ReauthMethod.none => const SizedBox.shrink(),
            },
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: context.text.labelMedium?.copyWith(color: error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: error, foregroundColor: Colors.white),
          onPressed: _busy ? null : _delete,
          child: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Text('Delete account'),
        ),
      ],
    );
  }
}
