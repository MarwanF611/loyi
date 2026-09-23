import 'package:flutter/material.dart';

/// Loyi house style: "Coral & Ink" on warm white.
///
/// Light mode is the primary look: a warm off-white canvas with white panels,
/// deep ink text, coral for actions, sunny yellow for rewards and mint for
/// success. Dark mode uses its own palette rather than an inverted one.
class LoyiPalette extends ThemeExtension<LoyiPalette> {
  const LoyiPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.accent,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.sun,
    required this.sunSoft,
    required this.mint,
    required this.mintSoft,
    required this.shadow,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color ink;
  final Color inkMuted;
  final Color line;
  final Color accent;
  final Color accentSoft;
  final Color onAccentSoft;
  final Color sun;
  final Color sunSoft;
  final Color mint;
  final Color mintSoft;
  final Color shadow;

  static const light = LoyiPalette(
    canvas: Color(0xFFF7F5F2),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1EEEA),
    ink: Color(0xFF17161C),
    inkMuted: Color(0xFF6E6A73),
    line: Color(0xFFEAE6E1),
    accent: Color(0xFFFF5A3C),
    accentSoft: Color(0xFFFFE9E3),
    onAccentSoft: Color(0xFFB8321B),
    sun: Color(0xFFFFC83D),
    sunSoft: Color(0xFFFFF4D6),
    mint: Color(0xFF1FB57A),
    mintSoft: Color(0xFFDDF5EA),
    shadow: Color(0x1417161C),
  );

  static const dark = LoyiPalette(
    canvas: Color(0xFF111015),
    surface: Color(0xFF1B1A21),
    surfaceMuted: Color(0xFF25232C),
    ink: Color(0xFFF5F3EF),
    inkMuted: Color(0xFFA5A1AB),
    line: Color(0xFF2E2C36),
    accent: Color(0xFFFF6B4F),
    accentSoft: Color(0xFF3A1E19),
    onAccentSoft: Color(0xFFFFB4A3),
    sun: Color(0xFFFFCF57),
    sunSoft: Color(0xFF3A3019),
    mint: Color(0xFF3CCB91),
    mintSoft: Color(0xFF16332A),
    shadow: Color(0x66000000),
  );

  /// Soft, layered shadow for white panels (depth without heavy borders).
  List<BoxShadow> get panelShadow => [
    BoxShadow(color: shadow, blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: shadow, blurRadius: 2, offset: const Offset(0, 1)),
  ];

  @override
  LoyiPalette copyWith() => this;

  @override
  LoyiPalette lerp(LoyiPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return LoyiPalette(
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      line: l(line, other.line),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      onAccentSoft: l(onAccentSoft, other.onAccentSoft),
      sun: l(sun, other.sun),
      sunSoft: l(sunSoft, other.sunSoft),
      mint: l(mint, other.mint),
      mintSoft: l(mintSoft, other.mintSoft),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension LoyiThemeX on BuildContext {
  LoyiPalette get loyi => Theme.of(this).extension<LoyiPalette>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Radii used across the app.
abstract final class Radii {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 28.0;
}

const _font = 'PlusJakartaSans';

TextTheme _textTheme(Color ink, Color muted) {
  TextStyle s(double size, FontWeight w, {double spacing = 0, double height = 1.3, Color? color}) => TextStyle(
    fontFamily: _font,
    fontSize: size,
    fontWeight: w,
    letterSpacing: spacing,
    height: height,
    color: color ?? ink,
  );
  return TextTheme(
    displayLarge: s(56, FontWeight.w800, spacing: -2, height: 1.05),
    displayMedium: s(44, FontWeight.w800, spacing: -1.5, height: 1.08),
    displaySmall: s(34, FontWeight.w800, spacing: -1, height: 1.1),
    headlineLarge: s(30, FontWeight.w800, spacing: -0.8, height: 1.15),
    headlineMedium: s(26, FontWeight.w800, spacing: -0.6, height: 1.18),
    headlineSmall: s(22, FontWeight.w700, spacing: -0.4, height: 1.2),
    titleLarge: s(19, FontWeight.w700, spacing: -0.3),
    titleMedium: s(16, FontWeight.w700, spacing: -0.1),
    titleSmall: s(14, FontWeight.w600),
    bodyLarge: s(16, FontWeight.w500, height: 1.45),
    bodyMedium: s(14.5, FontWeight.w500, height: 1.45, color: muted),
    bodySmall: s(12.5, FontWeight.w500, height: 1.4, color: muted),
    labelLarge: s(15, FontWeight.w700, spacing: -0.1),
    labelMedium: s(13, FontWeight.w600),
    labelSmall: s(11.5, FontWeight.w700, spacing: 0.6),
  );
}

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.light ? LoyiPalette.light : LoyiPalette.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.accent,
    onPrimary: Colors.white,
    primaryContainer: p.accentSoft,
    onPrimaryContainer: p.onAccentSoft,
    secondary: p.ink,
    onSecondary: p.canvas,
    secondaryContainer: p.surfaceMuted,
    onSecondaryContainer: p.ink,
    tertiary: p.mint,
    onTertiary: Colors.white,
    tertiaryContainer: p.mintSoft,
    onTertiaryContainer: p.ink,
    error: const Color(0xFFE5484D),
    onError: Colors.white,
    surface: p.surface,
    onSurface: p.ink,
    onSurfaceVariant: p.inkMuted,
    surfaceContainerLowest: p.surface,
    surfaceContainerLow: p.canvas,
    surfaceContainer: p.surfaceMuted,
    surfaceContainerHigh: p.surfaceMuted,
    surfaceContainerHighest: p.line,
    outline: p.inkMuted.withValues(alpha: 0.5),
    outlineVariant: p.line,
    shadow: p.shadow,
    inverseSurface: p.ink,
    onInverseSurface: p.canvas,
    surfaceTint: Colors.transparent, // no Material tint; depth comes from shadows
  );
  final text = _textTheme(p.ink, p.inkMuted);
  const pill = StadiumBorder();
  const buttonSize = Size(64, 56);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: _font,
    textTheme: text,
    scaffoldBackgroundColor: p.canvas,
    extensions: [p],
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: p.canvas,
      foregroundColor: p.ink,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonSize,
        shape: pill,
        textStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        disabledBackgroundColor: p.line,
        disabledForegroundColor: p.inkMuted,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        shape: pill,
        foregroundColor: p.ink,
        side: BorderSide(color: p.line, width: 1.5),
        textStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 22),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.ink,
        shape: pill,
        textStyle: text.labelLarge,
        minimumSize: const Size(48, 48),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: p.ink, minimumSize: const Size(48, 48)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      labelStyle: text.bodyLarge?.copyWith(color: p.inkMuted),
      floatingLabelStyle: text.labelMedium?.copyWith(color: p.accent),
      hintStyle: text.bodyLarge?.copyWith(color: p.inkMuted.withValues(alpha: 0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: p.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: p.line, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: p.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: p.line),
      ),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      titleTextStyle: text.titleSmall?.copyWith(color: p.ink),
      subtitleTextStyle: text.bodySmall,
      iconColor: p.ink,
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: p.surfaceMuted,
      selectedColor: p.ink,
      labelStyle: text.labelMedium?.copyWith(color: p.ink),
      secondaryLabelStyle: text.labelMedium?.copyWith(color: p.canvas),
      checkmarkColor: p.canvas,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        side: WidgetStatePropertyAll(BorderSide(color: p.line, width: 1.5)),
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        textStyle: WidgetStatePropertyAll(text.labelMedium),
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.ink : p.surface),
        foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.canvas : p.ink),
        iconColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.canvas : p.ink),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.mint : p.line),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.accent : p.inkMuted),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.accent,
      linearTrackColor: p.surfaceMuted,
      circularTrackColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.ink,
      contentTextStyle: text.labelMedium?.copyWith(color: p.canvas),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl)),
      titleTextStyle: text.headlineSmall,
      contentTextStyle: text.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: p.line,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl))),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(8)),
      textStyle: text.labelMedium?.copyWith(color: p.canvas),
    ),
  );
}

/// Centers content and caps its width so pages read well on tablets and web.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = 560});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
