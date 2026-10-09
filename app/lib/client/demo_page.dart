import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models.dart';
import '../services/language.dart';
import '../theme.dart';
import '../widgets/confetti.dart';
import '../widgets/loyalty_card_view.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/ui.dart';

/// `/demo`: a sample card for the website's "try it on your phone". A button
/// stands in for the stamp tag. Nothing is saved and no account is made.
class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  static const _required = 6;
  static const _design = CardDesign(
    background: 0xFF263238,
    style: CardStyle.pattern,
    stampColor: 0xFFFFD699,
    stampIcon: 'coffee',
  );

  int _stamps = 2;
  int _rewards = 0;
  int _burst = 0; // a new key restarts the confetti

  void _stamp() => setState(() {
    if (++_stamps == _required) {
      _stamps = 0;
      _rewards++;
      _burst++;
    }
  });

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    final l = context.l10n;
    final full = _rewards > 0 && _stamps == 0;
    return Scaffold(
      appBar: AppBar(title: const LoyiWordmark(size: 26), centerTitle: true, automaticallyImplyLeading: false),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              PageBody(
                maxWidth: 440,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.demoTitle, style: context.text.headlineLarge),
                    const SizedBox(height: 6),
                    Text(l.demoSub, style: context.text.bodyMedium),
                    const SizedBox(height: 24),
                    LoyaltyCardView(
                      businessName: 'Koffiebar Mokka',
                      programName: 'Koffiekaart',
                      design: _design,
                      stamps: _stamps,
                      stampsRequired: _required,
                      rewardsAvailable: _rewards,
                      animateLatestStamp: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      full ? l.demoFull : l.demoStamped(_required - _stamps),
                      style: context.text.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(onPressed: _stamp, icon: const Icon(LoyiIcons.nfc), label: Text(l.demoStamp)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() {
                        _stamps = 0;
                        _rewards = 0;
                      }),
                      child: Text(l.demoAgain),
                    ),
                    const SizedBox(height: 28),
                    Panel(
                      color: p.surfaceMuted,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l.demoForShops, style: context.text.titleMedium),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => context.go('/business/login?signup=1'),
                            child: Text(l.startTrial),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_burst > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: ConfettiBurst(key: ValueKey(_burst), colors: [p.accent, p.sun, p.mint, _design.backgroundColor]),
              ),
            ),
        ],
      ),
    );
  }
}
