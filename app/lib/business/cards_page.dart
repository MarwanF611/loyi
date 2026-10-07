import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models.dart';
import '../services/language.dart';
import '../theme.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/stamp_icons.dart';
import '../widgets/ui.dart';
import 'shell.dart';

/// The Cards tab: the loyalty cards the shop offers, each with its NFC tags.
class CardsPage extends StatelessWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = BusinessData.of(context);
    final programs = data.programs;
    final p = context.loyi;
    final l = context.l10n;
    final holders = <String, int>{};
    for (final c in data.cards ?? const <LoyaltyCard>[]) {
      holders[c.programId] = (holders[c.programId] ?? 0) + 1;
    }
    return TabPage(
      eyebrow: l.loyaltyCards,
      title: l.yourCards,
      subtitle: l.yourCardsSub,
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/business/programs/new'),
          icon: const Icon(LoyiIcons.plus, size: 18),
          label: Text(l.newCard),
        ),
      ],
      children: [
        if (programs == null)
          const Skeleton(height: 160, radius: Radii.lg)
        else if (programs.isEmpty)
          const _EmptyPrograms()
        else
          _ProgramGrid(programs: programs, business: data.business, holders: holders),
        const SizedBox(height: 28),
        Panel(
          muted: true,
          radius: Radii.xl,
          padding: const EdgeInsets.all(22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon: LoyiIcons.nfc, background: p.surface, foreground: p.accent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.howTagsWork, style: context.text.titleMedium),
                    const SizedBox(height: 4),
                    Text(l.howTagsWorkBody, style: context.text.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyPrograms extends StatelessWidget {
  const _EmptyPrograms();

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(32),
    onTap: () => context.go('/business/programs/new'),
    child: Column(
      children: [
        IconBadge(
          icon: LoyiIcons.walletCards,
          background: context.loyi.accentSoft,
          foreground: context.loyi.accent,
          size: 56,
        ),
        const SizedBox(height: 14),
        Text(context.l10n.createFirstCard, style: context.text.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(context.l10n.createFirstCardSub, style: context.text.bodyMedium, textAlign: TextAlign.center),
      ],
    ),
  );
}

/// Programs as cards in their own design colours.
class _ProgramGrid extends StatelessWidget {
  const _ProgramGrid({required this.programs, required this.business, required this.holders});

  final List<Program> programs;
  final Business business;
  final Map<String, int> holders;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = c.maxWidth >= 720 ? 3 : (c.maxWidth >= 440 ? 2 : 1);
      const gap = 16.0;
      final width = (c.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final p in programs)
            SizedBox(
              width: width,
              child: _ProgramTile(program: p, design: p.designFor(business), holders: holders[p.id] ?? 0),
            ),
        ],
      );
    },
  );
}

class _ProgramTile extends StatelessWidget {
  const _ProgramTile({required this.program, required this.design, required this.holders});

  final Program program;
  final CardDesign design;
  final int holders;

  @override
  Widget build(BuildContext context) {
    final fg = design.textColor;
    final active = program.activeRewards.length;
    void open() => context.go('/business/programs/${program.id}');
    return Semantics(
      button: true,
      child: Pressable(
        onTap: open,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: design.backgroundColor.withValues(alpha: 0.35),
                blurRadius: 36,
                spreadRadius: -14,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Material(
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            color: design.backgroundColor,
            child: Ink(
              height: 168,
              decoration: BoxDecoration(
                gradient: design.style == CardStyle.solid
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [design.backgroundColor, design.secondaryColor],
                      ),
              ),
              child: InkWell(
                onTap: open,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: design.stampFill,
                            child: Icon(stampIconData(design.stampIcon), size: 19, color: design.stampIconColor),
                          ),
                          const Spacer(),
                          if (!program.active)
                            Pill(
                              label: context.l10n.paused,
                              background: Colors.white,
                              foreground: LoyiPalette.light.ink,
                            )
                          else
                            Pill(
                              icon: LoyiIcons.users,
                              label: '$holders',
                              background: Colors.white.withValues(alpha: 0.2),
                              foreground: fg,
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        program.name,
                        style: context.text.titleLarge?.copyWith(color: fg),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        context.l10n.programTileSummary(program.stampsRequired, active),
                        style: context.text.labelMedium?.copyWith(color: fg.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
