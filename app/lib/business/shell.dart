import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../services/auth_service.dart';
import '../services/language.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/loyalty_card_view.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/ui.dart';
import 'business_scope.dart';
import 'onboarding.dart';
import 'subscribe_page.dart';

/// The business app around the tabs: sign-up steps until the shop is set up and
/// paid, then a sidebar (wide screens) or bottom bar (phones) with the tabs.
class BusinessShell extends StatelessWidget {
  const BusinessShell({super.key, required this.location, required this.checkoutDone, required this.child});

  final String location;

  /// Stripe sent the shop back after paying; its webhook follows within seconds.
  final bool checkoutDone;
  final Widget child;

  @override
  Widget build(BuildContext context) => BusinessScope(
    builder: (context, business) {
      if (business == null) return const NameStep();
      if (business.colors.isEmpty) return ColorsStep(business: business);
      return PlanBuilder(
        builder: (context, status) => switch (status.state) {
          PlanState.loading => const Scaffold(body: Center(child: CircularProgressIndicator())),
          PlanState.active => _ShellFrame(
            key: ValueKey(business.id),
            business: business,
            location: location,
            child: child,
          ),
          PlanState.activating => const ActivatingStep(),
          PlanState.none || PlanState.expired when checkoutDone => const ActivatingStep(),
          PlanState.none || PlanState.expired => PayStep(status: status),
        },
      );
    },
  );
}

/// The shop's live data, shared by every tab so switching tabs costs no reads.
class BusinessData extends InheritedWidget {
  const BusinessData({
    super.key,
    required this.business,
    required this.uid,
    required this.programs,
    required this.cards,
    required this.activity,
    required super.child,
  });

  final Business business;
  final String uid;

  /// Null while loading.
  final List<Program>? programs;

  /// Every client card of the shop; null while loading.
  final List<LoyaltyCard>? cards;
  final ActivityCache activity;

  Map<String, Program> get programById => {for (final p in programs ?? const <Program>[]) p.id: p};

  static BusinessData of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<BusinessData>()!;

  @override
  bool updateShouldNotify(BusinessData old) =>
      old.business != business || old.programs != programs || old.cards != cards;
}

/// Stamps and rewards of a period, plus the stamp count of the period before.
class ActivityWindow {
  const ActivityWindow({
    required this.days,
    required this.stamps,
    required this.redemptions,
    required this.previousStamps,
    required this.capped,
  });

  final int days;
  final List<ActivityItem> stamps;
  final List<ActivityItem> redemptions;
  final int previousStamps;
  final bool capped;
}

/// Loads activity for the Insights tab and keeps it for a few minutes. A shorter
/// period is cut from a longer one already loaded, so switching costs nothing.
class ActivityCache {
  ActivityCache({required this.uid, required this.businessId});

  final String uid;
  final String businessId;
  final _windows = <int, (DateTime, Future<ActivityWindow>)>{};

  static const _fresh = Duration(minutes: 5);

  static DateTime startOf(int days, DateTime now) =>
      DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));

  Future<ActivityWindow> load(int days, {bool refresh = false}) {
    final now = DateTime.now();
    if (refresh) _windows.clear();
    final own = _windows[days];
    if (own != null && now.difference(own.$1) < _fresh) return own.$2;
    // Cut it from a longer fresh period (the previous-period count still needs a query).
    for (final e in _windows.entries) {
      if (e.key > days && now.difference(e.value.$1) < _fresh) {
        final start = startOf(days, now);
        final future =
            Future.wait([
              e.value.$2,
              repo.countStamps(uid, businessId, start.subtract(Duration(days: days)), start),
            ]).then((r) {
              final w = r[0] as ActivityWindow;
              return ActivityWindow(
                days: days,
                stamps: [
                  for (final s in w.stamps)
                    if (!s.at.isBefore(start)) s,
                ],
                redemptions: [
                  for (final s in w.redemptions)
                    if (!s.at.isBefore(start)) s,
                ],
                previousStamps: r[1] as int,
                capped: w.capped,
              );
            });
        _windows[days] = (now, future);
        return future;
      }
    }
    final start = startOf(days, now);
    final future =
        Future.wait([
          repo.stampsSince(uid, businessId, start),
          repo.redemptionsSince(uid, businessId, start),
          repo.countStamps(uid, businessId, start.subtract(Duration(days: days)), start),
        ]).then((r) {
          final stamps = r[0] as List<ActivityItem>;
          return ActivityWindow(
            days: days,
            stamps: stamps,
            redemptions: r[1] as List<ActivityItem>,
            previousStamps: r[2] as int,
            capped: stamps.length >= Repo.maxInsightEvents,
          );
        });
    _windows[days] = (now, future);
    future.catchError((Object _) {
      _windows.remove(days); // retry next time
      return ActivityWindow(days: days, stamps: const [], redemptions: const [], previousStamps: 0, capped: false);
    });
    return future;
  }
}

class _Tab {
  const _Tab(this.path, this.icon);

  final String path;
  final IconData icon;
}

