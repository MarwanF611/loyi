import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/language.dart';
import '../theme.dart';

/// Small, dependency-free charts in the Loyi style. Every chart draws in over
/// ~0.7 s, shows a tooltip on hover or tap, and has a text label for screen readers.

const _drawIn = Duration(milliseconds: 750);

/// Rounds up to a "nice" axis maximum (1, 2, 5 × 10ⁿ).
int niceMax(int value) {
  if (value <= 4) return 4;
  final mag = math.pow(10, (math.log(value) / math.ln10).floor()).toInt();
  for (final m in [1, 2, 5, 10]) {
    if (m * mag >= value) return m * mag;
  }
  return 10 * mag;
}

/// Tracks which data point the pointer is over.
class _Hover extends StatefulWidget {
  const _Hover({required this.count, required this.builder});

  final int count;
  final Widget Function(BuildContext context, int? index, double progress) builder;

  @override
  State<_Hover> createState() => _HoverState();
}

class _HoverState extends State<_Hover> {
  int? _index;

  void _at(Offset local, double width) {
    if (widget.count == 0 || width <= 0) return;
    final i = (local.dx / width * widget.count).floor().clamp(0, widget.count - 1);
    if (i != _index) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => MouseRegion(
      onHover: (e) => _at(e.localPosition, c.maxWidth),
      onExit: (_) => setState(() => _index = null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _at(d.localPosition, c.maxWidth),
        onHorizontalDragUpdate: (d) => _at(d.localPosition, c.maxWidth),
        onHorizontalDragEnd: (_) => setState(() => _index = null),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: _drawIn,
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => widget.builder(context, _index, t),
        ),
      ),
    ),
  );
}

/// Dark rounded label floating above the chart.
class _Tooltip extends StatelessWidget {
  const _Tooltip({required this.title, required this.lines});

  final String title;
  final List<(Color, String)> lines;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(12), boxShadow: p.panelShadow),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.labelSmall?.copyWith(color: p.canvas.withValues(alpha: 0.7))),
          for (final (color, text) in lines)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(text, style: context.text.labelMedium?.copyWith(color: p.canvas)),
              ],
            ),
        ],
      ),
    );
  }
}

/// Positions [tooltip] above x = [fraction] of the width, kept inside the chart.
Widget _floating(BoxConstraints c, double fraction, Widget tooltip) => Positioned(
  left: 0,
  right: 0,
  top: 0,
  child: Align(alignment: Alignment((fraction * 2 - 1).clamp(-1.0, 1.0), -1), child: tooltip),
);

/// A smooth line with a soft gradient fill, for one value per day.
class AreaChart extends StatelessWidget {
  const AreaChart({
    super.key,
    required this.values,
    required this.labels,
    required this.semanticLabel,
    this.describe,
    this.height = 220,
    this.color,
  });

  final List<int> values;

  /// Tooltip title per point (e.g. "Tue 14 Oct").
  final List<String> labels;
  final String semanticLabel;

