import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api.dart';
import '../services/auth_service.dart';
import '../services/billing.dart';
import '../services/language.dart';
import '../theme.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/ui.dart';

/// Landing page for `/t/<tagId>`, the URL written on every NFC tag, and for
/// `/q/<programId>/<token>`, the one-time QR code on a shop's screen.
/// Joins/stamps, then replaces the URL with the card page so a browser refresh
/// can't trigger a second stamp.
class TapPage extends StatefulWidget {
  const TapPage({super.key, required String this.tagId}) : qr = null;

  /// A scanned "Stempel uitdelen" code: the billing server spends it and hands out
  /// the card's QR tag with a ticket for one stamp (firestore.rules require it).
  const TapPage.qr({super.key, required String programId, required String token})
    : tagId = null,
      qr = (programId: programId, token: token);

  final String? tagId;
  final ({String programId, String token})? qr;

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
      final result = await _run();
      if (mounted) context.go('/c/${result.cardId}', extra: result);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  Future<TapResult> _run() async {
    final qr = widget.qr;
    if (qr == null) return api.tap(widget.tagId!);
    final claim = await billing.qrClaim(qr.programId, qr.token);
    return api.tap(claim.tagId, ticketId: claim.ticketId);
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
                        const TapPulse(),
                        const SizedBox(height: 28),
                        Text(context.l10n.addingToCard, style: context.text.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text(context.l10n.onlyAMoment, style: context.text.bodyMedium),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: IconBadge(
                            icon: LoyiIcons.nfc,
                            background: p.accentSoft,
                            foreground: p.accent,
                            size: 72,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          context.l10n.thatDidntWorkTitle,
                          style: context.text.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(_error!, style: context.text.bodyMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 28),
                        // A QR code works once: trying the same one again can't help.
                        if (widget.qr == null) FilledButton(onPressed: _tap, child: Text(context.l10n.tryAgain)),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => context.go('/cards'), child: Text(context.l10n.goToMyCards)),
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
class TapPulse extends StatefulWidget {
  const TapPulse({super.key});

  @override
  State<TapPulse> createState() => _TapPulseState();
}

class _TapPulseState extends State<TapPulse> with SingleTickerProviderStateMixin {
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
          child: const Icon(LoyiIcons.nfc, color: Colors.white, size: 36),
        ),
      ),
    );
  }
}
