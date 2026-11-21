import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/home_screen/home_screen.dart' as home_screen;
import '../services/language.dart';
import '../theme.dart';
import 'loyi_icons.dart';
import 'ui.dart';

/// "Zet Loyi op je beginscherm": shown to customers who saved their cards, on a phone, in the browser.
/// Only after saving: on iOS a home-screen web app doesn't share Safari's storage, so the customer signs in
/// there once and the saved account brings the cards along.
class HomeScreenPrompt extends StatefulWidget {
  const HomeScreenPrompt({super.key});

  @override
  State<HomeScreenPrompt> createState() => _HomeScreenPromptState();
}

class _HomeScreenPromptState extends State<HomeScreenPrompt> {
  static const _dismissedKey = 'homeScreenHintDismissed';

  // Hidden until the stored choice is known, so it never flashes up for someone who said "not now".
  bool _dismissed = true;

  static bool get _phone =>
      defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && _phone && !home_screen.isStandalone) _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) setState(() => _dismissed = prefs.getBool(_dismissedKey) ?? false);
    } catch (_) {
      // No storage (private mode): just don't offer it.
    }
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      (await SharedPreferences.getInstance()).setBool(_dismissedKey, true);
    } catch (_) {}
  }

  Future<void> _open() async {
    final done = await showLoyiSheet<bool>(context, builder: (_) => const _HowTo());
    if (done ?? false) await _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final anonymous = auth.user?.isAnonymous ?? true;
    if (_dismissed || anonymous) return const SizedBox.shrink();
    final p = context.loyi;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Panel(
        onTap: _open,
        child: Row(
          children: [
            IconBadge(icon: LoyiIcons.smartphone, background: p.accentSoft, foreground: p.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.homeScreenTitle, style: context.text.titleMedium),
                  const SizedBox(height: 2),
                  Text(context.l10n.homeScreenSub, style: context.text.bodySmall),
                ],
              ),
            ),
            IconButton(tooltip: context.l10n.notNow, icon: const Icon(LoyiIcons.x, size: 20), onPressed: _dismiss),
          ],
        ),
      ),
    );
  }
}

/// The steps for this phone. Pops `true` when the customer is done with it (installed or "not now").
class _HowTo extends StatefulWidget {
  const _HowTo();

  @override
  State<_HowTo> createState() => _HowToState();
}

class _HowToState extends State<_HowTo> {
  // Android Chrome can show its own install dialog; otherwise (or on iOS) the customer follows the steps.
  final bool _canInstall = home_screen.canPromptInstall;

  Future<void> _install() async {
    final installed = await home_screen.promptInstall();
    if (installed && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final steps = ios
        ? [
            (LoyiIcons.upload, l.homeScreenIosShare),
            (LoyiIcons.plus, l.homeScreenIosAdd),
            (LoyiIcons.userCheck, l.homeScreenIosOpen),
          ]
        : [(LoyiIcons.ellipsis, l.homeScreenAndroidMenu), (LoyiIcons.plus, l.homeScreenAndroidAdd)];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.homeScreenTitle, style: context.text.headlineSmall),
        const SizedBox(height: 4),
        Text(l.homeScreenSub, style: context.text.bodyMedium),
        const SizedBox(height: 20),
        if (_canInstall && !ios)
          FilledButton.icon(onPressed: _install, icon: const Icon(LoyiIcons.download), label: Text(l.homeScreenInstall))
        else
          for (final (i, (icon, text)) in steps.indexed) _Step(number: i + 1, icon: icon, text: text),
        const SizedBox(height: 8),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l.notNow)),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.icon, required this.text});

  final int number;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: p.ink,
            child: Text('$number', style: context.text.labelMedium?.copyWith(color: p.canvas)),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: p.inkMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: context.text.bodyLarge)),
        ],
      ),
    );
  }
}
