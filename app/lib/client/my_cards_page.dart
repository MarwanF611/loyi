import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/loyalty_card_view.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My cards'),
        actions: [
          IconButton(
            tooltip: 'Account',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/account'),
          ),
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
            return const Center(child: CircularProgressIndicator());
          }
          return _CardList(key: ValueKey(user.uid), uid: user.uid);
        },
      ),
    );
  }
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
    final text = Theme.of(context).textTheme;
    return StreamBuilder<List<LoyaltyCard>>(
      stream: _cards,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final cards = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PageBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (cards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          const Icon(Icons.nfc_rounded, size: 64),
                          const SizedBox(height: 16),
                          Text('No cards yet', style: text.titleLarge),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap a Loyi tag in a shop with your phone to get your first loyalty card.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  for (final card in cards) ...[
                    CardData(
                      card: card,
                      builder: (context, program, business) {
                        final progress = card.progressFor(program.stampsRequired);
                        return LoyaltyCardView(
                          businessName: business.name,
                          programName: program.name,
                          color: Color(business.color),
                          stamps: progress.stamps,
                          stampsRequired: program.stampsRequired,
                          rewardsAvailable: progress.rewards,
                          onTap: () => context.go('/c/${card.id}'),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => context.go('/business'),
                    child: const Text('Own a shop? Loyi for business →'),
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
