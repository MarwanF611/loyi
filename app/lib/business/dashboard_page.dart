import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/loyalty_card_view.dart';
import '../widgets/stamp_icons.dart';
import '../widgets/ui.dart';
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const LoyiWordmark(size: 26), actions: const [_SignOutButton(), SizedBox(width: 8)]),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        PageBody(
          maxWidth: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Welcome to Loyi 👋', style: context.text.headlineLarge),
              const SizedBox(height: 8),
              Text("Let's set up your shop. You can change all of this later.", style: context.text.bodyMedium),
              const SizedBox(height: 24),
              Panel(
                padding: const EdgeInsets.all(24),
                child: BusinessForm(
                  submitLabel: 'Create my shop',
                  onSubmit: (name, color) => repo.createBusiness(ownerUid: auth.user!.uid, name: name, color: color),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) =>
      RoundIconButton(icon: Icons.logout_rounded, tooltip: 'Sign out', onPressed: auth.signOut);
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
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
  late Future<List<int>> _week = repo.stampsPerDay(_uid, widget.business.id);

  Future<void> _refresh() async {
    setState(() {
      _stats = repo.stats(_uid, widget.business.id);
      _week = repo.stampsPerDay(_uid, widget.business.id);
    });
    await Future.wait([_stats, _week]);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    final p = context.loyi;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: StreamBuilder<List<Program>>(
            stream: _programs,
            builder: (context, programsSnap) {
              final programs = programsSnap.data ?? const <Program>[];
              final names = {for (final p in programs) p.id: p.name};
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  PageBody(
                    maxWidth: 960,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(business: b),
                        const SizedBox(height: 24),
                        _Bento(stats: _stats, week: _week),
                        if (b.logo == null) ...[
                          const SizedBox(height: 16),
                          Panel(
                            onTap: () => context.go('/business/settings'),
                            child: Row(
                              children: [
                                IconBadge(
                                  icon: Icons.add_photo_alternate_outlined,
                                  background: p.accentSoft,
                                  foreground: p.onAccentSoft,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Add your logo', style: context.text.titleMedium),
                                      Text(
                                        'It appears on every card your clients carry.',
                                        style: context.text.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        SectionHeader(
                          title: 'Loyalty cards',
                          action: FilledButton.icon(
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                            onPressed: () => context.go('/business/programs/new'),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('New card'),
                          ),
                        ),
                        if (!programsSnap.hasData)
                          const Skeleton(height: 140, radius: Radii.lg)
                        else if (programs.isEmpty)
                          const _EmptyPrograms()
                        else
                          _ProgramGrid(programs: programs, business: b),
                        const SizedBox(height: 32),
                        const SectionHeader(title: 'Recent activity'),
                        _ActivityFeed(stamps: _stamps, redemptions: _redemptions, programNames: names),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      BusinessLogo(logo: business.logo, name: business.name, size: 52),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_greeting(), style: context.text.bodyMedium),
            Text(business.name, style: context.text.headlineMedium, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      RoundIconButton(
        icon: Icons.storefront_outlined,
        tooltip: 'Business settings',
        onPressed: () => context.go('/business/settings'),
      ),
      const SizedBox(width: 8),
      const _SignOutButton(),
    ],
  );
}

/// Bento grid: a hero tile with today's stamps and a 7-day chart, plus two small tiles.
class _Bento extends StatelessWidget {
  const _Bento({required this.stats, required this.week});

  final Future<({int clients, int stampsToday, int redeemed})> stats;
  final Future<List<int>> week;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return FutureBuilder(
      future: stats,
      builder: (context, s) {
        final clients = _SmallTile(
          label: 'Clients',
          value: s.data?.clients,
          icon: Icons.people_alt_rounded,
          background: p.surface,
          badge: p.mintSoft,
          badgeFg: p.mint,
        );
        final rewards = _SmallTile(
          label: 'Rewards given',
          value: s.data?.redeemed,
          icon: Icons.redeem_rounded,
          background: p.sunSoft,
          badge: p.sun,
          badgeFg: LoyiPalette.light.ink,
        );
        final hero = _HeroTile(today: s.data?.stampsToday, week: week);
        return LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= 720) {
              return SizedBox(
                height: 236,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: hero),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: clients),
                          const SizedBox(height: 14),
                          Expanded(child: rewards),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                SizedBox(height: 220, child: hero),
                const SizedBox(height: 14),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: clients),
                      const SizedBox(width: 14),
                      Expanded(child: rewards),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _HeroTile extends StatelessWidget {
  const _HeroTile({required this.today, required this.week});

  final int? today;
  final Future<List<int>> week;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    const white = Colors.white;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.accent, Color.lerp(p.accent, const Color(0xFF7A1D0C), 0.3)!],
        ),
        boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stamps today', style: context.text.labelLarge?.copyWith(color: white.withValues(alpha: 0.85))),
              const Spacer(),
              Text(today?.toString() ?? '–', style: context.text.displayLarge?.copyWith(color: white, fontSize: 64)),
              Text('Last 7 days →', style: context.text.labelMedium?.copyWith(color: white.withValues(alpha: 0.75))),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: FutureBuilder<List<int>>(
              future: week,
              builder: (context, s) => _WeekBars(values: s.data ?? List.filled(7, 0), highlight: p.sun),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiny bar chart: one bar per day, today highlighted.
class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.values, required this.highlight});

  final List<int> values;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    final max = values.fold(1, math.max);
    final days = [
      for (var i = values.length - 1; i >= 0; i--) DateFormat.E().format(DateTime.now().subtract(Duration(days: i)))[0],
    ];
    return Semantics(
      label: 'Stamps per day, last 7 days: ${values.join(', ')}',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: 0.06 + 0.94 * values[i] / max,
                            widthFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: i == values.length - 1 ? highlight : Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        days[i],
                        style: context.text.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SmallTile extends StatelessWidget {
  const _SmallTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
    required this.badge,
    required this.badgeFg,
  });

  final String label;
  final int? value;
  final IconData icon;
  final Color background;
  final Color badge;
  final Color badgeFg;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: background == p.surface ? p.panelShadow : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value?.toString() ?? '–', style: context.text.headlineLarge),
                Text(label, style: context.text.labelMedium?.copyWith(color: p.inkMuted)),
              ],
            ),
          ),
          IconBadge(icon: icon, background: badge, foreground: badgeFg),
        ],
      ),
    );
  }
}

