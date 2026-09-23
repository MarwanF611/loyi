import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/confetti.dart';
import '../widgets/loyalty_card_view.dart';
import '../widgets/save_cards_prompt.dart';
import '../widgets/ui.dart';
import 'card_data.dart';
import 'redeemed_page.dart';

class CardPage extends StatefulWidget {
  const CardPage({super.key, required this.cardId, this.tapResult});

  final String cardId;

  /// Set when the client just arrived from a tag tap.
  final TapResult? tapResult;

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  late final Stream<LoyaltyCard?> _card = repo.card(widget.cardId);

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: FrostedAppBar(
      leadingWidth: 150,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: TextButton.icon(
          onPressed: () => context.go('/cards'),
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          label: const Text('My cards'),
        ),
      ),
    ),
    body: StreamBuilder<LoyaltyCard?>(
      stream: _card,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const _CardSkeleton();
        final card = snap.data;
        if (card == null) return const _CardNotFound();
        return CardData(
          card: card,
          placeholder: const _CardSkeleton(),
          builder: (context, program, business) =>
              _CardDetails(card: card, program: program, business: business, tapResult: widget.tapResult),
        );
      },
    ),
  );
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.fromLTRB(16, frostedTopPadding(context) + 8, 16, 32),
    children: const [
      PageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Skeleton(height: 72, radius: Radii.lg),
            SizedBox(height: 16),
            Skeleton(height: 210, radius: 28),
            SizedBox(height: 24),
            Skeleton(height: 120, radius: Radii.lg),
          ],
        ),
      ),
    ],
  );
}

class _CardNotFound extends StatelessWidget {
  const _CardNotFound();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(
            icon: Icons.search_off_rounded,
            background: context.loyi.surfaceMuted,
            foreground: context.loyi.inkMuted,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text('Card not found on this device', style: context.text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(onPressed: () => context.go('/cards'), child: const Text('Go to my cards')),
        ],
      ),
    ),
  );
}

class _CardDetails extends StatefulWidget {
  const _CardDetails({required this.card, required this.program, required this.business, this.tapResult});

  final LoyaltyCard card;
  final Program program;
  final Business business;
  final TapResult? tapResult;

  @override
  State<_CardDetails> createState() => _CardDetailsState();
}

class _CardDetailsState extends State<_CardDetails> {
  @override
  void initState() {
    super.initState();
    // A little physical feedback when the stamp lands (Android; iOS web ignores it).
    final r = widget.tapResult;
    if (r?.completedCard ?? false) {
      HapticFeedback.heavyImpact();
    } else if (r?.outcome == TapOutcome.stamped) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _chooseReward() async {
    final result = await showLoyiSheet<RedeemResult>(
      context,
      builder: (_) => _RewardSheet(card: widget.card, program: widget.program),
    );
    if (result == null || !mounted) return;
    context.go(
      '/redeemed',
      extra: RedeemedArgs(
        cardId: widget.card.id,
        businessName: widget.business.name,
        logoUrl: widget.business.logoUrl,
        rewardTitle: result.rewardTitle,
        redeemedAt: result.redeemedAt,
        design: widget.program.designFor(widget.business),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    final program = widget.program;
    final design = program.designFor(widget.business);
    final progress = widget.card.progressFor(program.stampsRequired);
    final rewards = program.activeRewards;
    final tap = widget.tapResult;
    final hasReward = progress.rewards > 0;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16, frostedTopPadding(context) + 8, 16, hasReward ? 130 : 40),
          children: [
            PageBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (tap != null) ...[_TapBanner(result: tap), const SizedBox(height: 18)],
                  LoyaltyCardView(
                    businessName: widget.business.name,
                    programName: program.name,
                    design: design,
                    logoUrl: widget.business.logoUrl,
                    stamps: progress.stamps,
                    stampsRequired: program.stampsRequired,
                    rewardsAvailable: progress.rewards,
                    animateLatestStamp: tap?.outcome == TapOutcome.stamped && !tap!.completedCard,
                  ),
                  const SizedBox(height: 24),
                  if (hasReward)
                    Panel(
                      color: p.sunSoft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconBadge(
                                icon: Icons.redeem_rounded,
                                background: p.sun,
                                foreground: LoyiPalette.light.ink,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      progress.rewards == 1 ? '1 reward ready' : '${progress.rewards} rewards ready',
                                      style: context.text.titleLarge,
                                    ),
                                    Text('Saved on your card. Use it now or later.', style: context.text.bodySmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (rewards.isEmpty) ...[
                            const SizedBox(height: 12),
                            Text('This shop has no rewards available right now.', style: context.text.bodyMedium),
                          ],
                        ],
                      ),
                    )
                  else
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${program.stampsRequired - progress.stamps}', style: context.text.headlineLarge),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('more to go', style: context.text.titleMedium?.copyWith(color: p.inkMuted)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: progress.stamps / program.stampsRequired,
                              minHeight: 10,
                              color: design.backgroundColor.computeLuminance() > 0.8
                                  ? p.accent
                                  : design.backgroundColor,
                            ),
                          ),
                          if (rewards.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Text(
                              'Then choose one of these',
                              style: context.text.labelMedium?.copyWith(color: p.inkMuted),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final r in rewards)
                                  Pill(label: r.title, icon: Icons.redeem_rounded, background: p.sunSoft),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(value: '${widget.card.totalStamps}', label: 'stamps collected'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniStat(value: '${widget.card.totalRedeemed}', label: 'rewards used'),
                      ),
                    ],
                  ),
                  if (auth.user?.isAnonymous ?? false) ...[const SizedBox(height: 14), const SaveCardsPrompt()],
                ],
              ),
            ),
          ],
        ),
        if (hasReward && rewards.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomActionBar(
              child: FilledButton.icon(
                onPressed: _chooseReward,
                icon: const Icon(Icons.redeem_rounded),
                label: const Text('Use a reward'),
              ),
            ),
          ),
        if (tap?.completedCard ?? false)
          Positioned.fill(
            child: ConfettiBurst(colors: [p.accent, p.sun, p.mint, design.backgroundColor, design.stampFill]),
          ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: context.text.headlineSmall),
        Text(label, style: context.text.bodySmall),
      ],
    ),
  );
}

