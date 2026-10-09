import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'business/account_page.dart';
import 'business/cards_page.dart';
import 'business/clients_page.dart';
import 'business/dashboard_page.dart';
import 'business/insights_page.dart';
import 'business/login_page.dart';
import 'business/program_page.dart';
import 'business/settings_page.dart';
import 'business/shell.dart';
import 'business/subscribe_page.dart';
import 'client/account_pages.dart';
import 'client/card_page.dart';
import 'client/demo_page.dart';
import 'client/kit_tap_page.dart';
import 'client/my_cards_page.dart';
import 'client/redeemed_page.dart';
import 'client/tap_page.dart';
import 'services/api.dart';
import 'services/auth_service.dart';

/// Rebuilds routes when the signed-in user changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh() {
    auth.userChanges.listen((_) => notifyListeners());
  }
}

GoRouter buildRouter() => GoRouter(
  navigatorKey: _root,
  // Web is mostly reached through tag URLs; native builds are the business app.
  initialLocation: kIsWeb ? null : '/business',
  refreshListenable: _AuthRefresh(),
  redirect: (context, state) {
    final path = state.matchedLocation;
    final business = auth.isBusinessUser;
    if (path.startsWith('/business') && path != '/business/login' && !business) return '/business/login';
    if (path == '/business/login' && business) return '/business';
    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (_, _) => '/cards'),

    // ── Clients (web) ──────────────────────────────────────────────────────
    GoRoute(
      path: '/t/:tagId',
      builder: (_, s) => TapPage(tagId: s.pathParameters['tagId']!),
    ),
    // Secure tags (starter kit) write a new one-time link at every tap.
    GoRoute(
      path: '/k',
      builder: (_, s) => KitTapPage(e: s.uri.queryParameters['e'] ?? '', c: s.uri.queryParameters['c'] ?? ''),
    ),
    // Try-it card for the website: no account, nothing saved.
    GoRoute(path: '/demo', builder: (_, _) => const DemoPage()),
    GoRoute(path: '/cards', builder: (_, _) => const MyCardsPage()),
    GoRoute(
      path: '/c/:cardId',
      builder: (_, s) => CardPage(cardId: s.pathParameters['cardId']!, tapResult: s.extra as TapResult?),
    ),
    GoRoute(
      path: '/redeemed',
      redirect: (_, s) => s.extra is RedeemedArgs ? null : '/cards',
      builder: (_, s) => RedeemedPage(args: s.extra! as RedeemedArgs),
    ),
    GoRoute(path: '/account', builder: (_, _) => const AccountPage()),

    // ── Businesses ─────────────────────────────────────────────────────────
    GoRoute(
      path: '/business/login',
      builder: (_, s) => BusinessLoginPage(signUp: s.uri.queryParameters['signup'] == '1'),
    ),
    ShellRoute(
      builder: (_, s, child) =>
          BusinessShell(location: s.uri.path, checkoutDone: s.uri.queryParameters['checkout'] == 'done', child: child),
      routes: [
        GoRoute(
          path: '/business',
          pageBuilder: (_, s) => _tab(s, const OverviewPage()),
          routes: [
            GoRoute(path: 'clients', pageBuilder: (_, s) => _tab(s, const ClientsPage())),
            GoRoute(path: 'insights', pageBuilder: (_, s) => _tab(s, const InsightsPage())),
            GoRoute(path: 'cards', pageBuilder: (_, s) => _tab(s, const CardsPage())),
            GoRoute(path: 'settings', pageBuilder: (_, s) => _tab(s, const BusinessSettingsPage())),
            // Full-screen pages, above the tabs (and reachable while the shop isn't paid yet).
            GoRoute(path: 'subscribe', parentNavigatorKey: _root, builder: (_, _) => const SubscribePage()),
            GoRoute(path: 'account', parentNavigatorKey: _root, builder: (_, _) => const BusinessAccountPage()),
            GoRoute(path: 'programs/new', parentNavigatorKey: _root, builder: (_, _) => const ProgramPage()),
            GoRoute(
              path: 'programs/:programId',
              parentNavigatorKey: _root,
              builder: (_, s) => ProgramPage(programId: s.pathParameters['programId']!),
            ),
          ],
        ),
      ],
    ),
  ],
);

final _root = GlobalKey<NavigatorState>();

/// Tabs swap with a quick fade instead of a slide.
Page<void> _tab(GoRouterState state, Widget child) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 180),
  transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
);
