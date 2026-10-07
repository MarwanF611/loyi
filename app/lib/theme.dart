import 'package:flutter/material.dart';

/// Loyi house style, shared with the website (app/web/site/site.css).
///
/// Light mode is the default: a white page, warm grey panels holding white
/// cards with a soft drop shadow, deep ink text and coral for actions. Sunny
/// yellow marks rewards and mint marks success. Dark mode has its own palette.
class LoyiPalette extends ThemeExtension<LoyiPalette> {
  const LoyiPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.panelDeep,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.accent,
    required this.accentDeep,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.sun,
    required this.sunSoft,
    required this.onSunSoft,
    required this.mint,
    required this.mintSoft,
    required this.shadow,
  });

  /// The page background (site: --page).
  final Color canvas;

  /// Cards and inputs (site: --card).
  final Color surface;

  /// Panels that group cards, chips and tracks (site: --panel).
  final Color surfaceMuted;

  /// Hover and pressed panels (site: --panel-deep).
  final Color panelDeep;
  final Color ink;
  final Color inkMuted;
  final Color line;
  final Color accent;
  final Color accentDeep;
  final Color accentSoft;
  final Color onAccentSoft;
  final Color sun;
  final Color sunSoft;

  /// Text and icons on [sunSoft].
  final Color onSunSoft;
  final Color mint;
  final Color mintSoft;
  final Color shadow;

  static const light = LoyiPalette(
    canvas: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF7F5F2),
    panelDeep: Color(0xFFEFEBE5),
    ink: Color(0xFF17161C),
    inkMuted: Color(0xFF6E6A73),
    line: Color(0xFFE7E3DE),
    accent: Color(0xFFFF5A3C),
    accentDeep: Color(0xFFE0442A),
    accentSoft: Color(0xFFFFE9E3),
    onAccentSoft: Color(0xFFB8321B),
    sun: Color(0xFFFFC83D),
    sunSoft: Color(0xFFFFF4D6),
    onSunSoft: Color(0xFF8A6500),
    mint: Color(0xFF1FB57A),
    mintSoft: Color(0xFFDDF5EA),
    shadow: Color(0xFF17161C),
  );

  static const dark = LoyiPalette(
    canvas: Color(0xFF111015),
    surface: Color(0xFF24232A),
    surfaceMuted: Color(0xFF1A191F),
    panelDeep: Color(0xFF222128),
    ink: Color(0xFFF5F3EF),
    inkMuted: Color(0xFFA7A3AB),
    line: Color(0xFF2E2C34),
    accent: Color(0xFFFF6B4F),
    accentDeep: Color(0xFFF0523A),
    accentSoft: Color(0xFF3A1F19),
    onAccentSoft: Color(0xFFFFB4A3),
    sun: Color(0xFFFFCF57),
    sunSoft: Color(0xFF3A3220),
    onSunSoft: Color(0xFFFFD98A),
    mint: Color(0xFF3CCB91),
    mintSoft: Color(0xFF16332A),
    shadow: Color(0xFF000000),
  );

  bool get isDark => canvas.computeLuminance() < 0.2;

  /// The website's card shadow: a hairline plus a long, soft drop.
  List<BoxShadow> get panelShadow => [
    BoxShadow(
      color: shadow.withValues(alpha: isDark ? 0.3 : 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: shadow.withValues(alpha: isDark ? 0.7 : 0.22),
      blurRadius: 40,
      spreadRadius: -18,
      offset: const Offset(0, 18),
    ),
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
      panelDeep: l(panelDeep, other.panelDeep),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      line: l(line, other.line),
      accent: l(accent, other.accent),
      accentDeep: l(accentDeep, other.accentDeep),
      accentSoft: l(accentSoft, other.accentSoft),
      onAccentSoft: l(onAccentSoft, other.onAccentSoft),
      sun: l(sun, other.sun),
      sunSoft: l(sunSoft, other.sunSoft),
      onSunSoft: l(onSunSoft, other.onSunSoft),
      mint: l(mint, other.mint),
      mintSoft: l(mintSoft, other.mintSoft),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension LoyiThemeX on BuildContext {
  LoyiPalette get loyi => Theme.of(this).extension<LoyiPalette>()!;
  TextTheme get text => Theme.of(this).textTheme;

  /// Small mono caps label above headings and numbers, like the website's `.eyebrow`.
  TextStyle get eyebrow => TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1,
    height: 1.4,
    color: loyi.inkMuted,
  );
}

/// Radii used across the app.
abstract final class Radii {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
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
  // Headings follow the website: semibold with tight tracking (-0.035em).
  TextStyle h(double size, {FontWeight w = FontWeight.w600, double height = 1.08}) =>
      s(size, w, spacing: -size * 0.035, height: height);
  return TextTheme(
    displayLarge: h(56, height: 1.02),
    displayMedium: h(44, height: 1.04),
    displaySmall: h(36, height: 1.06),
    headlineLarge: h(30, height: 1.12),
    headlineMedium: h(26, height: 1.15),
    headlineSmall: h(22, height: 1.2),
    titleLarge: s(19, FontWeight.w700, spacing: -0.4),
    titleMedium: s(16, FontWeight.w700, spacing: -0.2),
    titleSmall: s(14.5, FontWeight.w600),
    bodyLarge: s(16, FontWeight.w500, height: 1.5),
    bodyMedium: s(14.5, FontWeight.w500, height: 1.5, color: muted),
    bodySmall: s(12.5, FontWeight.w500, height: 1.4, color: muted),
    labelLarge: s(15.5, FontWeight.w700, spacing: -0.1),
    labelMedium: s(13, FontWeight.w600),
    labelSmall: s(11.5, FontWeight.w700, spacing: 0.4),
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
  const buttonSize = Size(64, 52);

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
      // The website's soft button: a warm pill without a border.
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        shape: pill,
        foregroundColor: p.ink,
        backgroundColor: p.surfaceMuted,
        side: BorderSide.none,
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
      // Ink text, inverted on the dark selected pill.
      labelStyle: text.labelMedium?.copyWith(
        color: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? p.canvas : p.ink),
      ),
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
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.canvas,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.accentSoft,
      height: 68,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => text.labelSmall?.copyWith(
          letterSpacing: 0,
          fontSize: 12,
          color: s.contains(WidgetState.selected) ? p.ink : p.inkMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(size: 22, color: s.contains(WidgetState.selected) ? p.accent : p.inkMuted),
      ),
    ),
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