/// Bottom sheet: pick one of the active rewards and confirm at the counter.
class _RewardSheet extends StatefulWidget {
  const _RewardSheet({required this.card, required this.program});

  final LoyaltyCard card;
  final Program program;

  @override
  State<_RewardSheet> createState() => _RewardSheetState();
}

class _RewardSheetState extends State<_RewardSheet> {
  late String _selected = widget.program.activeRewards.first.id;
  bool _busy = false;
  String? _error;

  Future<void> _redeem() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await api.redeem(cardId: widget.card.id, rewardId: _selected);
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Choose your reward', style: context.text.headlineSmall),
        const SizedBox(height: 4),
        Text('This uses one full card.', style: context.text.bodyMedium),
        const SizedBox(height: 18),
        for (final r in widget.program.activeRewards) ...[
          _RewardOption(title: r.title, selected: r.id == _selected, onTap: () => setState(() => _selected = r.id)),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p.surfaceMuted, borderRadius: BorderRadius.circular(Radii.md)),
          child: Row(
            children: [
              Icon(Icons.storefront_rounded, color: p.inkMuted, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Only do this at the counter. Staff need to see the confirmation screen.',
                  style: context.text.bodySmall?.copyWith(color: p.ink),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: context.text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _busy ? null : _redeem,
          child: _busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Text('Use it now'),
        ),
        const SizedBox(height: 6),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Not yet')),
      ],
    );
  }
}

class _RewardOption extends StatelessWidget {
  const _RewardOption({required this.title, required this.selected, required this.onTap});

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return Semantics(
      selected: selected,
      button: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected ? p.accentSoft : p.surface,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: selected ? p.accent : p.line, width: selected ? 2 : 1.5),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.md),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    IconBadge(icon: Icons.redeem_rounded, background: p.sunSoft, foreground: p.ink, size: 40),
                    const SizedBox(width: 14),
                    Expanded(child: Text(title, style: context.text.titleMedium)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: selected
                          ? Icon(Icons.check_circle_rounded, key: const ValueKey(1), color: p.accent, size: 26)
                          : Icon(Icons.circle_outlined, key: const ValueKey(0), color: p.line, size: 26),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TapBanner extends StatelessWidget {
  const _TapBanner({required this.result});

  final TapResult result;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    final (icon, title, subtitle, bg, fg) = switch (result.outcome) {
      TapOutcome.stamped when result.completedCard => (
        Icons.celebration_rounded,
        'Card full!',
        'You earned a reward. Use it now or on a later visit.',
        p.sunSoft,
        p.sun,
      ),
      TapOutcome.stamped => (Icons.check_rounded, 'Stamp added', 'Thanks for your visit!', p.mintSoft, p.mint),
      TapOutcome.joined => (
        Icons.waving_hand_rounded,
        'Welcome!',
        'Your card is ready. Tap the counter tag after each purchase.',
        p.accentSoft,
        p.accent,
      ),
      TapOutcome.alreadyMember => (
        Icons.style_rounded,
        'Your card',
        'You already have this card.',
        p.surfaceMuted,
        p.ink,
      ),
      TapOutcome.cooldown => (
        Icons.timer_outlined,
        'Already stamped',
        'Your next stamp is possible in ${_formatWait(result.retryAfter)}.',
        p.surfaceMuted,
        p.inkMuted,
      ),
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: Semantics(
        liveRegion: true,
        child: Panel(
          color: bg,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
                child: Icon(icon, color: fg == p.sun ? LoyiPalette.light.ink : Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleMedium),
                    Text(subtitle, style: context.text.bodySmall?.copyWith(color: p.ink.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatWait(Duration d) {
    if (d.inHours >= 1) return '${d.inHours} h ${d.inMinutes.remainder(60)} min';
    return '${d.inMinutes + 1} min';
  }
}
