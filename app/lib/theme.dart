import 'package:flutter/material.dart';

const loyiCoral = Color(0xFFE8553D);

/// Swatches a business can pick for its card.
const businessColors = <Color>[
  Color(0xFFE8553D), // coral
  Color(0xFF7C4DFF), // violet
  Color(0xFF1E88E5), // blue
  Color(0xFF00897B), // teal
  Color(0xFF43A047), // green
  Color(0xFFF9A825), // mustard
  Color(0xFF6D4C41), // coffee
  Color(0xFF263238), // charcoal
];

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: loyiCoral, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(0, 52), textStyle: const TextStyle(fontSize: 16)),
    ),
    cardTheme: const CardThemeData(margin: EdgeInsets.zero),
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
