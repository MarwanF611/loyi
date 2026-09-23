import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RedeemedArgs {
  const RedeemedArgs({
    required this.cardId,
    required this.businessName,
    required this.rewardTitle,
    required this.redeemedAt,
    required this.color,
  });

  final String cardId;
  final String businessName;
  final String rewardTitle;
  final DateTime redeemedAt;
  final Color color;
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
    const white = TextStyle(color: Colors.white);
    return Scaffold(
      backgroundColor: a.color,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: Tween(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                  child: const CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.check_rounded, size: 72, color: Colors.black87),
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
                Text(a.businessName, style: text.titleLarge?.merge(white)),
                const SizedBox(height: 32),
                Text(
                  DateFormat.Hms().format(_now),
                  style: text.displayMedium?.merge(white).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                Text(
                  'Redeemed at ${DateFormat.Hm().format(a.redeemedAt)} · show this screen to staff',
                  style: text.bodyMedium?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    minimumSize: const Size(160, 48),
                  ),
                  onPressed: () => context.go('/c/${a.cardId}'),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
