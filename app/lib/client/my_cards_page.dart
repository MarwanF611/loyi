import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/loyalty_card_view.dart';
import '../widgets/save_cards_prompt.dart';
import '../widgets/ui.dart';
import 'card_data.dart';

class MyCardsPage extends StatefulWidget {
  const MyCardsPage({super.key});

  @override
  State<MyCardsPage> createState() => _MyCardsPageState();
}

class _MyCardsPageState extends State<MyCardsPage> {
  late final Stream<User?> _user = auth.userChanges;
  bool _signingIn = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: FrostedAppBar(
      title: const LoyiWordmark(size: 26),
      actions: [
        RoundIconButton(
          icon: Icons.person_outline_rounded,
          tooltip: 'Account',
          onPressed: () => context.push('/account'),
        ),
        const SizedBox(width: 12),
      ],
    ),
    body: StreamBuilder<User?>(
      stream: _user,
      builder: (context, userSnap) {
        final user = userSnap.data;
        if (user == null) {
          // First visit or just signed out: start a fresh anonymous session.
          if (userSnap.connectionState == ConnectionState.active && !_signingIn) {
            _signingIn = true;
            auth.ensureClientSession().whenComplete(() => _signingIn = false);
          }
          return const _ListSkeleton();
        }
        return _CardList(key: ValueKey(user.uid), uid: user.uid);
      },
    ),
  );
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.fromLTRB(16, frostedTopPadding(context) + 16, 16, 32),
    children: const [
      PageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Skeleton(width: 180, height: 36),
            SizedBox(height: 20),
            Skeleton(height: 200, radius: 28),
            SizedBox(height: 16),
            Skeleton(height: 200, radius: 28),
          ],
        ),
      ),
    ],
  );
}

class _CardList extends StatefulWidget {
  const _CardList({super.key, required this.uid});

  final String uid;

  @override
  State<_CardList> createState() => _CardListState();
}

class _CardListState extends State<_CardList> {
  late final Stream<List<LoyaltyCard>> _cards = repo.cardsForClient(widget.uid);

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return StreamBuilder<List<LoyaltyCard>>(
      stream: _cards,
      builder: (context, snap) {
        if (!snap.hasData) return const _ListSkeleton();
        final cards = snap.data!;
        final anonymous = auth.user?.isAnonymous ?? false;
        final ready = cards.fold(0, (sum, c) => sum + c.rewardsAvailable);
        return ListView(
          padding: EdgeInsets.fromLTRB(16, frostedTopPadding(context) + 12, 16, 40),
          children: [
            PageBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Your cards', style: context.text.headlineLarge),
                  const SizedBox(height: 10),
                  if (cards.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Pill(
                          label: cards.length == 1 ? '1 card' : '${cards.length} cards',
                          icon: Icons.style_rounded,
                          background: p.surface,
                        ),
                        if (ready > 0)
                          Pill(
                            label: ready == 1 ? '1 reward ready' : '$ready rewards ready',
                            icon: Icons.redeem_rounded,
                            background: p.sun,
                            foreground: LoyiPalette.light.ink,
                          ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  if (cards.isEmpty) const _EmptyState(),
                  // With several cards the risk of losing them is bigger, so ask up front.
                  if (cards.length > 1 && anonymous) ...[
                    SaveCardsPrompt(cardCount: cards.length),
                    const SizedBox(height: 20),
                  ],
                  for (final card in cards) ...[
                    CardData(
                      key: ValueKey(card.id),
                      card: card,
                      placeholder: const Skeleton(height: 200, radius: 28),
                      builder: (context, program, business) {
                        final progress = card.progressFor(program.stampsRequired);
                        return LoyaltyCardView(
                          businessName: business.name,
                          programName: program.name,
                          design: program.designFor(business),
                          logo: business.logo,
                          stamps: progress.stamps,
                          stampsRequired: program.stampsRequired,
                          rewardsAvailable: progress.rewards,
                          onTap: () => context.go('/c/${card.id}'),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (cards.length == 1 && anonymous) const SaveCardsPrompt(),
                  const SizedBox(height: 28),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.go('/business'),
                      icon: const Icon(Icons.storefront_outlined, size: 20),
                      label: const Text('Own a shop? Loyi for business'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Illustration of two fanned cards and an NFC hint.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    Widget card(Color color, double angle, Offset offset) => Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 150,
          height: 96,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                card(p.sun, math.pi / 14, const Offset(34, -6)),
                card(p.accent, -math.pi / 20, const Offset(-24, 8)),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: p.surface, shape: BoxShape.circle, boxShadow: p.panelShadow),
                  child: Icon(Icons.nfc_rounded, color: p.ink, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('No cards yet', style: context.text.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Hold your phone near a Loyi tag in a shop to get your first loyalty card.',
            style: context.text.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
