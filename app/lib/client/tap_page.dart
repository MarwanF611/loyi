import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api.dart';
import '../services/auth_service.dart';
import '../theme.dart';

/// Landing page for `/t/<tagId>`, the URL written on every NFC tag.
/// Joins/stamps on the server, then replaces the URL with the card page so a
/// browser refresh can't trigger a second stamp.
class TapPage extends StatefulWidget {
  const TapPage({super.key, required this.tagId});

  final String tagId;

  @override
  State<TapPage> createState() => _TapPageState();
}

class _TapPageState extends State<TapPage> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _tap();
  }

  Future<void> _tap() async {
    setState(() => _error = null);
    try {
      await auth.ensureClientSession();
      final result = await api.tap(widget.tagId);
      if (mounted) context.go('/c/${result.cardId}', extra: result);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: PageBody(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _error == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text('Loading your card…', style: text.titleMedium),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.nfc_rounded, size: 56),
                        const SizedBox(height: 16),
                        Text(_error!, style: text.titleMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton(onPressed: _tap, child: const Text('Try again')),
                        TextButton(onPressed: () => context.go('/cards'), child: const Text('My cards')),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
