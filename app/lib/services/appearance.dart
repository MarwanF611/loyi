import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'language.dart';

/// Light, dark or follow the device. Light is the default.
///
/// Stored with shared_preferences under "themeMode". On the web that is
/// localStorage["flutter.themeMode"], the same key the website's footer switch
/// (web/site/theme.js) uses, so the site and the app always match.
class Appearance extends ValueNotifier<ThemeMode> {
  Appearance() : super(ThemeMode.light);

  static const _key = 'themeMode';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      value = _parse(prefs.getString(_key));
    } catch (e) {
      // Storage unavailable (private browsing): keep light.
      debugPrint('Appearance not loaded: $e');
    }
  }

  Future<void> set(ThemeMode mode) async {
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // Not remembered, but applied for this session.
    }
  }

  static ThemeMode _parse(String? name) => switch (name) {
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => ThemeMode.light,
  };
}

final appearance = Appearance();

/// Light / Dark / Device switch, for the settings and account pages.
class AppearancePicker extends StatelessWidget {
  const AppearancePicker({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: appearance,
    builder: (context, mode, _) => SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(value: ThemeMode.light, label: Text(context.l10n.light)),
        ButtonSegment(value: ThemeMode.dark, label: Text(context.l10n.dark)),
        ButtonSegment(value: ThemeMode.system, label: Text(context.l10n.device)),
      ],
      selected: {mode},
      onSelectionChanged: (s) => appearance.set(s.first),
    ),
  );
}
