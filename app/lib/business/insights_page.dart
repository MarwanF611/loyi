import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../services/language.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/ui.dart';
import 'dashboard_page.dart';
import 'insights/analytics.dart';
import 'shell.dart';

/// The Insights tab: trends, busy hours, loyalty and per-card numbers for a period.
/// Everything is counted from anonymous activity; no person is profiled.
class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  int _days = 30;
  Future<ActivityWindow>? _window;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _window ??= BusinessData.of(context).activity.load(_days);
  }

  void _select(int days) => setState(() {
    _days = days;
    _window = BusinessData.of(context).activity.load(days);
  });

  Future<void> _refresh() async {
    final w = BusinessData.of(context).activity.load(_days, refresh: true);
    setState(() => _window = w);
    await w;
  }

  @override
  Widget build(BuildContext context) {
    final data = BusinessData.of(context);
    final wide = wideLayout(context);
    final l = context.l10n;
    final period = SegmentedButton<int>(
      segments: [
        ButtonSegment(value: 7, label: Text(l.days7)),
        ButtonSegment(value: 30, label: Text(l.days30)),
        ButtonSegment(value: 90, label: Text(l.days90)),
      ],
      selected: {_days},
      showSelectedIcon: false,
      onSelectionChanged: (s) => _select(s.first),
    );
    return TabPage(
      eyebrow: l.tabInsights,
      title: l.insightsTitle,
      onRefresh: _refresh,
      actions: [if (wide) period],
      children: [
        if (!wide) ...[Align(alignment: Alignment.centerLeft, child: period), const SizedBox(height: 20)],
        FutureBuilder<ActivityWindow>(
          future: _window,
          builder: (context, snap) {
            if (snap.hasError) {
              return Panel(
                child: Row(
                  children: [
                    const Icon(LoyiIcons.circleAlert),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l.couldNotLoadInsights)),
                    TextButton(onPressed: _refresh, child: Text(l.tryAgain)),
                  ],
                ),
              );
            }
            final w = snap.data;
            final cards = data.cards;
            final programs = data.programs;
            if (w == null || w.days != _days || cards == null || programs == null) return const _Loading();
            final insights = Insights.compute(
              businessId: data.business.id,
              now: DateTime.now(),
              days: _days,
              cards: cards,
              programs: data.programById,
              stamps: w.stamps,
              redemptions: w.redemptions,
              capped: w.capped,
            );
            return _InsightsBody(insights: insights, previousStamps: w.previousStamps);
          },
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      Skeleton(height: 120, radius: Radii.lg),
      SizedBox(height: 16),
      Skeleton(height: 300, radius: Radii.lg),
      SizedBox(height: 16),
      Skeleton(height: 240, radius: Radii.lg),
    ],
  );
}

/// Two widgets side by side on wide screens, stacked on phones.
class _Pair extends StatelessWidget {
  const _Pair(this.a, this.b, {this.flex = (1, 1)});

  final Widget a;
  final Widget b;
  final (int, int) flex;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => c.maxWidth >= 820
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: flex.$1, child: a),
                const SizedBox(width: 16),
                Expanded(flex: flex.$2, child: b),
              ],
            ),
          )
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, const SizedBox(height: 16), b]),
  );
}

/// A white card with a title, an optional note and a chart.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, this.note, this.trailing, required this.child});

  final String title;
  final String? note;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleLarge),
                  if (note != null) ...[const SizedBox(height: 2), Text(note!, style: context.text.bodySmall)],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend(this.items);

  final List<(Color, String)> items;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 14,
    runSpacing: 6,
    children: [
      for (final (c, l) in items)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 6),
            Text(l, style: context.text.bodySmall),
          ],
        ),
    ],
  );
}

class _InsightsBody extends StatelessWidget {
  const _InsightsBody({required this.insights, required this.previousStamps});

  final Insights insights;
  final int previousStamps;

