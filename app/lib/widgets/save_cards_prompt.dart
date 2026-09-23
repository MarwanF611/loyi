import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
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
          IconBadge(icon: Icons.cloud_done_rounded, background: p.mintSoft, foreground: p.mint),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cardCount > 1 ? "Don't lose your $cardCount cards" : "Don't lose your stamps",
                  style: context.text.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Your cards live in this browser only. Add your email to keep them on a new phone '
                  'or when you open Loyi from your home screen.',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
