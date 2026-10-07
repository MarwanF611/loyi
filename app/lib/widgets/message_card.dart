import 'package:flutter/material.dart';

import '../models.dart';
import '../services/language.dart';
import '../theme.dart';
import 'loyalty_card_view.dart';
import 'loyi_icons.dart';

/// A shop's follow-up message as clients see it on their card.
class MessageCard extends StatelessWidget {
  const MessageCard({super.key, required this.business, required this.title, required this.body, this.onDismiss});

  final Business business;
  final String title;
  final String body;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: p.panelShadow,
        border: Border.all(color: p.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BusinessLogo(logo: business.logo, name: business.name, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LoyiIcons.megaphone, size: 14, color: p.accent),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        business.name.toUpperCase(),
                        style: context.eyebrow.copyWith(color: p.accent, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(title.isEmpty ? context.l10n.messageTitlePlaceholder : title, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(body.isEmpty ? context.l10n.messageBodyPlaceholder : body, style: context.text.bodyMedium),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              tooltip: context.l10n.hideThisMessage,
              onPressed: onDismiss,
              icon: Icon(LoyiIcons.x, size: 18, color: p.inkMuted),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}
