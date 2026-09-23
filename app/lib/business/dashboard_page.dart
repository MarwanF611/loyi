import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/repo.dart';
import '../theme.dart';
import 'business_form.dart';
import 'business_scope.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) => BusinessScope(
    builder: (context, business) => business == null ? const _Onboarding() : _Dashboard(business: business),
  );
}

class _Onboarding extends StatelessWidget {
  const _Onboarding();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(actions: const [_SignOutButton()]),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Welcome to Loyi 👋', style: text.headlineMedium),
                const SizedBox(height: 8),
                const Text("Let's set up your business. You can change this later."),
                const SizedBox(height: 32),
                BusinessForm(
                  submitLabel: 'Create business',
                  onSubmit: (name, color) => repo.createBusiness(ownerUid: auth.user!.uid, name: name, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) =>
      IconButton(tooltip: 'Sign out', icon: const Icon(Icons.logout), onPressed: auth.signOut);
}

class _Dashboard extends StatefulWidget {
  const _Dashboard({required this.business});

  final Business business;

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  late final String _uid = auth.user!.uid;
  late final Stream<List<Program>> _programs = repo.programsForBusiness(widget.business.id);
  late final Stream<List<ActivityItem>> _stamps = repo.recentStamps(_uid, widget.business.id);
  late final Stream<List<ActivityItem>> _redemptions = repo.recentRedemptions(_uid, widget.business.id);
  late Future<({int clients, int stampsToday, int redeemed})> _stats = repo.stats(_uid, widget.business.id);

  Future<void> _refresh() async {
    setState(() => _stats = repo.stats(_uid, widget.business.id));
    await _stats;
  }

  Future<void> _editBusiness() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Business details'),
      content: SizedBox(
        width: 400,
        child: BusinessForm(
          initialName: widget.business.name,
          initialColor: widget.business.color,
          submitLabel: 'Save',
          onSubmit: (name, color) async {
            await repo.updateBusiness(widget.business.id, name: name, color: color);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.business.name),
        actions: [
          IconButton(tooltip: 'Edit business', icon: const Icon(Icons.storefront_outlined), onPressed: _editBusiness),
          const _SignOutButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: StreamBuilder<List<Program>>(
          stream: _programs,
          builder: (context, programsSnap) {
            final programs = programsSnap.data ?? const <Program>[];
            final names = {for (final p in programs) p.id: p.name};
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PageBody(
                  maxWidth: 900,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FutureBuilder(
                        future: _stats,
                        builder: (context, s) => Row(
                          children: [
                            _StatTile(label: 'Clients', value: s.data?.clients, icon: Icons.people_outline),
                            const SizedBox(width: 12),
                            _StatTile(label: 'Stamps today', value: s.data?.stampsToday, icon: Icons.approval),
                            const SizedBox(width: 12),
                            _StatTile(label: 'Rewards given', value: s.data?.redeemed, icon: Icons.card_giftcard),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(child: Text('Loyalty cards', style: text.titleLarge)),
                          FilledButton.tonalIcon(
                            onPressed: () => context.go('/business/programs/new'),
                            icon: const Icon(Icons.add),
                            label: const Text('New card'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (programsSnap.hasData && programs.isEmpty)
                        Card.outlined(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Icon(Icons.style_outlined, size: 48),
                                const SizedBox(height: 12),
                                Text('Create your first loyalty card', style: text.titleMedium),
                                const SizedBox(height: 4),
                                const Text(
                                  'Choose how many stamps fill a card and which rewards clients can pick.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      for (final p in programs) ...[
                        _ProgramTile(program: p, color: Color(widget.business.color)),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 28),
                      Text('Recent activity', style: text.titleLarge),
                      const SizedBox(height: 8),
                      _ActivityFeed(stamps: _stamps, redemptions: _redemptions, programNames: names),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon});

  final String label;
  final int? value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(value?.toString() ?? '–', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(label, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgramTile extends StatelessWidget {
  const _ProgramTile({required this.program, required this.color});

  final Program program;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final active = program.activeRewards.length;
    return Card.outlined(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Text('${program.stampsRequired}'),
        ),
        title: Text(program.name),
        subtitle: Text('${program.stampsRequired} stamps · $active ${active == 1 ? 'reward' : 'rewards'} active'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!program.active) const Chip(label: Text('Paused'), visualDensity: VisualDensity.compact),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => context.go('/business/programs/${program.id}'),
      ),
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.stamps, required this.redemptions, required this.programNames});

  final Stream<List<ActivityItem>> stamps;
  final Stream<List<ActivityItem>> redemptions;
  final Map<String, String> programNames;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ActivityItem>>(
    stream: stamps,
    builder: (context, s) => StreamBuilder<List<ActivityItem>>(
      stream: redemptions,
      builder: (context, r) {
        final items = [...?s.data, ...?r.data]..sort((a, b) => b.at.compareTo(a.at));
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Stamps and redeemed rewards will show up here.'),
          );
        }
        final time = DateFormat('d MMM · HH:mm');
        return Card.outlined(
          child: Column(
            children: [
              for (final item in items.take(20))
                ListTile(
                  dense: true,
                  leading: Icon(item.isRedemption ? Icons.card_giftcard : Icons.approval),
                  title: Text(item.isRedemption ? 'Redeemed: ${item.rewardTitle}' : 'Stamp given'),
                  subtitle: Text(programNames[item.programId] ?? ''),
                  trailing: Text(time.format(item.at)),
                ),
            ],
          ),
        );
      },
    ),
  );
}
