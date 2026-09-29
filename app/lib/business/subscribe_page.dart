import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/billing.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/account_widgets.dart';
import '../widgets/ui.dart';

/// Where the business's subscription stands, combining Firestore (what the
/// tags actually follow) with RevenueCat (knows about a purchase immediately).
enum PlanState { loading, none, activating, active, expired }

/// See [PlanState].
class PlanStatus {
  const PlanStatus(this.state, [this.subscription]);

  final PlanState state;
  final Subscription? subscription;
}

/// Streams the signed-in owner's [PlanStatus] to [builder].
class PlanBuilder extends StatelessWidget {
  const PlanBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, PlanStatus status) builder;

  @override
  Widget build(BuildContext context) => StreamBuilder<Subscription?>(
    stream: repo.subscription(auth.user!.uid),
    builder: (context, subSnap) => StreamBuilder<CustomerInfo?>(
      stream: billing.customerInfo,
      builder: (context, infoSnap) {
        if (subSnap.connectionState == ConnectionState.waiting) {
          return builder(context, const PlanStatus(PlanState.loading));
        }
        final sub = subSnap.data;
        if (sub != null && sub.isActive) return builder(context, PlanStatus(PlanState.active, sub));
        // Bought, but the webhook hasn't written Firestore yet (a few seconds).
        if (Billing.isActive(infoSnap.data)) return builder(context, PlanStatus(PlanState.activating, sub));
        return builder(context, PlanStatus(sub == null ? PlanState.none : PlanState.expired, sub));
      },
    ),
  );
}

String _date(DateTime d) => DateFormat('d MMMM y').format(d);

/// Dashboard banner for a payment problem (the store retries during a grace period).
/// Not subscribed at all is handled before the dashboard, in the sign-up flow.
class SubscriptionBanner extends StatelessWidget {
  const SubscriptionBanner({super.key});

  @override
  Widget build(BuildContext context) => PlanBuilder(
    builder: (context, status) {
      if (status.state != PlanState.active || !status.subscription!.billingIssue) return const SizedBox.shrink();
      final p = context.loyi;
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Panel(
          color: p.sunSoft,
          onTap: () => context.go('/business/subscribe'),
          child: Row(
            children: [
              IconBadge(icon: Icons.credit_card_off_rounded, background: p.surface, foreground: p.ink),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment problem', style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    Text('Update your payment method to keep your tags working.', style: context.text.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      );
    },
  );
}

class SubscribePage extends StatelessWidget {
  const SubscribePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Subscription'),
      leading: BackButton(onPressed: () => context.go('/business')),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        PageBody(
          maxWidth: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PlanHero(),
              const SizedBox(height: 16),
              PlanBuilder(builder: (context, status) => PlanSection(status: status)),
            ],
          ),
        ),
      ],
    ),
  );
}

class PlanHero extends StatelessWidget {
  const PlanHero({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    const white = Colors.white;
    Widget perk(String text) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: context.text.bodyMedium?.copyWith(color: white)),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.accent, Color.lerp(p.accent, const Color(0xFF7A1D0C), 0.35)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Loyi for business', style: context.text.headlineMedium?.copyWith(color: white)),
          const SizedBox(height: 6),
          Text(
            'Digital stamp cards your clients actually keep.',
            style: context.text.bodyMedium?.copyWith(color: white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 8),
          perk('Your NFC join and stamp tags, switched on'),
          perk('Unlimited loyalty cards and rewards'),
          perk('Your logo, colours and card design'),
          perk('Live dashboard: clients, stamps and rewards'),
          perk('Nothing for your clients to install'),
        ],
      ),
    );
  }
}

class PlanSection extends StatefulWidget {
  const PlanSection({super.key, required this.status});

  final PlanStatus status;

  @override
  State<PlanSection> createState() => PlanSectionState();
}

class PlanSectionState extends State<PlanSection> {
  late final Future<Package?>? _package = billing.available ? billing.monthlyPackage() : null;
  bool _busy = false;