  /// Tooltip text for a value ("12 stamps"); the bare number when null.
  final String Function(int value)? describe;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    final c = color ?? p.accent;
    final max = niceMax(values.fold(0, math.max));
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: _Hover(
            count: values.length,
            builder: (context, index, t) => LayoutBuilder(
              builder: (context, box) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 36,
                    child: CustomPaint(
                      painter: _AreaPainter(
                        values: values,
                        max: max,
                        color: c,
                        grid: p.line,
                        label: context.text.bodySmall!.copyWith(fontSize: 11),
                        progress: t,
                        hover: index,
                        surface: p.surface,
                      ),
                    ),
                  ),
                  if (index != null)
                    _floating(
                      box,
                      values.length == 1 ? 0.5 : index / (values.length - 1),
                      _Tooltip(title: labels[index], lines: [(c, describe?.call(values[index]) ?? '${values[index]}')]),
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

class _AreaPainter extends CustomPainter {
  _AreaPainter({
    required this.values,
    required this.max,
    required this.color,
    required this.grid,
    required this.label,
    required this.progress,
    required this.hover,
    required this.surface,
  });

  final List<int> values;
  final int max;
  final Color color;
  final Color grid;
  final TextStyle label;
  final double progress;
  final int? hover;
  final Color surface;

  static const _axis = 28.0;
  static const _bottom = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height - _bottom;
    final w = size.width - _axis;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = h - h * i / 2;
      canvas.drawLine(Offset(_axis, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: '${max * i ~/ 2}', style: label),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
    if (values.isEmpty) return;
    Offset pt(int i) => Offset(
      _axis + (values.length == 1 ? w / 2 : w * i / (values.length - 1)),
      h - h * (values[i] / max) * progress,
    );
    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final a = pt(i - 1);
      final b = pt(i);
      final mid = (a.dx + b.dx) / 2;
      line.cubicTo(mid, a.dy, mid, b.dy, b.dx, b.dy);
    }
    final fill = Path.from(line)
      ..lineTo(pt(values.length - 1).dx, h)
      ..lineTo(pt(0).dx, h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, h)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    if (hover case final i?) {
      final o = pt(i);
      canvas.drawLine(Offset(o.dx, 0), Offset(o.dx, h), Paint()..color = color.withValues(alpha: 0.35));
      canvas.drawCircle(o, 6, Paint()..color = surface);
      canvas.drawCircle(
        o,
        6,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_AreaPainter old) =>
      old.progress != progress || old.hover != hover || old.values != values || old.color != color;
}

/// One stacked bar per bucket, e.g. new and returning clients per week.
class StackedBarChart extends StatelessWidget {
  const StackedBarChart({
    super.key,
    required this.series,
    required this.describe,
    required this.colors,
    required this.labels,
    required this.semanticLabel,
    this.axisLabels,
    this.height = 200,
  });

  /// [series][s][i]: value of series s in bucket i.
  final List<List<int>> series;

  /// Tooltip text per series for a value ("3 new clients").
  final List<String Function(int value)> describe;
  final List<Color> colors;

  /// Tooltip title per bucket.
  final List<String> labels;

  /// Short label under each bar (null: none).
  final List<String>? axisLabels;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    final n = series.first.length;
    final totals = [for (var i = 0; i < n; i++) series.fold(0, (a, s) => a + s[i])];
    final max = niceMax(totals.fold(0, math.max));
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: _Hover(
            count: n,
            builder: (context, index, t) => LayoutBuilder(
              builder: (context, box) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 44,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < n; i++)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: n > 20 ? 1.5 : 4),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: _Bar(
                                      parts: [for (final s in series) s[i] / max * t],
                                      colors: [
                                        for (final c in colors)
                                          index == null || index == i ? c : c.withValues(alpha: 0.35),
                                      ],
                                      empty: p.surfaceMuted,
                                    ),
                                  ),
                                  if (axisLabels != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      axisLabels![i],
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      style: context.text.bodySmall?.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (index != null)
                    _floating(
                      box,
                      (index + 0.5) / n,
                      _Tooltip(
                        title: labels[index],
                        lines: [for (var s = 0; s < series.length; s++) (colors[s], describe[s](series[s][index]))],
                      ),
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

class _Bar extends StatelessWidget {
  const _Bar({required this.parts, required this.colors, required this.empty});

  /// Fractions of the full height, bottom series first.
  final List<double> parts;
  final List<Color> colors;
  final Color empty;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final total = parts.fold(0.0, (a, b) => a + b);
      return Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            decoration: BoxDecoration(color: empty, borderRadius: BorderRadius.circular(6)),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: c.maxHeight * total.clamp(0, 1),
              child: Column(
                verticalDirection: VerticalDirection.up,
                children: [
                  for (var i = 0; i < parts.length; i++)
                    if (parts[i] > 0)
                      Expanded(
                        flex: (parts[i] * 1000).round().clamp(1, 1000000),
                        child: Container(color: colors[i]),
                      ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Stamps per weekday and hour: darker is busier.
class Heatmap extends StatelessWidget {
  const Heatmap({super.key, required this.grid, required this.dayNames});

  /// [grid][weekday 0 = Monday][hour].
  final List<List<int>> grid;
  final List<String> dayNames;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    final max = grid.expand((r) => r).fold(0, math.max);
    // Only the hours the shop is actually busy (at least 8 columns).
    var first = 23;
    var last = 0;
    for (final row in grid) {
      for (var h = 0; h < 24; h++) {
        if (row[h] > 0) {
          first = math.min(first, h);
          last = math.max(last, h);
        }
      }
    }
    if (max == 0) {
      first = 8;
      last = 18;
    }
    while (last - first < 7) {
      if (first > 0) first--;
      if (last - first < 7 && last < 23) last++;
    }
    final hours = [for (var h = first; h <= last; h++) h];
    return Semantics(
      label: context.l10n.stampsPerWeekdayAndHour,
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var d = 0; d < 7; d++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(width: 36, child: Text(dayNames[d], style: context.text.bodySmall)),
                    for (final h in hours)
                      Expanded(
                        child: Tooltip(
                          message: '${dayNames[d]} ${h.toString().padLeft(2, '0')}:00 · ${grid[d][h]} stamps',
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: max == 0 ? 0 : grid[d][h] / max),
                            duration: _drawIn,
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => Container(
                              height: 22,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                color: v == 0 ? p.surfaceMuted : Color.lerp(p.accentSoft, p.accent, v),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 2),
            Row(
              children: [
                const SizedBox(width: 36),
                for (final h in hours)
                  Expanded(
                    child: Text(
                      h % 2 == 0 ? '$h' : '',
                      textAlign: TextAlign.center,
                      style: context.text.bodySmall?.copyWith(fontSize: 10.5),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A ring split into coloured parts, with the total in the middle.
class Donut extends StatelessWidget {
  const Donut({super.key, required this.values, required this.colors, required this.center, this.size = 150});

  final List<int> values;
  final List<Color> colors;
  final Widget center;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _drawIn,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => CustomPaint(
        painter: _DonutPainter(values: values, colors: colors, progress: t, empty: context.loyi.surfaceMuted),
        child: child,
      ),
      child: Center(child: center),
    ),
  );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors, required this.progress, required this.empty});

  final List<int> values;
  final List<Color> colors;
  final double progress;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = empty);
    final total = values.fold(0, (a, b) => a + b);
    if (total == 0) return;
    var start = -math.pi / 2;
    const gap = 0.04;
    for (var i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweep = math.pi * 2 * values[i] / total * progress;
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(0.001, sweep - gap),
        false,
        paint
          ..color = colors[i]
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress || old.values != values;
}

/// Horizontal progress bar with a label and value, for simple breakdowns.
class MeterRow extends StatelessWidget {
  const MeterRow({
    super.key,
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
    this.leading,
  });

  final String label;
  final String value;
  final double fraction;
  final Color color;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Expanded(child: Text(label, style: context.text.labelMedium)),
            Text(value, style: context.text.labelMedium?.copyWith(color: context.loyi.inkMuted)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction.clamp(0, 1)),
            duration: _drawIn,
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 8,
              color: color,
              backgroundColor: context.loyi.surfaceMuted,
            ),
          ),
        ),
      ],
    ),
  );
}
