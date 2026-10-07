import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../services/language.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/ui.dart';
import 'insights/analytics.dart';
import 'messages.dart';
import 'shell.dart';
import 'subscribe_page.dart';

String _greeting(L10n l) {
  final h = DateTime.now().hour;
  if (h < 12) return l.goodMorning;
  if (h < 18) return l.goodAfternoon;
  return l.goodEvening;
}

/// "+12%" / "-5%", in the local style (French: "+12 %").
String signedPercent(double change) => '${change >= 0 ? '+' : ''}${NumberFormat.percentPattern().format(change)}';

/// The Overview tab: today at a glance, who to follow up with, and the live feed.
class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late BusinessData _data;
  bool _started = false;
  late Future<({int clients, int stampsToday, int redeemed})> _stats;
  late Future<List<int>> _days;
  late Stream<List<ActivityItem>> _stamps;
  late Stream<List<ActivityItem>> _redemptions;
  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _debounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data = BusinessData.of(context);
    if (_started) return;
    _started = true;
    final (uid, id) = (_data.uid, _data.business.id);
    _stamps = repo.recentStamps(uid, id);
    _redemptions = repo.recentRedemptions(uid, id);
    _load();
    // Refresh the counts whenever a client stamps or redeems (skip the initial snapshot).
    for (final stream in [_stamps, _redemptions]) {
      _subscriptions.add(stream.skip(1).listen((_) => _scheduleRefresh(), onError: (_) {}));
    }
  }

  void _load() {
    final (uid, id) = (_data.uid, _data.business.id);
    _stats = repo.stats(uid, id);
    _days = repo.stampsPerDay(uid, id, days: 14);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(_load);
    });
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_stats, _days]);
  }

  @override
  Widget build(BuildContext context) {
    final data = BusinessData.of(context);
    final b = data.business;
    final p = context.loyi;
    final l = context.l10n;
    return TabPage(
      eyebrow: _greeting(l),
      title: b.name,
      onRefresh: _refresh,
      actions: [
        if (wideLayout(context))
          FilledButton.icon(
            onPressed: () => showMessageComposer(context),
            icon: const Icon(LoyiIcons.megaphone, size: 18),
            label: Text(l.newMessage),
          ),
      ],
      children: [
        const SubscriptionBanner(),
        _Hero(stats: _stats, days: _days),
        const SizedBox(height: 16),
        _Kpis(stats: _stats),
        const SizedBox(height: 36),
        SectionHeader(eyebrow: l.followUp, title: l.whoToReachOut, subtitle: l.whoToReachOutSub),
        const _FollowUps(),
        if (b.logo == null) ...[
          const SizedBox(height: 16),
          Panel(
            muted: true,
            onTap: () => context.go('/business/settings'),
            child: Row(
              children: [
                IconBadge(icon: LoyiIcons.imagePlus, background: p.accentSoft, foreground: p.accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.addYourLogo, style: context.text.titleMedium),
                      Text(l.addYourLogoSub, style: context.text.bodySmall),
                    ],
                  ),
                ),
                const Icon(LoyiIcons.chevronRight),
              ],
            ),
          ),
        ],
        const SizedBox(height: 36),
        SectionHeader(
          eyebrow: l.live,
          title: l.recentActivity,
          action: TextButton(onPressed: () => context.go('/business/insights'), child: Text(l.allInsights)),
        ),
        _ActivityFeed(stamps: _stamps, redemptions: _redemptions),
      ],
    );
  }
}

/// Coral stage like the website's hero: today's stamps and the last 7 days.
class _Hero extends StatelessWidget {
  const _Hero({required this.stats, required this.days});

  final Future<({int clients, int stampsToday, int redeemed})> stats;
  final Future<List<int>> days;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    return FutureBuilder<List<int>>(
      future: days,
      builder: (context, d) {
        final values = d.data ?? List.filled(14, 0);
        final week = values.sublist(7);
        final thisWeek = week.fold(0, (a, b) => a + b);
        final lastWeek = values.sublist(0, 7).fold(0, (a, b) => a + b);
        final delta = change(thisWeek, lastWeek);
        final summary = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Eyebrow(context.l10n.stampsToday, color: white.withValues(alpha: 0.8)),
            const SizedBox(height: 10),
            FutureBuilder(
              future: stats,
              builder: (context, s) => _Count(
                value: s.data?.stampsToday,
                style: context.text.displayLarge!.copyWith(color: white, fontSize: 72),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _GlassChip(label: context.l10n.thisWeekCount(thisWeek)),
                if (delta != null)
                  _GlassChip(
                    icon: delta >= 0 ? LoyiIcons.trendingUp : LoyiIcons.trendingDown,
                    label: context.l10n.vsLastWeek(signedPercent(delta)),
                  ),
              ],
            ),
          ],
        );
        final bars = _WeekBars(values: week);
        return CoralStage(
          padding: const EdgeInsets.all(26),
          child: LayoutBuilder(
            builder: (context, c) => c.maxWidth >= 620
                ? SizedBox(
                    height: 210,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: summary),
                        const SizedBox(width: 24),
                        Expanded(child: bars),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      summary,
                      const SizedBox(height: 22),
                      SizedBox(height: 130, child: bars),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// Animates a number counting up, like the website's stats.
class _Count extends StatelessWidget {
  const _Count({required this.value, required this.style});

  final int? value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v == null) return Text('–', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: v.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, x, _) => Text(NumberFormat.decimalPattern().format(x.round()), style: style),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0x2917161C),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 15, color: Colors.white), const SizedBox(width: 6)],
        Text(label, style: context.text.labelMedium?.copyWith(color: Colors.white)),
      ],
    ),
  );
}

