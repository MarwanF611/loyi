import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme.dart';

/// The Loyi wordmark: "loyi" in ink with a coral full stop.
class LoyiWordmark extends StatelessWidget {
  const LoyiWordmark({super.key, this.size = 28, this.color});

  final double size;

  /// Overrides the ink colour (e.g. white on a coral background).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    final style = TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontWeight: FontWeight.w800,
      fontSize: size,
      letterSpacing: -size * 0.05,
      height: 1,
      color: color ?? p.ink,
    );
    return Semantics(
      label: 'Loyi',
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            text: 'loyi',
            style: style,
            children: [
              TextSpan(
                text: '.',
                style: style.copyWith(color: color == null ? p.accent : p.sun),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scales its child down slightly while pressed: a small cue that it's tappable.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.borderRadius = Radii.lg});

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && v != _down) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? 0.975 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// White rounded surface with a soft layered shadow: the basic building block.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.color,
    this.radius = Radii.lg,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    final content = Material(
      color: color ?? p.surface,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow && color == null ? p.panelShadow : null,
        border: color == null ? Border.all(color: p.line.withValues(alpha: 0.7)) : null,
      ),
      child: content,
    );
    return onTap == null ? decorated : Pressable(onTap: onTap, borderRadius: radius, child: decorated);
  }
}

/// Rounded square with an icon on a soft tinted background.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.background, required this.foreground, this.size = 44});

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.32)),
    child: Icon(icon, color: foreground, size: size * 0.5),
  );
}

/// Section title with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleLarge),
              if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: context.text.bodySmall)],
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

/// Small rounded label, e.g. "Paused" or "1 reward ready".
class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, this.icon, this.background, this.foreground});

  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    final fg = foreground ?? p.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: background ?? p.surfaceMuted, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 6)],
          Text(label, style: context.text.labelMedium?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// Shimmering placeholder shown while data loads (instead of a spinner).
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, required this.height, this.radius = Radii.md});

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + 3 * _c.value, 0),
            end: Alignment(-0.5 + 3 * _c.value, 0),
            colors: [p.surfaceMuted, p.line, p.surfaceMuted],
          ),
        ),
      ),
    );
  }
}

/// App bar that frosts (blurs) the content scrolling underneath it.
/// Use with `Scaffold(extendBodyBehindAppBar: true)` and [frostedTopPadding].
class FrostedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FrostedAppBar({super.key, this.title, this.leading, this.actions, this.leadingWidth});

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final double? leadingWidth;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    title: title,
    leading: leading,
    leadingWidth: leadingWidth,
    actions: actions,
    backgroundColor: Colors.transparent,
    automaticallyImplyLeading: false,
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: ColoredBox(color: context.loyi.canvas.withValues(alpha: 0.78)),
      ),
    ),
  );
}

/// Top padding for lists under a [FrostedAppBar].
double frostedTopPadding(BuildContext context) => MediaQuery.paddingOf(context).top + kToolbarHeight;

/// Sticky bottom bar for the page's primary action, in the thumb zone.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: p.canvas.withValues(alpha: 0.85),
            border: Border(top: BorderSide(color: p.line)),
          ),
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
          child: PageBody(child: child),
        ),
      ),
    );
  }
}

/// Opens a Loyi-styled bottom sheet.
Future<T?> showLoyiSheet<T>(BuildContext context, {required WidgetBuilder builder}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 560),
  builder: (context) => Padding(
    padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
    child: builder(context),
  ),
);

/// Circular white icon button for page headers.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: p.surface,
        side: BorderSide(color: p.line),
        fixedSize: const Size(48, 48),
      ),
      icon: Icon(icon, size: 22),
    );
  }
}
