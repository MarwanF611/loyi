import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../config.dart';
import '../models.dart';
import '../services/api.dart';
import '../services/billing.dart';
import '../services/language.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/ui.dart';
import 'shell.dart';

/// "Stempel uitdelen" on the Overview: opens the QR screen for the shop's card, or asks which card first.
/// Hidden while the shop has no active card.
class GiveStampButton extends StatelessWidget {
  const GiveStampButton({super.key});

  @override
  Widget build(BuildContext context) {
    final active = [
      for (final p in BusinessData.of(context).programs ?? const <Program>[])
        if (p.active) p,
    ];
    if (active.isEmpty) return const SizedBox.shrink();
    return FilledButton.icon(
      onPressed: () => active.length == 1 ? _open(context, active.single) : _choose(context, active),
      icon: const Icon(LoyiIcons.qrCode),
      label: Text(context.l10n.giveStamp),
    );
  }

  void _open(BuildContext context, Program program) => context.push('/business/give-stamp/${program.id}');

  Future<void> _choose(BuildContext context, List<Program> programs) async {
    final chosen = await showLoyiSheet<Program>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(sheet.l10n.chooseCardToStamp, style: sheet.text.headlineSmall),
          const SizedBox(height: 16),
          for (final p in programs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Panel(
                onTap: () => Navigator.pop(sheet, p),
                child: Row(
                  children: [
                    Expanded(child: Text(p.name, style: sheet.text.titleMedium)),
                    const Icon(LoyiIcons.chevronRight),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (chosen != null && context.mounted) _open(context, chosen);
  }
}

enum _Phase { loading, showing, scanned, expired, failed }

/// Full screen at the counter: a QR code for one stamp, valid for a minute. The customer scans it with the
/// phone's camera (`/q/<programId>/<token>`); the billing server turns the scan into a one-time stamp ticket.
class GiveStampPage extends StatefulWidget {
  const GiveStampPage({super.key, required this.programId});

  final String programId;

  @override
  State<GiveStampPage> createState() => _GiveStampPageState();
}

class _GiveStampPageState extends State<GiveStampPage> {
  static const _validFor = Duration(seconds: 60);

  late final Stream<Program?> _program = repo.program(widget.programId);
  _Phase _phase = _Phase.loading;
  String? _token;
  DateTime _until = DateTime.now();
  String? _error;
  Timer? _tick;
  StreamSubscription<Object?>? _offer;

  @override
  void initState() {
    super.initState();
    _newCode();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _offer?.cancel();
    super.dispose();
  }

  Future<void> _newCode() async {
    _tick?.cancel();
    setState(() {
      _phase = _Phase.loading;
      _error = null;
    });
    try {
      final offer = await billing.qrOffer(widget.programId);
      if (!mounted) return;
      // Count down on this device's clock: the server decides anyway, this is what the shop sees.
      final left = offer.expiresAt.difference(DateTime.now());
      setState(() {
        _token = offer.token;
        _until = DateTime.now().add(left > Duration.zero && left <= _validFor ? left : _validFor);
        _phase = _Phase.showing;
      });
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
      // The offer exists now (the rules only let the shop read an existing one of its own).
      _offer ??= repo.stampOffer(widget.programId).listen(_onOffer, onError: (Object _) {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.failed;
          _error = friendlyError(e);
        });
      }
    }
  }

  void _onTick() {
    if (!mounted || _phase != _Phase.showing) return;
    if (!DateTime.now().isBefore(_until)) {
      _tick?.cancel();
      setState(() => _phase = _Phase.expired);
    } else {
      setState(() {});
    }
  }

  void _onOffer(({String token, bool claimed})? offer) {
    if (!mounted || offer == null || offer.token != _token || !offer.claimed) return;
    if (_phase != _Phase.showing && _phase != _Phase.expired) return;
    _tick?.cancel();
    HapticFeedback.mediumImpact();
    setState(() => _phase = _Phase.scanned);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.giveStamp),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(LoyiIcons.x),
          onPressed: () => context.canPop() ? context.pop() : context.go('/business'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: PageBody(
              maxWidth: 420,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StreamBuilder<Program?>(
                    stream: _program,
                    builder: (context, snap) =>
                        Text(snap.data?.name ?? '', style: context.text.titleLarge, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: _body(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final p = context.loyi;
    final l = context.l10n;
    switch (_phase) {
      case _Phase.loading:
        return const SizedBox(
          key: ValueKey('loading'),
          height: 320,
          child: Center(child: CircularProgressIndicator()),
        );
      case _Phase.showing:
        final seconds = (_until.difference(DateTime.now()).inMilliseconds / 1000).ceil().clamp(0, 60);
        return Column(
          key: ValueKey(_token),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Radii.lg),
                  border: Border.all(color: p.line),
                ),
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: QrImageView(data: qrStampUrl(widget.programId, _token!), padding: EdgeInsets.zero),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(l.giveStampHint, style: context.text.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LoyiIcons.timer, size: 18, color: p.inkMuted),
                const SizedBox(width: 6),
                Text(l.codeValidFor(seconds), style: context.text.labelLarge?.copyWith(color: p.inkMuted)),
              ],
            ),
          ],
        );
      case _Phase.scanned:
        return _Result(
          key: const ValueKey('scanned'),
          icon: LoyiIcons.circleCheck,
          background: p.mintSoft,
          foreground: p.mint,
          title: l.stampGiven,
          body: l.stampGivenSub,
          action: l.nextCustomer,
          onAction: _newCode,
        );
      case _Phase.expired:
        return _Result(
          key: const ValueKey('expired'),
          icon: LoyiIcons.hourglass,
          background: p.surfaceMuted,
          foreground: p.inkMuted,
          title: l.codeExpiredTitle,
          body: l.codeExpiredSub,
          action: l.newCode,
          onAction: _newCode,
        );
      case _Phase.failed:
        return _Result(
          key: const ValueKey('failed'),
          icon: LoyiIcons.circleAlert,
          background: p.accentSoft,
          foreground: p.accent,
          title: l.thatDidntWorkTitle,
          body: _error ?? l.somethingWentWrong,
          action: l.tryAgain,
          onAction: _newCode,
        );
    }
  }
}

class _Result extends StatelessWidget {
  const _Result({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 24),
      Center(
        child: IconBadge(icon: icon, background: background, foreground: foreground, size: 96),
      ),
      const SizedBox(height: 20),
      Text(title, style: context.text.headlineSmall, textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text(body, style: context.text.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: 28),
      FilledButton(onPressed: onAction, child: Text(action)),
    ],
  );
}