/// One white bar per day on the coral stage, today in sunny yellow.
class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final max = values.fold(1, math.max);
    final now = DateTime.now();
    final days = [
      for (var i = values.length - 1; i >= 0; i--)
        DateFormat.E().format(now.subtract(Duration(days: i)))[0].toUpperCase(),
    ];
    return Semantics(
      label: context.l10n.stampsLast7Days(values.join(', ')),
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Text(
                          '${values[i]}',
                          style: context.text.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: (0.05 + 0.95 * values[i] / max) * t,
                              widthFactor: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: i == values.length - 1
                                      ? const Color(0xFFFFC83D)
                                      : Colors.white.withValues(alpha: 0.38),
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
      ),
    );
  }
}

/// Four key numbers, from the live card list and the reward count.
class _Kpis extends StatelessWidget {
  const _Kpis({required this.stats});

  final Future<({int clients, int stampsToday, int redeemed})> stats;

  @override
  Widget build(BuildContext context) {
    final data = BusinessData.of(context);
    final p = context.loyi;
    final l = context.l10n;
    final cards = data.cards;
    final now = DateTime.now();
    final clients = cards == null ? null : summarizeClients(data.business.id, cards, data.programById);
    final joinedThisMonth = clients?.where((c) => c.joined != null && now.difference(c.joined!).inDays < 30).length;
    final active = clients?.where((c) => c.lastVisit != null && now.difference(c.lastVisit!).inDays < 30).length;
    final waiting = clients?.fold(0, (a, c) => a + c.rewardsWaiting);
    return FutureBuilder(
      future: stats,
      builder: (context, s) {
        final tiles = [
          KpiTile(
            icon: LoyiIcons.users,
            tone: (p.mintSoft, p.mint),
            label: l.kpiClients,
            value: clients?.length,
            note: joinedThisMonth == null ? null : l.kpiJoinedThisMonth(joinedThisMonth),
          ),
          KpiTile(
            icon: LoyiIcons.repeat,
            tone: (p.accentSoft, p.accent),
            label: l.kpiActive,
            value: active,
            note: l.kpiActiveNote,
          ),
          KpiTile(
            icon: LoyiIcons.hourglass,
            tone: (p.sunSoft, p.onSunSoft),
            label: l.kpiRewardsWaiting,
            value: waiting,
            note: l.kpiRewardsWaitingNote,
          ),
          KpiTile(
            icon: LoyiIcons.gift,
            tone: (p.surfaceMuted, p.ink),
            label: l.kpiRewardsGiven,
            value: s.data?.redeemed,
            note: l.kpiRewardsGivenNote,
          ),
        ];
        return KpiGrid(tiles: tiles);
      },
    );
  }
}

/// Lays tiles out 4, 2 or 1 per row.
class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = c.maxWidth >= 860 ? 4 : 2;
      return GridRows(columns: columns, gap: 14, children: tiles);
    },
  );
}