  @override
  Widget build(BuildContext context) {
    final i = insights;
    final p = context.loyi;
    final l = context.l10n;
    final dayLabel = DateFormat('EEE d MMM');
    final dates = [for (var d = 0; d < i.days; d++) i.start.add(Duration(days: d, hours: 12))];
    final weekly = i.days > 14;
    final bucketSize = weekly ? 7 : 1;
    final newPer = bucket(i.newClientsPerDay, bucketSize);
    final redeemPer = bucket(i.redemptionsPerDay, bucketSize);
    final bucketLabels = [
      for (var b = 0; b < newPer.length; b++)
        () {
          final end = dates[(dates.length - 1 - (newPer.length - 1 - b) * bucketSize).clamp(0, dates.length - 1)];
          return weekly ? l.weekTo(DateFormat('d MMM').format(end)) : dayLabel.format(end);
        }(),
    ];
    final axis = [
      for (var b = 0; b < newPer.length; b++)
        weekly
            ? (b == newPer.length - 1 ? l.chartNow : l.weeksAgoShort(newPer.length - 1 - b))
            : bucketLabels[b].substring(0, 1).toUpperCase(),
    ];
    final peak = i.peak;
    final days = [for (var d = 1; d <= 7; d++) DateFormat.E().format(DateTime(2024, 1, d))]; // 1 Jan 2024 = Monday
    final statusOrder = [
      ClientStatus.newcomer,
      ClientStatus.regular,
      ClientStatus.almost,
      ClientStatus.reward,
      ClientStatus.occasional,
      ClientStatus.slipping,
      ClientStatus.lost,
    ];
    final statusColors = [
      p.mint,
      const Color(0xFF0E8A5C),
      p.accent,
      p.sun,
      p.inkMuted.withValues(alpha: 0.5),
      const Color(0xFFB98A6E),
      p.ink.withValues(alpha: 0.75),
    ];
    final totalClients = i.statusCounts.values.fold(0, (a, b) => a + b);
    final pct = NumberFormat.percentPattern();
    final oneDecimal = NumberFormat('0.0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (i.capped) ...[
          Panel(
            color: p.sunSoft,
            padding: const EdgeInsets.all(14),
            child: Text(
              l.busyShop(NumberFormat.decimalPattern().format(Repo.maxInsightEvents)),
              style: context.text.bodySmall?.copyWith(color: p.ink),
            ),
          ),
          const SizedBox(height: 16),
        ],
        KpiGrid(
          tiles: [
            KpiTile(
              icon: LoyiIcons.stamp,
              tone: (p.accentSoft, p.accent),
              label: l.kpiStamps,
              value: i.totalStamps,
              delta: i.capped ? null : change(i.totalStamps, previousStamps),
              note: l.noEarlierData,
            ),
            KpiTile(
              icon: LoyiIcons.users,
              tone: (p.mintSoft, p.mint),
              label: l.kpiActiveClients,
              value: i.activeClients,
              note: l.cameBackCount(i.returningClients),
            ),
            KpiTile(
              icon: LoyiIcons.userPlus,
              tone: (p.surfaceMuted, p.ink),
              label: l.kpiNewClients,
              value: i.newClients,
              note: l.joinedInPeriod,
            ),
            KpiTile(
              icon: LoyiIcons.gift,
              tone: (p.sunSoft, p.onSunSoft),
              label: l.kpiRewardsUsed,
              value: i.totalRedemptions,
              note: l.stillWaitingCount(i.rewardsWaiting),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: l.stampsPerDay,
          note: peak == null
              ? l.stampsAppearHere
              : l.busiestAt(
                  DateFormat.EEEE().format(DateTime(2024, 1, peak.weekday + 1)), // 1 Jan 2024 was a Monday
                  DateFormat.Hm().format(DateTime(2024, 1, 1, peak.hour)),
                ),
          child: AreaChart(
            values: i.stampsPerDay,
            labels: [for (final d in dates) dayLabel.format(d)],
            describe: l.stampsCount,
            semanticLabel: l.stampsPerDaySemantic(i.days, i.totalStamps),
          ),
        ),
        const SizedBox(height: 16),
        _Pair(
          _ChartCard(
            title: l.kpiNewClients,
            note: weekly ? l.perWeek : l.perDay,
            trailing: _Legend([(p.mint, l.legendNew)]),
            child: StackedBarChart(
              series: [newPer],
              describe: [l.newClientsCount],
              colors: [p.mint],
              labels: bucketLabels,
              axisLabels: axis,
              semanticLabel: l.newClientsSemantic(newPer.join(', ')),
            ),
          ),
          _ChartCard(
            title: l.kpiRewardsUsed,
            note: weekly ? l.perWeek : l.perDay,
            trailing: _Legend([(p.sun, l.legendRewards)]),
            child: StackedBarChart(
              series: [redeemPer],
              describe: [l.rewardsCount],
              colors: [p.sun],
              labels: bucketLabels,
              axisLabels: axis,
              semanticLabel: l.rewardsUsedSemantic(redeemPer.join(', ')),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: l.busyTimes,
          note: l.busyTimesNote,
          child: Heatmap(grid: i.heatmap, dayNames: days),
        ),
        const SizedBox(height: 16),
        _Pair(
          flex: (2, 3),
          _ChartCard(
            title: l.clientMix,
            note: l.clientMixNote(NumberFormat.decimalPattern().format(totalClients)),
            child: Column(
              children: [
                Donut(
                  values: [for (final s in statusOrder) i.statusCounts[s] ?? 0],
                  colors: statusColors,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$totalClients', style: context.text.headlineMedium),
                      Text(l.clientsWord, style: context.text.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _Legend([
                  for (final (k, s) in statusOrder.indexed)
                    if ((i.statusCounts[s] ?? 0) > 0) (statusColors[k], '${s.label(l)} ${i.statusCounts[s]}'),
                ]),
              ],
            ),
          ),
          _ChartCard(
            title: l.loyalty,
            note: l.loyaltyNote,
            child: Column(
              children: [
                _Metric(
                  icon: LoyiIcons.repeat,
                  label: l.cameBackAfterFirst,
                  value: i.returnRate == null ? '–' : pct.format(i.returnRate),
                  hint: l.cameBackAfterFirstHint,
                ),
                _Metric(
                  icon: LoyiIcons.stamp,
                  label: l.visitsPerActive,
                  value: i.activeClients == 0 ? '–' : oneDecimal.format(i.visitsPerClient),
                  hint: l.inThisPeriod,
                ),
                _Metric(
                  icon: LoyiIcons.calendarDays,
                  label: l.daysBetweenVisits,
                  value: i.daysBetweenVisits == null ? '–' : oneDecimal.format(i.daysBetweenVisits),
                  hint: l.daysBetweenVisitsHint,
                ),
                _Metric(
                  icon: LoyiIcons.hourglass,
                  label: l.rewardsWaitingToUse,
                  value: '${i.rewardsWaiting}',
                  hint: l.rewardsWaitingToUseHint,
                  last: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final pi in i.perProgram)
          if (i.progress[pi.program.id] case final dist?) ...[
            _ChartCard(
              title: pi.program.name,
              note: l.programInsightNote(pi.clients, pi.stamps, pi.redemptions),
              child: StackedBarChart(
                height: 170,
                series: [dist],
                describe: [l.clientsCount],
                colors: [p.accent],
                labels: [for (var s = 0; s < dist.length; s++) l.stampsOfRequiredShort(s, pi.program.stampsRequired)],
                axisLabels: [for (var s = 0; s < dist.length; s++) '$s'],
                semanticLabel: l.programDistributionSemantic(pi.program.name, dist.join(', ')),
              ),
            ),
            const SizedBox(height: 16),
          ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LoyiIcons.shieldCheck, size: 18, color: p.mint),
            const SizedBox(width: 10),
            Expanded(child: Text(l.insightsPrivacyNote, style: context.text.bodySmall)),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go('/business/clients'),
            icon: const Icon(LoyiIcons.users, size: 18),
            label: Text(l.seeClients),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value, required this.hint, this.last = false});

  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: p.line)),
      ),
      child: Row(
        children: [
          IconBadge(icon: icon, background: p.surfaceMuted, foreground: p.ink, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.titleSmall),
                Text(hint, style: context.text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: context.text.headlineSmall),
        ],
      ),
    );
  }
}
