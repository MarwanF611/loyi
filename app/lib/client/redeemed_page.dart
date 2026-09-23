import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/confetti.dart';
import '../widgets/loyalty_card_view.dart';

class RedeemedArgs {
  const RedeemedArgs({
    required this.cardId,
    required this.businessName,
    required this.rewardTitle,
    required this.redeemedAt,
    required this.design,
    this.logoUrl,
  });

  final String cardId;
  final String businessName;
  final String? logoUrl;
  final String rewardTitle;
  final DateTime redeemedAt;
  final CardDesign design;
}

/// Full-screen confirmation the client shows to staff. The live clock and
/// pulsing animation make an old screenshot easy to spot.
class RedeemedPage extends StatefulWidget {
  const RedeemedPage({super.key, required this.args});

  final RedeemedArgs args;

  @override
  State<RedeemedPage> createState() => _RedeemedPageState();
}

class _RedeemedPageState extends State<RedeemedPage> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 1))
    ..repeat(reverse: true);
  late final Timer _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _clock.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    final text = Theme.of(context).textTheme;
    final fg = a.design.textColor;
    final white = TextStyle(color: fg);
    return Stack(
      children: [
        Scaffold(
          backgroundColor: a.design.backgroundColor,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: a.design.style == CardStyle.solid
                  ? null
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [a.design.backgroundColor, a.design.secondaryColor],
                    ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: Tween(
                          begin: 0.9,
                          end: 1.1,
                        ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: a.design.stampFill,
                          child: Icon(Icons.check_rounded, size: 72, color: a.design.stampIconColor),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text('Reward redeemed', style: text.titleMedium?.merge(white)),
                      const SizedBox(height: 8),
                      Text(
                        a.rewardTitle,
                        style: text.displaySmall?.merge(white).copyWith(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BusinessLogo(url: a.logoUrl, name: a.businessName, size: 32),
                          const SizedBox(width: 10),
                          Flexible(child: Text(a.businessName, style: text.titleLarge?.merge(white))),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        DateFormat.Hms().format(_now),
                        style: text.displayMedium
                            ?.merge(white)
                            .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                      Text(
                        'Redeemed at ${DateFormat.Hm().format(a.redeemedAt)} · show this screen to staff',
                        style: text.bodyMedium?.copyWith(color: fg.withValues(alpha: 0.75)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: fg,
                          foregroundColor: a.design.backgroundColor,
                          minimumSize: const Size(180, 56),
                        ),
                        onPressed: () => context.go('/c/${a.cardId}'),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ConfettiBurst(
            colors: [LoyiPalette.light.sun, a.design.stampFill, Colors.white, LoyiPalette.light.accent],
          ),
        ),
      ],
    );
  }
}