/// A key number with an icon, a label and a small note (or a change).
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
    this.note,
    this.delta,
    this.format,
  });

  final IconData icon;

  /// Badge background and icon colour.
  final (Color, Color) tone;
  final String label;
  final num? value;
  final String? note;

  /// Change against the previous period, shown instead of [note] when set.
  final double? delta;
  final String Function(num value)? format;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    final v = value;
    final d = delta;
    return Panel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, background: tone.$1, foreground: tone.$2, size: 36),
          const SizedBox(height: 14),
          if (v == null)
            const Skeleton(width: 64, height: 34, radius: 10)
          else if (format != null)
            Text(format!(v), style: context.text.headlineLarge)
          else
            _Count(value: v.round(), style: context.text.headlineLarge!),
          const SizedBox(height: 2),
          Text(label, style: context.text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          if (d != null)
            Row(
              children: [
                Icon(
                  d >= 0 ? LoyiIcons.trendingUp : LoyiIcons.trendingDown,
                  size: 15,
                  color: d >= 0 ? p.mint : p.accent,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    context.l10n.vsBefore(signedPercent(d)),
                    style: context.text.bodySmall?.copyWith(color: d >= 0 ? p.mint : p.accent),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            Text(note ?? ' ', style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Ready-made groups to follow up with, each opening the message composer.
class _FollowUps extends StatelessWidget {
  const _FollowUps();

  @override
  Widget build(BuildContext context) {
    final data = BusinessData.of(context);
    final p = context.loyi;
    final l = context.l10n;
    final groups = [
      (Audience.slipping, LoyiIcons.clock, l.pitchSlipping),
      (Audience.almost, LoyiIcons.target, l.pitchAlmost),
      (Audience.reward, LoyiIcons.gift, l.pitchReward),
      (Audience.newcomers, LoyiIcons.hand, l.pitchNew),
    ];
    final cards = data.cards;
    final programs = data.programById;
    final now = DateTime.now();
    final tones = [(p.accentSoft, p.accent), (p.mintSoft, p.mint), (p.sunSoft, p.onSunSoft), (p.surface, p.ink)];
    return Panel(
      muted: true,
      radius: Radii.xl,
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, c) {
          final columns = c.maxWidth >= 860 ? 4 : 2;
          const gap = 12.0;
          final width = (c.maxWidth - gap * (columns - 1)) / columns;
          final roomy = width >= 200;
          return GridRows(
            columns: columns,
            gap: gap,
            children: [
              for (final (i, (audience, icon, pitch)) in groups.indexed)
                SizedBox(
                  width: width,
                  child: Panel(
                    padding: EdgeInsets.all(roomy ? 18 : 14),
                    onTap: () => showMessageComposer(context, audience: audience),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconBadge(icon: icon, background: tones[i].$1, foreground: tones[i].$2, size: 36),
                            const Spacer(),
                            if (cards == null)
                              const Skeleton(width: 32, height: 28, radius: 8)
                            else
                              Text(
                                '${reach(cards, programs, audience, null, now)}',
                                style: context.text.headlineMedium,
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(audience.label(l), style: context.text.titleMedium, maxLines: 2),
                        if (roomy) ...[
                          const SizedBox(height: 2),
                          Text(pitch, style: context.text.bodySmall, maxLines: 3),
                        ],
                        const SizedBox(height: 12),
                        const Spacer(), // the link sits at the bottom of every card in the row
                        Row(
                          children: [
                            Text(
                              roomy ? l.writeAMessage : l.message,
                              style: context.text.labelMedium?.copyWith(color: p.accent),
                            ),
                            const SizedBox(width: 4),
                            Icon(LoyiIcons.arrowRight, size: 15, color: p.accent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String relativeTime(L10n l, DateTime t) {
  final now = DateTime.now();
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return l.justNow;
  if (diff.inMinutes < 60) return l.minutesAgo(diff.inMinutes);
  if (now.year == t.year && now.month == t.month && now.day == t.day) return l.todayAt(DateFormat.Hm().format(t));
  return DateFormat('d MMM · HH:mm').format(t);
}

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.stamps, required this.redemptions});

  final Stream<List<ActivityItem>> stamps;
  final Stream<List<ActivityItem>> redemptions;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    final data = BusinessData.of(context);
    final names = {for (final pr in data.programs ?? const <Program>[]) pr.id: pr.name};
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
                  IconBadge(icon: LoyiIcons.nfc, background: p.surfaceMuted, foreground: p.inkMuted),
                  const SizedBox(width: 14),
                  Expanded(child: Text(context.l10n.activityEmpty, style: context.text.bodyMedium)),
                ],
              ),
            );
          }
          final shown = items.take(12).toList();
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
                          icon: item.isRedemption ? LoyiIcons.gift : LoyiIcons.stamp,
                          background: item.isRedemption ? p.sunSoft : p.mintSoft,
                          foreground: item.isRedemption ? p.onSunSoft : p.mint,
                          size: 40,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.isRedemption
                                    ? context.l10n.activityReward(item.rewardTitle ?? '')
                                    : context.l10n.activityStamp,
                                style: context.text.titleSmall,
                              ),
                              Text(
                                [
                                  if (item.clientUid.isNotEmpty) clientCode(data.business.id, item.clientUid),
                                  names[item.programId] ?? '',
                                ].join(' · '),
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(relativeTime(context.l10n, item.at), style: context.text.bodySmall),
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
