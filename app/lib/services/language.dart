import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../widgets/loyi_icons.dart';
import 'document_language/document_language.dart';

/// The languages Loyi speaks, each named in its own language. Dutch is the default.
const appLanguages = [('nl', 'Nederlands'), ('fr', 'Français'), ('en', 'English')];

/// The chosen language. Stored with shared_preferences under "locale"; on the
/// web that is localStorage["flutter.locale"], which the website's language
/// links (web/site/lang.js) also set, so the site and the app always match.
class Language extends ValueNotifier<Locale> {
  Language() : super(const Locale('nl'));

  static const _key = 'locale';

  String get code => value.languageCode;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_key);
      if (appLanguages.any((l) => l.$1 == stored)) value = Locale(stored!);
    } catch (e) {
      // Storage unavailable (private browsing): keep Dutch.
      debugPrint('Language not loaded: $e');
    }
    _apply();
  }

  Future<void> set(String code) async {
    value = Locale(code);
    _apply();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, code);
    } catch (_) {
      // Not remembered, but applied for this session.
    }
  }

  void _apply() {
    Intl.defaultLocale = code; // dates and numbers
    setDocumentLanguage(code); // <html lang>, for screen readers and translation tools
    try {
      // Password-reset and email-change emails in the same language.
      FirebaseAuth.instance.setLanguageCode(code);
    } catch (_) {
      // Firebase not initialised (tests).
    }
  }
}

final language = Language();

/// Strings for code that has no BuildContext (services, models, error messages).
/// Widgets use `context.l10n`, so they rebuild when the language changes.
L10n get l10n => lookupL10n(language.value);

extension L10nContext on BuildContext {
  L10n get l10n => L10n.of(this);
}

/// Nederlands / Français / English, each in its own language.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale>(
    valueListenable: language,
    builder: (context, locale, _) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (code, name) in appLanguages)
          ChoiceChip(
            label: Text(name),
            selected: locale.languageCode == code,
            showCheckmark: false,
            onSelected: (_) => language.set(code),
          ),
      ],
    ),
  );
}

/// A compact "NL" button that opens the language list, for screens without settings
/// (sign-in, sign-up, the client's cards).
class LanguageMenu extends StatelessWidget {
  const LanguageMenu({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale>(
    valueListenable: language,
    builder: (context, locale, _) => PopupMenuButton<String>(
      tooltip: context.l10n.language,
      initialValue: locale.languageCode,
      onSelected: language.set,
      itemBuilder: (_) => [for (final (code, name) in appLanguages) PopupMenuItem(value: code, child: Text(name))],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LoyiIcons.globe, size: 18),
            const SizedBox(width: 6),
            Text(locale.languageCode.toUpperCase(), style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    ),
  );
}
