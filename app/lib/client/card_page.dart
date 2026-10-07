import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../services/language.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/confetti.dart';
import '../widgets/loyalty_card_view.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/message_card.dart';
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
          icon: const Icon(LoyiIcons.arrowLeft, size: 20),
          label: Text(context.l10n.myCards),
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
            icon: LoyiIcons.searchX,
            background: context.loyi.surfaceMuted,
            foreground: context.loyi.inkMuted,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(context.l10n.cardNotOnDevice, style: context.text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(onPressed: () => context.go('/cards'), child: Text(context.l10n.goToMyCards)),
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
        logo: widget.business.logo,
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
                    logo: widget.business.logo,
                    stamps: progress.stamps,
                    stampsRequired: program.stampsRequired,
                    rewardsAvailable: progress.rewards,
                    animateLatestStamp: tap?.outcome == TapOutcome.stamped && !tap!.completedCard,
                  ),
                  _ShopMessages(card: widget.card, program: program, business: widget.business),
                  const SizedBox(height: 24),
                  if (hasReward)
                    Panel(
                      color: p.sunSoft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconBadge(icon: LoyiIcons.gift, background: p.sun, foreground: LoyiPalette.light.ink),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(context.l10n.rewardsReady(progress.rewards), style: context.text.titleLarge),
                                    Text(context.l10n.savedOnCard, style: context.text.bodySmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (rewards.isEmpty) ...[
                            const SizedBox(height: 12),
                            Text(context.l10n.noRewardsNow, style: context.text.bodyMedium),
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
                                child: Text(
                                  context.l10n.moreToGo,
                                  style: context.text.titleMedium?.copyWith(color: p.inkMuted),
                                ),
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
                              context.l10n.thenChooseOne,
                              style: context.text.labelMedium?.copyWith(color: p.inkMuted),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final r in rewards)
                                  Pill(label: r.title, icon: LoyiIcons.gift, background: p.sunSoft),
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
                        child: _MiniStat(value: '${widget.card.totalStamps}', label: context.l10n.stampsCollected),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniStat(value: '${widget.card.totalRedeemed}', label: context.l10n.rewardsUsedLower),
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
                icon: const Icon(LoyiIcons.gift),
                label: Text(context.l10n.useAReward),
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

/// The shop's follow-up message for this card, if one is meant for this client.
/// The match happens here, on the client's device: the shop never learns who saw it.
class _ShopMessages extends StatefulWidget {
  const _ShopMessages({required this.card, required this.program, required this.business});

  final LoyaltyCard card;
  final Program program;
  final Business business;

  @override
  State<_ShopMessages> createState() => _ShopMessagesState();
}

class _ShopMessagesState extends State<_ShopMessages> {
  static const _key = 'hiddenMessages';
  late final Stream<List<ShopMessage>> _messages = repo.activeMessages(widget.business.id);
  Set<String> _hidden = {};

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance()
        .then((prefs) {
          if (mounted) setState(() => _hidden = {...?prefs.getStringList(_key)});
        })
        .catchError((Object _) {});
  }

  Future<void> _hide(ShopMessage m) async {
    setState(() => _hidden = {..._hidden, m.id});
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _hidden.toList());
    } catch (_) {
      // Storage blocked: hidden for this visit only.
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ShopMessage>>(
    stream: _messages,
    builder: (context, snap) {
      final now = DateTime.now();
      final shown = [
        for (final m in snap.data ?? const <ShopMessage>[])
          if (!_hidden.contains(m.id) && m.showsFor(widget.card, widget.program, now)) m,
      ]..sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
      return AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: shown.isEmpty
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 16),
                child: MessageCard(
                  business: widget.business,
                  title: shown.first.title,
                  body: shown.first.body,
                  onDismiss: () => _hide(shown.first),
                ),
              ),
      );
    },
  );
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
        Text(context.l10n.chooseYourReward, style: context.text.headlineSmall),
        const SizedBox(height: 4),
        Text(context.l10n.usesOneFullCard, style: context.text.bodyMedium),
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
              Icon(LoyiIcons.store, color: p.inkMuted, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(context.l10n.onlyAtCounter, style: context.text.bodySmall?.copyWith(color: p.ink)),
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
              : Text(context.l10n.useItNow),
        ),
        const SizedBox(height: 6),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.notYet)),
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
                    IconBadge(icon: LoyiIcons.gift, background: p.sunSoft, foreground: p.ink, size: 40),
                    const SizedBox(width: 14),
                    Expanded(child: Text(title, style: context.text.titleMedium)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: selected
                          ? Icon(LoyiIcons.circleCheck, key: const ValueKey(1), color: p.accent, size: 26)
                          : Icon(LoyiIcons.circle, key: const ValueKey(0), color: p.line, size: 26),
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
    final l = context.l10n;
    final (icon, title, subtitle, bg, fg) = switch (result.outcome) {
      TapOutcome.stamped when result.completedCard => (
        LoyiIcons.partyPopper,
        l.cardFull,
        l.cardFullSub,
        p.sunSoft,
        p.sun,
      ),
      TapOutcome.stamped => (LoyiIcons.check, l.stampAdded, l.thanksForVisit, p.mintSoft, p.mint),
      TapOutcome.joined => (LoyiIcons.hand, l.welcome, l.welcomeSub, p.accentSoft, p.accent),
      TapOutcome.alreadyMember => (LoyiIcons.walletCards, l.yourCard, l.alreadyHaveCard, p.surfaceMuted, p.ink),
      TapOutcome.cooldown => (
        LoyiIcons.timer,
        l.alreadyStamped,
        l.nextStampIn(_formatWait(l, result.retryAfter)),
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

  static String _formatWait(L10n l, Duration d) {
    if (d.inHours >= 1) return l.waitHoursMinutes(d.inHours, d.inMinutes.remainder(60));
    return l.waitMinutes(d.inMinutes + 1);
  }
}
