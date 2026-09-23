import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'stamp_icons.dart';
import 'ui.dart';

/// The visual stamp card, shared by clients (live data) and businesses (preview).
class LoyaltyCardView extends StatelessWidget {
  const LoyaltyCardView({
    super.key,
    required this.businessName,
    required this.programName,
    required this.design,
    required this.stamps,
    required this.stampsRequired,
    this.logoUrl,
    this.rewardsAvailable = 0,
    this.animateLatestStamp = false,
    this.onTap,
  });

  final String businessName;
  final String programName;
  final CardDesign design;
  final String? logoUrl;
  final int stamps;
  final int stampsRequired;
  final int rewardsAvailable;
  final bool animateLatestStamp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fg = design.textColor;
    final remaining = stampsRequired - stamps;
    const radius = BorderRadius.all(Radius.circular(28));
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        // Coloured glow instead of a grey shadow.
        boxShadow: [
          BoxShadow(color: design.backgroundColor.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 14)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 3, offset: const Offset(0, 1)),
        ],
      ),
      child: Material(
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        color: design.backgroundColor,
        child: Ink(
          decoration: BoxDecoration(
            gradient: design.style == CardStyle.solid
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [design.backgroundColor, design.secondaryColor],
                  ),
          ),
          child: CustomPaint(
            painter: _Sheen(pattern: design.style == CardStyle.pattern ? fg.withValues(alpha: 0.08) : null),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        BusinessLogo(url: logoUrl, name: businessName, size: 46),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                businessName,
                                style: text.titleLarge?.copyWith(color: fg, fontWeight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                programName,
                                style: text.labelMedium?.copyWith(color: fg.withValues(alpha: 0.72)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (rewardsAvailable > 0) _RewardBadge(count: rewardsAvailable),
                      ],
                    ),
                    const SizedBox(height: 22),
                    StampGrid(stamps: stamps, total: stampsRequired, design: design, animateLatest: animateLatestStamp),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          '$stamps',
                          style: text.titleLarge?.copyWith(color: fg, fontWeight: FontWeight.w800, height: 1),
                        ),
                        Text(
                          ' / $stampsRequired stamps',
                          style: text.labelMedium?.copyWith(color: fg.withValues(alpha: 0.72)),
                        ),
                        const Spacer(),
                        if (remaining > 0 && stamps > 0)
                          Text(
                            '$remaining to go',
                            style: text.labelMedium?.copyWith(color: fg.withValues(alpha: 0.72)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      label:
          '$businessName, $programName: $stamps of $stampsRequired stamps'
          '${rewardsAvailable > 0 ? ', $rewardsAvailable rewards ready' : ''}',
      button: onTap != null,
      child: onTap == null ? card : Pressable(onTap: onTap, child: card),
    );
  }
}

/// The business logo in a rounded white tile, or its initial when there is no logo.
class BusinessLogo extends StatelessWidget {
  const BusinessLogo({super.key, required this.url, required this.name, this.size = 40});

  final String? url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = Center(
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(fontSize: size * 0.45, fontWeight: FontWeight.w700, color: Colors.black87),
      ),
    );
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(url == null ? 0 : size * 0.08),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size * 0.25)),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? initial
          : Image.network(
              url!,
              fit: BoxFit.contain,
              // Falls back to an <img> element if the bucket has no CORS config.
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (_, _, _) => initial,
            ),
    );
  }
}

/// A soft light sheen in the top-left corner, plus an optional dot pattern.
class _Sheen extends CustomPainter {
  _Sheen({this.pattern});

  final Color? pattern;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-1.1, -1.3),
          radius: 1.4,
          colors: [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0)],
        ).createShader(rect),
    );
    if (pattern == null) return;
    final paint = Paint()..color = pattern!;
    const gap = 22.0;
    for (var y = 0.0, row = 0; y < size.height + gap; y += gap, row++) {
      for (var x = row.isEven ? 0.0 : gap / 2; x < size.width + gap; x += gap) {
        canvas.drawCircle(Offset(x, y), 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Sheen old) => old.pattern != pattern;
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: LoyiPalette.light.sun,
      borderRadius: BorderRadius.circular(99),
      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2))],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.redeem_rounded, size: 16, color: Color(0xFF17161C)),
        const SizedBox(width: 6),
        Text(
          count == 1 ? '1 reward' : '$count rewards',
          style: const TextStyle(color: Color(0xFF17161C), fontWeight: FontWeight.w800, fontSize: 13),
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
    required this.design,
    this.animateLatest = false,
  });

  final int stamps;
  final int total;
  final CardDesign design;
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
                  _StampDot(size: size, filled: i < stamps, design: design, animate: animateLatest && i == stamps - 1),
              ],
            ),
        ],
      );
    },
  );
}

class _StampDot extends StatelessWidget {
  const _StampDot({required this.size, required this.filled, required this.design, required this.animate});

  final double size;
  final bool filled;
  final CardDesign design;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final empty = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: design.textColor.withValues(alpha: 0.45), width: 2),
      ),
    );
    if (!filled) return empty;

    final stamp = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: design.stampFill),
      child: Icon(stampIconData(design.stampIcon), color: design.stampIconColor, size: size * 0.58),
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
