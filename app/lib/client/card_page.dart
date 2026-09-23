import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/loyalty_card_view.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 140,
        leading: TextButton.icon(
          onPressed: () => context.go('/cards'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('My cards'),
        ),
      ),
      body: StreamBuilder<LoyaltyCard?>(
        stream: _card,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final card = snap.data;
          if (card == null) return const _CardNotFound();
          return CardData(
            card: card,
            builder: (context, program, business) =>
                _CardDetails(card: card, program: program, business: business, tapResult: widget.tapResult),
          );
        },
      ),
    );
  }
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
          Text('Card not found on this device.', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => context.go('/cards'), child: const Text('My cards')),
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
  String? _selectedRewardId;
  bool _redeeming = false;

  Future<void> _redeem(Reward reward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Use "${reward.title}" now?'),
        content: const Text(
          'Only do this at the counter. Staff need to see the confirmation screen. '
          'This uses one full card.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not yet')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Use reward')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _redeeming = true);
    try {
      final result = await api.redeem(cardId: widget.card.id, rewardId: reward.id);
      if (!mounted) return;
      context.go(
        '/redeemed',
        extra: RedeemedArgs(
          cardId: widget.card.id,
          businessName: widget.business.name,
          rewardTitle: result.rewardTitle,
          redeemedAt: result.redeemedAt,
          color: Color(widget.business.color),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final program = widget.program;
    final progress = widget.card.progressFor(program.stampsRequired);
    final rewards = program.activeRewards;
    final selected = rewards.where((r) => r.id == _selectedRewardId).firstOrNull ?? rewards.firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.tapResult != null) ...[_TapBanner(result: widget.tapResult!), const SizedBox(height: 16)],
              LoyaltyCardView(
                businessName: widget.business.name,
                programName: program.name,
                color: Color(widget.business.color),
                stamps: progress.stamps,
                stampsRequired: program.stampsRequired,
                rewardsAvailable: progress.rewards,
                animateLatestStamp: widget.tapResult?.outcome == TapOutcome.stamped && !widget.tapResult!.completedCard,
              ),
              const SizedBox(height: 28),
              if (progress.rewards > 0) ...[
                Text('Choose your reward', style: text.titleLarge),
                const SizedBox(height: 4),
                Text('Your full card is saved. Use it now or on a later visit.', style: text.bodyMedium),
                const SizedBox(height: 12),
                if (rewards.isEmpty)
                  const Text('This shop has no rewards available right now. Your full card stays saved.')
                else ...[
                  RadioGroup<String>(
                    groupValue: selected?.id,
                    onChanged: (id) => setState(() => _selectedRewardId = id),
                    child: Column(
                      children: [
                        for (final reward in rewards)
                          RadioListTile<String>(value: reward.id, title: Text(reward.title)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _redeeming || selected == null ? null : () => _redeem(selected),
                    icon: const Icon(Icons.card_giftcard),
                    label: const Text('Use reward at the counter'),
                  ),
                ],
              ] else if (rewards.isNotEmpty) ...[
                Text('${program.stampsRequired - progress.stamps} more to go', style: text.titleLarge),
                const SizedBox(height: 4),
                Text('Fill your card, then choose one of these:', style: text.bodyMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in rewards) Chip(avatar: const Icon(Icons.redeem, size: 18), label: Text(r.title)),
                  ],
                ),
              ],
              if (auth.user?.isAnonymous ?? false) ...[const SizedBox(height: 28), const _SaveCardsPrompt()],
            ],
          ),
        ),
      ],
    );
  }
}

class _TapBanner extends StatelessWidget {
  const _TapBanner({required this.result});

  final TapResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, title, subtitle) = switch (result.outcome) {
      TapOutcome.stamped when result.completedCard => (
        Icons.celebration,
        'Card full! 🎉',
        'You earned a reward. Choose it below, now or on a later visit.',
      ),
      TapOutcome.stamped => (Icons.check_circle, 'Stamp added!', 'Thanks for your visit.'),
      TapOutcome.joined => (
        Icons.waving_hand,
        'Welcome!',
        'Your loyalty card is ready. Tap the counter tag after each purchase.',
      ),
      TapOutcome.alreadyMember => (Icons.style, 'You already have this card', 'Here is your progress.'),
      TapOutcome.cooldown => (
        Icons.timer_outlined,
        'Already stamped',
        'Your next stamp is possible in ${_formatWait(result.retryAfter)}.',
      ),
    };
    final positive = result.outcome != TapOutcome.cooldown;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: Card(
        color: positive ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(icon, size: 32, color: positive ? scheme.onPrimaryContainer : null),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }

  static String _formatWait(Duration d) {
    if (d.inHours >= 1) return '${d.inHours} h ${d.inMinutes.remainder(60)} min';
    return '${d.inMinutes + 1} min';
  }
}

class _SaveCardsPrompt extends StatelessWidget {
  const _SaveCardsPrompt();

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const Icon(Icons.cloud_done_outlined),
      title: const Text("Don't lose your stamps"),
      subtitle: const Text('Add your email to keep your cards on a new phone.'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/account'),
    ),
  );
}