class _EmptyPrograms extends StatelessWidget {
  const _EmptyPrograms();

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(28),
    child: Column(
      children: [
        IconBadge(
          icon: Icons.style_rounded,
          background: context.loyi.accentSoft,
          foreground: context.loyi.accent,
          size: 56,
        ),
        const SizedBox(height: 14),
        Text('Create your first loyalty card', style: context.text.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          'Choose how many stamps fill a card, your rewards and your colours.',
          style: context.text.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

/// Programs as mini cards in their own design colours.
class _ProgramGrid extends StatelessWidget {
  const _ProgramGrid({required this.programs, required this.business});

  final List<Program> programs;
  final Business business;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = c.maxWidth >= 720 ? 3 : (c.maxWidth >= 440 ? 2 : 1);
      const gap = 14.0;
      final width = (c.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final p in programs)
            SizedBox(
              width: width,
              child: _ProgramTile(program: p, design: p.designFor(business)),
            ),
        ],
      );
    },
  );
}

class _ProgramTile extends StatelessWidget {
  const _ProgramTile({required this.program, required this.design});

  final Program program;
  final CardDesign design;

  @override
  Widget build(BuildContext context) {
    final fg = design.textColor;
    final active = program.activeRewards.length;
    void open() => context.go('/business/programs/${program.id}');
    return Pressable(
      onTap: open,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: design.backgroundColor.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Material(
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          color: design.backgroundColor,
          child: Ink(
            height: 140,
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
                          child: Icon(stampIconData(design.stampIcon), size: 20, color: design.stampIconColor),
                        ),
                        const Spacer(),
                        if (!program.active)
                          Pill(label: 'Paused', background: Colors.white, foreground: LoyiPalette.light.ink),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      program.name,
                      style: context.text.titleLarge?.copyWith(color: fg),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${program.stampsRequired} stamps · $active ${active == 1 ? 'reward' : 'rewards'} active',
                      style: context.text.labelMedium?.copyWith(color: fg.withValues(alpha: 0.75)),
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

String _relativeTime(DateTime t) {
  final now = DateTime.now();
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (now.year == t.year && now.month == t.month && now.day == t.day) return 'Today ${DateFormat.Hm().format(t)}';
  return DateFormat('d MMM · HH:mm').format(t);
}

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.stamps, required this.redemptions, required this.programNames});

  final Stream<List<ActivityItem>> stamps;
  final Stream<List<ActivityItem>> redemptions;
  final Map<String, String> programNames;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return StreamBuilder<List<ActivityItem>>(
      stream: stamps,
      builder: (context, s) => StreamBuilder<List<ActivityItem>>(
        stream: redemptions,
        builder: (context, r) {
          final items = [...?s.data, ...?r.data]..sort((a, b) => b.at.compareTo(a.at));
          if (items.isEmpty) {
            return Panel(
              child: Row(
                children: [
                  IconBadge(icon: Icons.nfc_rounded, background: p.surfaceMuted, foreground: p.inkMuted),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Stamps and redeemed rewards will show up here as clients tap your tags.',
                      style: context.text.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }
          final shown = items.take(15).toList();
          return Panel(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                for (final (i, item) in shown.indexed) ...[
                  if (i > 0) const Divider(indent: 70, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        IconBadge(
                          icon: item.isRedemption ? Icons.redeem_rounded : Icons.approval_rounded,
                          background: item.isRedemption ? p.sunSoft : p.mintSoft,
                          foreground: item.isRedemption ? p.ink : p.mint,
                          size: 40,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.isRedemption ? 'Reward: ${item.rewardTitle}' : 'Stamp given',
                                style: context.text.titleSmall,
                              ),
                              Text(programNames[item.programId] ?? '', style: context.text.bodySmall),
                            ],
                          ),
                        ),
                        Text(_relativeTime(item.at), style: context.text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
