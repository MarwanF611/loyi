import 'package:flutter/material.dart';

/// The visual stamp card, shared by clients (live data) and businesses (preview).
class LoyaltyCardView extends StatelessWidget {
  const LoyaltyCardView({
    super.key,
    required this.businessName,
    required this.programName,
    required this.color,
    required this.stamps,
    required this.stampsRequired,
    this.rewardsAvailable = 0,
    this.animateLatestStamp = false,
    this.onTap,
  });

  final String businessName;
  final String programName;
  final Color color;
  final int stamps;
  final int stampsRequired;
  final int rewardsAvailable;
  final bool animateLatestStamp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dark = Color.lerp(color, Colors.black, 0.25)!;
    return Material(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, dark]),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              businessName,
                              style: text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(programName, style: text.bodyMedium?.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      if (rewardsAvailable > 0) _RewardBadge(count: rewardsAvailable),
                    ],
                  ),
                  const SizedBox(height: 20),
                  StampGrid(stamps: stamps, total: stampsRequired, color: color, animateLatest: animateLatestStamp),
                  const SizedBox(height: 12),
                  Text(
                    '$stamps / $stampsRequired stamps',
                    style: text.labelLarge?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.card_giftcard, size: 16, color: Colors.black87),
        const SizedBox(width: 6),
        Text(
          count == 1 ? '1 reward' : '$count rewards',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class StampGrid extends StatelessWidget {
  const StampGrid({
    super.key,
    required this.stamps,
    required this.total,
    required this.color,
    this.animateLatest = false,
  });

  final int stamps;
  final int total;
  final Color color;
  final bool animateLatest;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Balanced rows of at most 6 (10 → 5+5, 8 → 4+4, 15 → 5+5+5).
      const spacing = 10.0;
      final rows = (total / 6).ceil();
      final perRow = (total / rows).ceil();
      final size = ((constraints.maxWidth - spacing * (perRow - 1)) / perRow).clamp(20.0, 52.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: spacing,
        children: [
          for (var row = 0; row < rows; row++)
            Row(
              spacing: spacing,
              children: [
                for (var i = row * perRow; i < total && i < (row + 1) * perRow; i++)
                  _StampDot(size: size, filled: i < stamps, color: color, animate: animateLatest && i == stamps - 1),
              ],
            ),
        ],
      );
    },
  );
}

class _StampDot extends StatelessWidget {
  const _StampDot({required this.size, required this.filled, required this.color, required this.animate});

  final double size;
  final bool filled;
  final Color color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final empty = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 2),
      ),
    );
    if (!filled) return empty;

    final stamp = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      child: Icon(Icons.check_rounded, color: color, size: size * 0.6),
    );
    if (!animate) return stamp;

    return Stack(
      children: [
        empty,
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (context, t, child) => Transform.scale(scale: t, child: child),
          child: stamp,
        ),
      ],
    );
  }
}
