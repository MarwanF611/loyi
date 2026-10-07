import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../config.dart';
import '../models.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../services/billing.dart';
import '../services/language.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/account_widgets.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/ui.dart';

/// Where the business's subscription stands (`subscriptions/{uid}`, written by
/// the billing server). `activating`: back from Stripe, waiting for its webhook.
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
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return builder(context, const PlanStatus(PlanState.loading));
      final sub = snap.data;
      if (sub != null && sub.isActive) return builder(context, PlanStatus(PlanState.active, sub));
      return builder(context, PlanStatus(sub == null ? PlanState.none : PlanState.expired, sub));
    },
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
              IconBadge(icon: LoyiIcons.creditCard, background: p.surface, foreground: p.ink),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.paymentProblem, style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    Text(context.l10n.paymentProblemSub, style: context.text.bodySmall),
                  ],
                ),
              ),
              const Icon(LoyiIcons.chevronRight),
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
      title: Text(context.l10n.subscription),
      leading: BackButton(onPressed: () => context.go('/business/settings')),
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
          const Icon(LoyiIcons.circleCheck, color: white, size: 20),
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
          Text(context.l10n.loyiForBusiness, style: context.text.headlineMedium?.copyWith(color: white)),
          const SizedBox(height: 6),
          Text(
            context.l10n.planTagline,
            style: context.text.bodyMedium?.copyWith(color: white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 8),
          perk(context.l10n.perkTags),
          perk(context.l10n.perkUnlimited),
          perk(context.l10n.perkBrand),
          perk(context.l10n.perkDashboard),
          perk(context.l10n.perkNoInstall),
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
  bool _busy = false;

  /// Runs [action] (which leaves for Stripe on success); shows the error otherwise.
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final p = context.loyi;
    final l = context.l10n;
    switch (status.state) {
      case PlanState.loading:
        return const Skeleton(height: 160, radius: Radii.lg);
      case PlanState.active:
        final sub = status.subscription!;
        return Panel(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconBadge(icon: LoyiIcons.badgeCheck, background: p.mintSoft, foreground: p.mint),
                  const SizedBox(width: 14),
                  Expanded(child: Text(l.youreSubscribed, style: context.text.titleLarge)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                sub.expiresAt.year >= 9999
                    ? l.tagsLive
                    : sub.store == null
                    ? l.tagsLiveUntil(_date(sub.expiresAt))
                    : sub.billingIssue
                    ? l.lastPaymentFailed(_date(sub.expiresAt))
                    : sub.willRenew
                    ? l.renewsOn(_date(sub.expiresAt))
                    : l.wontRenew(_date(sub.expiresAt)),
                style: context.text.bodyMedium,
              ),
              if (sub.store == 'stripe' && billing.canManageHere) ...[
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(billing.openPortal),
                  child: Text(l.manageSubscription),
                ),
                const SizedBox(height: 6),
                Text(l.manageSubscriptionSub, style: context.text.bodySmall, textAlign: TextAlign.center),
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
              Expanded(child: Text(l.switchingOnTags, style: context.text.titleMedium)),
            ],
          ),
        );
      case PlanState.none || PlanState.expired:
        if (!kIsWeb) return const _NotActive();
        if (!billing.available) return const _Unavailable();
        return _Offer(busy: _busy, onSubscribe: () => _run(billing.startCheckout));
    }
  }
}

class _Offer extends StatelessWidget {
  const _Offer({required this.busy, required this.onSubscribe});

  final bool busy;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.monthly, style: context.text.titleMedium),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: subscriptionPrice, style: context.text.displaySmall),
              TextSpan(text: context.l10n.perMonthExclVat, style: context.text.bodyLarge),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(context.l10n.cardOrBancontact, style: context.text.bodySmall),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: busy ? null : onSubscribe,
          child: busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : Text(context.l10n.subscribe),
        ),
        const SizedBox(height: 12),
        Text(context.l10n.stripeNote, style: context.text.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        const LegalLinks(),
      ],
    ),
  );
}

/// In the native apps: status only, no way to buy (the subscription is sold on the website).
class _NotActive extends StatelessWidget {
  const _NotActive();

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.noActiveSubscription, style: context.text.titleLarge),
        const SizedBox(height: 8),
        Text(context.l10n.noActiveSubscriptionSub, style: context.text.bodyMedium),
      ],
    ),
  );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(22),
    child: Text(context.l10n.subscriptionsNotSetUp, style: context.text.bodyMedium),
  );
}
