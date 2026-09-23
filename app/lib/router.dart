import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'business/dashboard_page.dart';
import 'business/login_page.dart';
import 'business/program_page.dart';
import 'client/account_pages.dart';
import 'client/card_page.dart';
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
    GoRoute(path: '/account/finish', builder: (_, _) => const FinishAccountPage()),

    // ── Businesses ─────────────────────────────────────────────────────────
    GoRoute(path: '/business/login', builder: (_, _) => const BusinessLoginPage()),
    GoRoute(
      path: '/business',
      builder: (_, _) => const DashboardPage(),
      routes: [
        GoRoute(path: 'programs/new', builder: (_, _) => const ProgramPage()),
        GoRoute(
          path: 'programs/:programId',
          builder: (_, s) => ProgramPage(programId: s.pathParameters['programId']!),
        ),
      ],
    ),
  ],
);