  Future<void> _run(Future<bool> Function() action, {required String success, String? nothing}) async {
    setState(() => _busy = true);
    try {
      final ok = await action();
      if (!mounted) return;
      final message = ok ? success : nothing;
      if (message != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(billingError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final p = context.loyi;
    switch (status.state) {
      case PlanState.loading:
        return const Skeleton(height: 160, radius: Radii.lg);
      case PlanState.active:
        final sub = status.subscription!;
        final manage = billing.managementUrl;
        return Panel(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconBadge(icon: Icons.verified_rounded, background: p.mintSoft, foreground: p.mint),
                  const SizedBox(width: 14),
                  Expanded(child: Text('You\'re subscribed', style: context.text.titleLarge)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                sub.expiresAt.year >= 9999
                    ? 'Your tags are live.'
                    : sub.store == null
                    ? 'Your tags are live until ${_date(sub.expiresAt)}.'
                    : sub.willRenew
                    ? 'Your tags are live. Renews on ${_date(sub.expiresAt)}.'
                    : 'Your tags are live until ${_date(sub.expiresAt)}. The subscription won\'t renew.',
                style: context.text.bodyMedium,
              ),
              if (manage != null) ...[
                const SizedBox(height: 18),
                OutlinedButton(onPressed: () => openUrl(manage), child: const Text('Manage subscription')),
              ],
            ],
          ),
        );
      case PlanState.activating:
        return Panel(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
              const SizedBox(width: 16),
              Expanded(child: Text('Subscription confirmed. Switching on your tags…', style: context.text.titleMedium)),
            ],
          ),
        );
      case PlanState.none || PlanState.expired:
        if (!billing.available) return _Unavailable(expired: status.state == PlanState.expired);
        return FutureBuilder<Package?>(
          future: _package,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Skeleton(height: 220, radius: Radii.lg);
            final package = snap.data;
            if (package == null) {
              return Panel(
                child: Text(
                  'Subscriptions aren\'t available right now. Please try again later.',
                  style: context.text.bodyMedium,
                ),
              );
            }
            return _Offer(
              package: package,
              busy: _busy,
              onSubscribe: () =>
                  _run(() => billing.purchase(package, email: auth.user?.email), success: 'Welcome to Loyi! Your tags are switching on.'),
              onRestore: () => _run(
                billing.restore,
                success: 'Subscription restored.',
                nothing: 'No active subscription found for this account.',
              ),
            );
          },
        );
    }
  }
}

class _Offer extends StatelessWidget {
  const _Offer({required this.package, required this.busy, required this.onSubscribe, required this.onRestore});

  final Package package;
  final bool busy;
  final VoidCallback onSubscribe;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final price = package.storeProduct.priceString;
    // Renewal terms the stores require next to a subscription's buy button.
    final terms = kIsWeb
        ? '$price per month. Renews automatically every month until you cancel. Cancel anytime '
              'under Subscription → Manage subscription.'
        : defaultTargetPlatform == TargetPlatform.iOS
        ? '$price per month, charged to your Apple Account. The subscription renews automatically '
              'unless you cancel it at least 24 hours before the end of the current period. Manage or '
              'cancel it in your App Store account settings.'
        : '$price per month, charged to your Google Play account. The subscription renews '
              'automatically until you cancel it. Manage or cancel it in Google Play → Subscriptions.';
    return Panel(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Monthly', style: context.text.titleMedium),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: price, style: context.text.displaySmall),
                TextSpan(text: ' / month', style: context.text.bodyLarge),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text('Cancel anytime.', style: context.text.bodySmall),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy ? null : onSubscribe,
            child: busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('Subscribe'),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: busy ? null : onRestore, child: const Text('Restore purchases')),
          const SizedBox(height: 8),
          Text(terms, style: context.text.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          const LegalLinks(),
        ],
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.expired});

  final bool expired;

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          !kIsWeb
              ? 'Subscriptions unavailable'
              : expired
              ? 'Renew in the Loyi app'
              : 'Subscribe in the Loyi app',
          style: context.text.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          kIsWeb
              ? 'Download Loyi for business on your iPhone or Android phone, sign in with this account and '
                    'subscribe there. Your tags switch on everywhere, including here.'
              : 'Subscriptions aren\'t set up in this build of the app.',
          style: context.text.bodyMedium,
        ),
      ],
    ),
  );
}
