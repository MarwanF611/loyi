import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../services/language.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/account_widgets.dart';
import '../widgets/color_picker.dart';
import '../widgets/loyalty_card_view.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/ui.dart';
import 'subscribe_page.dart';

// Business sign-up after the account exists:
//   1. account + business name (login page; [NameStep] if the shop is missing, e.g. Sign in with Apple)
//   2. brand colours ([ColorsStep])
//   3. payment ([PayStep])
// then the dashboard. Each step is derived from stored data, so leaving and
// signing in later continues where the owner stopped.

/// Layout shared by the sign-up steps: progress, title, and a way out
/// (account & privacy, sign out) so an unpaid account can always be deleted.
class SetupScaffold extends StatelessWidget {
  const SetupScaffold({super.key, this.step, required this.title, required this.subtitle, required this.child});

  /// 1-based step of 3, or null to hide the progress (renewing).
  final int? step;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return Scaffold(
      appBar: AppBar(
        title: const LoyiWordmark(size: 26),
        actions: [
          const LanguageMenu(),
          const SizedBox(width: 4),
          RoundIconButton(
            icon: LoyiIcons.userRound,
            tooltip: context.l10n.accountAndPrivacy,
            onPressed: () => context.go('/business/account'),
          ),
          const SizedBox(width: 8),
          RoundIconButton(icon: LoyiIcons.logOut, tooltip: context.l10n.signOut, onPressed: auth.signOut),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          PageBody(
            maxWidth: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (step != null) ...[
                  Text(context.l10n.stepOf(step!, 3), style: context.text.labelLarge?.copyWith(color: p.accent)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: step! / 3,
                      minHeight: 6,
                      backgroundColor: p.surfaceMuted,
                      color: p.accent,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(title, style: context.text.headlineLarge),
                const SizedBox(height: 8),
                Text(subtitle, style: context.text.bodyMedium),
                const SizedBox(height: 24),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 1 (again): the shop's name, when the account has no shop yet.
class NameStep extends StatefulWidget {
  const NameStep({super.key});

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  final _name = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.l10n.enterBusinessName);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.createBusiness(ownerUid: auth.user!.uid, name: name);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SetupScaffold(
    step: 1,
    title: context.l10n.yourBusiness,
    subtitle: context.l10n.yourBusinessSub,
    child: Panel(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 80,
            autocorrect: false,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: context.l10n.businessName,
              hintText: context.l10n.businessNameHint,
              errorText: _error,
            ),
            onSubmitted: (_) => _busy ? null : _save(),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _save, child: Text(context.l10n.continueAction)),
          // Google and Apple accounts start here without seeing the sign-up form.
          const SizedBox(height: 16),
          Text(context.l10n.continueAgreesToTerms, style: context.text.bodySmall, textAlign: TextAlign.center),
          const LegalLinks(),
        ],
      ),
    ),
  );
}

/// Step 2: up to three brand colours, with a live preview of a card.
class ColorsStep extends StatefulWidget {
  const ColorsStep({super.key, required this.business});

  final Business business;

  @override
  State<ColorsStep> createState() => _ColorsStepState();
}

class _ColorsStepState extends State<ColorsStep> {
  List<int> _colors = [cardPalette.first.toARGB32()];
  bool _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await repo.setBrandColors(widget.business.id, _colors);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SetupScaffold(
    step: 2,
    title: context.l10n.yourColours,
    subtitle: context.l10n.yourColoursSub(Business.maxBrandColors),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoyaltyCardView(
          businessName: widget.business.name,
          programName: context.l10n.loyaltyCard,
          design: CardDesign.fromBrand(_colors.isEmpty ? [cardPalette.first.toARGB32()] : _colors),
          stamps: 3,
          stampsRequired: 8,
        ),
        const SizedBox(height: 20),
        Panel(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MultiColorPicker(values: _colors, onChanged: (c) => setState(() => _colors = c)),
              const SizedBox(height: 12),
              Text(
                _colors.isEmpty
                    ? context.l10n.chooseOneColour
                    : context.l10n.coloursChosen(_colors.length, Business.maxBrandColors),
                style: context.text.bodySmall,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy || _colors.isEmpty ? null : _save,
                child: Text(context.l10n.continueAction),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Step 3: subscribe (or renew after the subscription ended).
class PayStep extends StatelessWidget {
  const PayStep({super.key, required this.status});

  final PlanStatus status;

  @override
  Widget build(BuildContext context) {
    final expired = status.state == PlanState.expired;
    final l = context.l10n;
    return SetupScaffold(
      step: expired ? null : 3,
      title: expired
          ? l.subscriptionEnded
          : kIsWeb
          ? l.startSubscription
          : l.almostThere,
      subtitle: expired
          ? l.tagsPausedSub
          : kIsWeb
          ? l.dashboardOpensWhenPaid
          : l.dashboardOpensWhenActive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (kIsWeb) ...[const PlanHero(), const SizedBox(height: 16)],
          PlanSection(status: status),
        ],
      ),
    );
  }
}

/// Paid; waiting a few seconds for Stripe's webhook to switch the shop on.
class ActivatingStep extends StatefulWidget {
  const ActivatingStep({super.key});

  @override
  State<ActivatingStep> createState() => _ActivatingStepState();
}

class _ActivatingStepState extends State<ActivatingStep> {
  bool _slow = false;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 45), () => setState(() => _slow = true));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SetupScaffold(
    title: context.l10n.paymentReceived,
    subtitle: context.l10n.switchingOn,
    child: Column(
      children: [
        const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
        if (_slow) ...[
          Text(context.l10n.takingLonger, style: context.text.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: () => context.go('/business'), child: Text(context.l10n.backToPayment)),
        ],
      ],
    ),
  );
}
