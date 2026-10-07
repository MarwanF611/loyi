import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/language.dart';
import '../theme.dart';
import 'loyi_icons.dart';
import 'ui.dart';

/// Nudges anonymous clients to attach an email so their cards aren't tied to one browser.
class SaveCardsPrompt extends StatelessWidget {
  const SaveCardsPrompt({super.key, this.cardCount = 1});

  final int cardCount;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return Panel(
      onTap: () => context.push('/account'),
      child: Row(
        children: [
          IconBadge(icon: LoyiIcons.cloudCheck, background: p.mintSoft, foreground: p.mint),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.dontLoseCards(cardCount), style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(context.l10n.cardsLiveInBrowser, style: context.text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(LoyiIcons.chevronRight),
        ],
      ),
    );
  }
}
