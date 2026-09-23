import 'dart:math';

import 'package:flutter/material.dart';

/// One-shot confetti burst, drawn over its parent (e.g. when a card fills up).
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, required this.colors, this.pieces = 70});

  final List<Color> colors;
  final int pieces;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    ..forward();
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    _pieces = [
      for (var i = 0; i < widget.pieces; i++)
        _Piece(
          angle: -pi / 2 + (rnd.nextDouble() - 0.5) * pi * 0.9,
          speed: 0.55 + rnd.nextDouble() * 0.6,
          spin: (rnd.nextDouble() - 0.5) * 14,
          size: 6 + rnd.nextDouble() * 6,
          color: widget.colors[i % widget.colors.length],
          round: rnd.nextBool(),
        ),
    ];
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect "reduce motion".
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_pieces, _c.value)),
      ),
    );
  }
}

class _Piece {
  _Piece({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
    required this.round,
  });

  final double angle;
  final double speed;
  final double spin;
  final double size;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final origin = Offset(size.width / 2, size.height * 0.35);
    final reach = size.shortestSide * 0.9;
    final paint = Paint();
    for (final p in pieces) {
      final d = reach * p.speed * Curves.easeOut.transform(t);
      final gravity = 900 * t * t * 0.5;
      final pos = origin + Offset(cos(p.angle) * d, sin(p.angle) * d + gravity);
      paint.color = p.color.withValues(alpha: (1 - t).clamp(0, 1));
      canvas
        ..save()
        ..translate(pos.dx, pos.dy)
        ..rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