const _tabs = [
  _Tab('/business', LoyiIcons.layoutDashboard),
  _Tab('/business/clients', LoyiIcons.users),
  _Tab('/business/insights', LoyiIcons.chartLine),
  _Tab('/business/cards', LoyiIcons.walletCards),
  _Tab('/business/settings', LoyiIcons.settings),
];

String _tabLabel(L10n l, int i) => [l.tabOverview, l.tabClients, l.tabInsights, l.tabCards, l.tabSettings][i];

int _tabIndex(String location) {
  for (var i = _tabs.length - 1; i > 0; i--) {
    if (location.startsWith(_tabs[i].path)) return i;
  }
  return 0;
}

/// Wide enough for the sidebar instead of the bottom bar.
bool wideLayout(BuildContext context) => MediaQuery.sizeOf(context).width >= 960;

class _ShellFrame extends StatefulWidget {
  const _ShellFrame({super.key, required this.business, required this.location, required this.child});

  final Business business;
  final String location;
  final Widget child;

  @override
  State<_ShellFrame> createState() => _ShellFrameState();
}

class _ShellFrameState extends State<_ShellFrame> {
  late final String _uid = auth.user!.uid;
  late final ActivityCache _activity = ActivityCache(uid: _uid, businessId: widget.business.id);
  final _subs = <StreamSubscription<Object?>>[];
  List<Program>? _programs;
  List<LoyaltyCard>? _cards;

  @override
  void initState() {
    super.initState();
    _subs
      ..add(repo.programsForBusiness(widget.business.id).listen((p) => setState(() => _programs = p), onError: (_) {}))
      ..add(repo.cardsForBusiness(_uid, widget.business.id).listen((c) => setState(() => _cards = c), onError: (_) {}));
    // Storage limitation: drop old log entries and cards nobody used for the retention period.
    unawaited(repo.applyRetention(_uid, widget.business.id).catchError((Object _) {}));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = _tabIndex(widget.location);
    void go(int i) => context.go(_tabs[i].path);
    final body = BusinessData(
      business: widget.business,
      uid: _uid,
      programs: _programs,
      cards: _cards,
      activity: _activity,
      child: widget.child,
    );
    if (wideLayout(context)) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(business: widget.business, selected: index, onSelect: go),
            Expanded(child: body),
          ],
        ),
      );
    }
    final p = context.loyi;
    return Scaffold(
      body: body,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.line)),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: go,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final (i, t) in _tabs.indexed)
              NavigationDestination(icon: Icon(t.icon), label: _tabLabel(context.l10n, i)),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.business, required this.selected, required this.onSelect});

  final Business business;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return Container(
      width: 252,
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        border: Border(right: BorderSide(color: p.line.withValues(alpha: 0.6))),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(padding: EdgeInsets.only(left: 12, bottom: 28), child: LoyiWordmark(size: 30)),
              for (final (i, t) in _tabs.indexed)
                _NavItem(
                  icon: t.icon,
                  label: _tabLabel(context.l10n, i),
                  selected: i == selected,
                  onTap: () => onSelect(i),
                ),
              const Spacer(),
              _NavItem(
                icon: LoyiIcons.shieldCheck,
                label: context.l10n.accountAndPrivacy,
                selected: false,
                onTap: () => context.go('/business/account'),
              ),
              const SizedBox(height: 10),
              Panel(
                padding: const EdgeInsets.all(12),
                radius: Radii.md,
                onTap: () => onSelect(_tabs.length - 1),
                child: Row(
                  children: [
                    BusinessLogo(logo: business.logo, name: business.name, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(business.name, style: context.text.titleSmall, overflow: TextOverflow.ellipsis),
                          Text(auth.user?.email ?? '', style: context.text.bodySmall, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? p.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: selected ? p.panelShadow : null,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: selected ? p.accent : p.inkMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label, style: context.text.labelLarge?.copyWith(color: selected ? p.ink : p.inkMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Scrollable tab content with the page header, capped in width.
class TabPage extends StatelessWidget {
  const TabPage({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.actions = const [],
    required this.children,
    this.onRefresh,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final wide = wideLayout(context);
    final list = ListView(
      padding: EdgeInsets.fromLTRB(wide ? 40 : 20, wide ? 36 : 12, wide ? 40 : 20, 48),
      children: [
        PageBody(
          maxWidth: 1080,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eyebrow != null) ...[Eyebrow(eyebrow!), const SizedBox(height: 8)],
                        Text(
                          title,
                          style: wide ? context.text.displaySmall : context.text.headlineLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(subtitle!, style: context.text.bodyMedium),
                        ],
                      ],
                    ),
                  ),
                  ...actions.map((a) => Padding(padding: const EdgeInsets.only(left: 8), child: a)),
                  if (!wide) ...[
                    const SizedBox(width: 8),
                    RoundIconButton(
                      icon: LoyiIcons.account,
                      tooltip: context.l10n.accountAndPrivacy,
                      onPressed: () => context.go('/business/account'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ],
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list),
      ),
    );
  }
}
