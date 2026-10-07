import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loyi/l10n/app_localizations.dart';
import 'package:loyi/services/language.dart';

Map<String, dynamic> _arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;

Set<String> _placeholders(String text) => {
  // {name} and the count variable of {count, plural, ...}; not the words inside plural branches.
  for (final m in RegExp(r'\{(\w+)(?=[},])').allMatches(text)) m.group(1)!,
}..removeWhere((p) => RegExp(r'^(one|other|few|many|zero|=\d+)$').hasMatch(p));

void main() {
  final en = _arb('en');
  final keys = {
    for (final k in en.keys)
      if (!k.startsWith('@')) k,
  };

  test('Dutch is the default language', () {
    expect(Language().value.languageCode, 'nl');
    expect(appLanguages.first.$1, 'nl');
    expect(L10n.supportedLocales.map((l) => l.languageCode), containsAll(['nl', 'fr', 'en']));
  });

  for (final lang in ['nl', 'fr']) {
    test('$lang has every string, with the same placeholders', () {
      final arb = _arb(lang);
      final theirs = {
        for (final k in arb.keys)
          if (!k.startsWith('@')) k,
      };
      expect(keys.difference(theirs), isEmpty, reason: 'missing in $lang');
      expect(theirs.difference(keys), isEmpty, reason: 'only in $lang');
      for (final k in keys) {
        expect(_placeholders(arb[k] as String), _placeholders(en[k] as String), reason: '$lang: $k');
        expect((arb[k] as String).trim(), isNotEmpty, reason: '$lang: $k');
      }
    });
  }

  test('translations are filled in and Dutch reads differently from English', () {
    final nl = lookupL10n(const Locale('nl'));
    final fr = lookupL10n(const Locale('fr'));
    expect(nl.tabClients, 'Klanten');
    expect(fr.tabSettings, 'Réglages');
    expect(nl.stampsCount(1), '1 stempel');
    expect(nl.stampsCount(3), '3 stempels');
    expect(fr.rewardsReady(2), '2 récompenses prêtes');
  });
}
