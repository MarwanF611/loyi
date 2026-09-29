import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/color_picker.dart';
import '../widgets/loyalty_card_view.dart';
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
          RoundIconButton(
            icon: Icons.person_outline_rounded,
            tooltip: 'Account & privacy',
            onPressed: () => context.go('/business/account'),
          ),
          const SizedBox(width: 8),
          RoundIconButton(icon: Icons.logout_rounded, tooltip: 'Sign out', onPressed: auth.signOut),
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
                  Text('Step $step of 3', style: context.text.labelLarge?.copyWith(color: p.accent)),
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
      setState(() => _error = 'Enter your business name.');
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
    title: 'Your business',
    subtitle: 'The name your clients see on their loyalty card.',
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
              labelText: 'Business name',
              hintText: 'e.g. Bakkerij Peeters',
              errorText: _error,
            ),
            onSubmitted: (_) => _busy ? null : _save(),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _save, child: const Text('Continue')),
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
    title: 'Your colours',
    subtitle:
        'Pick up to ${Business.maxBrandColors}: the card, its gradient and the stamps. You can fine-tune each '
        'card later.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoyaltyCardView(
          businessName: widget.business.name,
          programName: 'Loyalty card',
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
                    ? 'Choose at least one colour.'
                    : '${_colors.length} of ${Business.maxBrandColors} chosen. Tap a colour again to remove it.',
                style: context.text.bodySmall,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy || _colors.isEmpty ? null : _save,
                child: const Text('Continue'),
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
    return SetupScaffold(
      step: expired ? null : 3,
      title: expired ? 'Your subscription has ended' : 'Start your subscription',
      subtitle: expired
          ? 'Your tags are paused. Clients keep their stamps and can still use rewards they earned. Renew to open '
                'your dashboard again.'
          : 'Your dashboard opens and your tags work as soon as the payment is confirmed. Cancel anytime.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PlanHero(),
          const SizedBox(height: 16),
          PlanSection(status: status),
        ],
      ),
    );
  }
}

/// Paid; waiting a few seconds for the billing webhook to switch the shop on.
class ActivatingStep extends StatelessWidget {
  const ActivatingStep({super.key});

  @override
  Widget build(BuildContext context) => SetupScaffold(
    title: 'Payment confirmed',
    subtitle: 'Setting up your account. This takes a few seconds.',
    child: const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
  );
}
