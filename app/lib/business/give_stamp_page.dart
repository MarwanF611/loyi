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
import '../services/qr_stamp.dart';
import '../services/repo.dart';
import '../services/screen_awake/screen_awake.dart';
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

enum _Phase { loading, showing, failed }

/// The counter screen: a QR code that is always there and changes every 15 seconds. The customer scans it with the
/// phone's camera (`/q/<programId>/<period>-<n>-<signature>`). This device makes the codes itself from the card's
/// secret (billing.qrSession), so an idle screen costs no database traffic; the billing server checks each scan and
/// turns it into a one-time stamp ticket. After a scan the next code (n + 1) appears at once.
class GiveStampPage extends StatefulWidget {
  const GiveStampPage({super.key, required this.programId});

  final String programId;

  @override
  State<GiveStampPage> createState() => _GiveStampPageState();
}

class _GiveStampPageState extends State<GiveStampPage> {
  late final Stream<Program?> _program = repo.program(widget.programId);
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(onResume: () => keepScreenAwake(true));
  _Phase _phase = _Phase.loading;
  String? _error;

  String? _secret;
  Duration _period = const Duration(seconds: 15);
  Duration _clockOffset = Duration.zero;
  int _window = -1;
  int _n = 0;
  String _token = '';

  bool _scanned = false;
  String? _lastClaim;
  bool _firstClaim = true;
  Timer? _tick;
  Timer? _scannedTimer;
  StreamSubscription<String?>? _claims;

  @override
  void initState() {
    super.initState();
    _lifecycle; // starts listening
    keepScreenAwake(true);
    _start();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _scannedTimer?.cancel();
    _claims?.cancel();
    _lifecycle.dispose();
    keepScreenAwake(false);
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _phase = _Phase.loading;
      _error = null;
    });
    try {
      final session = await billing.qrSession(widget.programId);
      if (!mounted) return;
      _secret = session.secret;
      _period = session.period;
      _clockOffset = session.clockOffset;
      _window = -1;
      // The offer exists now (the rules only let the shop read an existing one of its own).
      _claims ??= repo.lastQrClaim(widget.programId).listen(_onClaim, onError: (Object _) {});
      _tick?.cancel();
      _tick = Timer.periodic(const Duration(milliseconds: 250), (_) => _refresh());
      setState(() => _phase = _Phase.showing);
      _refresh();
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.failed;
          _error = friendlyError(e);
        });
      }
    }
  }

  DateTime get _serverNow => DateTime.now().add(_clockOffset);

  String _sign(int window, int n) => qrStampToken(_secret!, widget.programId, window, n);

  void _refresh() {
    if (!mounted || _secret == null) return;
    final window = _serverNow.millisecondsSinceEpoch ~/ _period.inMilliseconds;
    setState(() {
      if (window != _window) {
        _window = window;
        _n = 0;
        _token = _sign(window, 0);
      }
    });
  }

  void _onClaim(String? claim) {
    // The first snapshot is whatever was scanned before this screen opened.
    if (_firstClaim) {
      _firstClaim = false;
      _lastClaim = claim;
      return;
    }
    if (!mounted || claim == null || claim == _lastClaim) return;
    _lastClaim = claim;
    HapticFeedback.mediumImpact();
    setState(() {
      // The code on screen was used: show the next one straight away.
      if (claim == '$_window-$_n') {
        _n += 1;
        _token = _sign(_window, _n);
      }
      _scanned = true;
    });
    _scannedTimer?.cancel();
    _scannedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _scanned = false);
    });
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
                  _body(context),
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
        return const SizedBox(height: 320, child: Center(child: CircularProgressIndicator()));
      case _Phase.failed:
        return _Result(
          icon: LoyiIcons.circleAlert,
          background: p.accentSoft,
          foreground: p.accent,
          title: l.thatDidntWorkTitle,
          body: _error ?? l.somethingWentWrong,
          action: l.tryAgain,
          onAction: _start,
        );
      case _Phase.showing:
        final periodMs = _period.inMilliseconds;
        final left = 1 - (_serverNow.millisecondsSinceEpoch % periodMs) / periodMs;
        return Column(
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      QrImageView(data: qrStampUrl(widget.programId, _token), padding: EdgeInsets.zero),
                      // A short "stamp given" over the code after a scan; the next code is already underneath.
                      AnimatedOpacity(
                        opacity: _scanned ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: IgnorePointer(
                          child: ColoredBox(
                            color: Colors.white.withValues(alpha: 0.94),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconBadge(
                                  icon: LoyiIcons.circleCheck,
                                  background: p.mintSoft,
                                  foreground: p.mint,
                                  size: 88,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  l.stampGiven,
                                  style: context.text.titleLarge?.copyWith(color: LoyiPalette.light.ink),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(l.giveStampHint, style: context.text.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    value: left,
                    strokeWidth: 2.5,
                    color: p.inkMuted,
                    backgroundColor: p.line,
                  ),
                ),
                const SizedBox(width: 8),
                Text(l.giveStampChanges, style: context.text.labelLarge?.copyWith(color: p.inkMuted)),
              ],
            ),
          ],
        );
    }
  }
}

class _Result extends StatelessWidget {
  const _Result({
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
