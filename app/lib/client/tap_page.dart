import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/ui.dart';

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
    final p = context.loyi;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: PageBody(
              maxWidth: 420,
              child: _error == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Pulse(),
                        const SizedBox(height: 28),
                        Text('Adding to your card…', style: context.text.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text('This only takes a moment.', style: context.text.bodyMedium),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: IconBadge(
                            icon: Icons.nfc_rounded,
                            background: p.accentSoft,
                            foreground: p.accent,
                            size: 72,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('That didn’t work', style: context.text.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text(_error!, style: context.text.bodyMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 28),
                        FilledButton(onPressed: _tap, child: const Text('Try again')),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => context.go('/cards'), child: const Text('Go to my cards')),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Coral NFC badge with expanding rings while the tap is processed.
class _Pulse extends StatefulWidget {
  const _Pulse();

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return SizedBox(
      width: 160,
      height: 160,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            for (final offset in [0.0, 0.5])
              Builder(
                builder: (_) {
                  final t = (_c.value + offset) % 1;
                  return Container(
                    width: 72 + 88 * t,
                    height: 72 + 88 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.accent.withValues(alpha: 0.18 * (1 - t)),
                    ),
                  );
                },
              ),
            child!,
          ],
        ),
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: p.accent,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: const Icon(Icons.nfc_rounded, color: Colors.white, size: 36),
        ),
      ),
    );
  }
}
