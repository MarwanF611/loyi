import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../services/billing.dart';
import '../services/language.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/ui.dart';
import 'tap_page.dart';

/// Landing page for `/k?e=…&c=…`, the one-time link a secure Loyi tag (starter
/// kit) writes at every tap. The billing server checks it; a linked tag then
/// works like `/t/<tagId>`, with a ticket for stamps. A tag that isn't linked
/// yet can be linked here by its shop.
class KitTapPage extends StatefulWidget {
  const KitTapPage({super.key, required this.e, required this.c});

  final String e;
  final String c;

  @override
  State<KitTapPage> createState() => _KitTapPageState();
}

class _KitTapPageState extends State<KitTapPage> {
  String? _error;
  KitTap? _unlinked;

  @override
  void initState() {
    super.initState();
    _tap();
  }

  Future<void> _tap() async {
    setState(() => _error = null);
    try {
      await auth.ensureClientSession();
      final kit = await billing.kitTap(widget.e, widget.c);
      if (!kit.linked) {
        if (mounted) setState(() => _unlinked = kit);
        return;
      }
      final result = await api.tap(kit.tagId!, ticketId: kit.ticketId);
      if (mounted) context.go('/c/${result.cardId}', extra: result);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlinked = _unlinked;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: PageBody(
              maxWidth: 420,
              child: _error != null
                  ? _Message(
                      icon: LoyiIcons.nfc,
                      title: context.l10n.thatDidntWorkTitle,
                      body: _error!,
                      action: TextButton(onPressed: () => context.go('/cards'), child: Text(context.l10n.goToMyCards)),
                    )
                  : unlinked == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const TapPulse(),
                        const SizedBox(height: 28),
                        Text(context.l10n.addingToCard, style: context.text.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text(context.l10n.onlyAMoment, style: context.text.bodyMedium),
                      ],
                    )
                  : unlinked.canLink
                  ? _LinkForm(e: widget.e, c: widget.c)
                  : _Message(
                      icon: LoyiIcons.nfc,
                      title: context.l10n.kitNewTagTitle,
                      body: '${context.l10n.kitNewTagClient}\n\n${context.l10n.kitShopSignIn}',
                      action: OutlinedButton(
                        onPressed: () => context.go('/business/login'),
                        child: Text(context.l10n.signIn),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body, required this.action});

  final IconData icon;
  final String title;
  final String body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: IconBadge(icon: icon, background: p.accentSoft, foreground: p.accent, size: 72),
        ),
        const SizedBox(height: 20),
        Text(title, style: context.text.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(body, style: context.text.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 28),
        action,
      ],
    );
  }
}

/// The shop links a new Loyi tag to a card. A shop has one tag: a client's first
/// tap adds the card with a first stamp, every next tap gives a stamp (a stamp tag).
class _LinkForm extends StatefulWidget {
  const _LinkForm({required this.e, required this.c});

  final String e;
  final String c;

  @override
  State<_LinkForm> createState() => _LinkFormState();
}

class _LinkFormState extends State<_LinkForm> {
  late final Stream<List<Program>> _programs = repo
      .businessForOwner(auth.user!.uid)
      .asyncExpand((b) => b == null ? Stream.value(const <Program>[]) : repo.programsForBusiness(b.id));
  String? _programId;
  bool _busy = false;
  String? _error;
  String? _linkedProgramId;

  Future<void> _link(String programId) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await billing.kitLink(
        e: widget.e,
        c: widget.c,
        programId: programId,
        type: TagType.stamp.name,
        label: l10n.defaultStampTagLabel,
      );
      if (mounted) setState(() => _linkedProgramId = programId);
    } on FirebaseAuthException catch (_) {
      if (mounted) setState(() => _error = l10n.signInAgain);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    final l = context.l10n;
    if (_linkedProgramId != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: IconBadge(icon: LoyiIcons.shieldCheck, background: p.mintSoft, foreground: p.mint, size: 72),
          ),
          const SizedBox(height: 20),
          Text(l.kitLinked, style: context.text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(l.kitLinkedSub, style: context.text.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 28),
          FilledButton(onPressed: () => context.go('/business/programs/$_linkedProgramId'), child: Text(l.kitOpenCard)),
        ],
      );
    }
    return StreamBuilder<List<Program>>(
      stream: _programs,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final programs = snap.data!;
        if (programs.isEmpty) {
          return _Message(
            icon: LoyiIcons.walletCards,
            title: l.kitNewTagTitle,
            body: l.kitNoCards,
            action: FilledButton(onPressed: () => context.go('/business/cards'), child: Text(l.tabCards)),
          );
        }
        final programId = programs.any((x) => x.id == _programId) ? _programId! : programs.first.id;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: IconBadge(icon: LoyiIcons.nfc, background: p.accentSoft, foreground: p.accent, size: 72),
            ),
            const SizedBox(height: 20),
            Text(l.kitNewTagTitle, style: context.text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(l.kitNewTagShop, style: context.text.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            // Most shops have one card: nothing to choose then.
            if (programs.length > 1)
              DropdownButtonFormField<String>(
                initialValue: programId,
                decoration: InputDecoration(labelText: l.kitCard),
                items: [for (final x in programs) DropdownMenuItem(value: x.id, child: Text(x.name))],
                onChanged: (v) => setState(() => _programId = v),
              )
            else
              Text(l.kitLinkTo(programs.first.name), style: context.text.titleMedium, textAlign: TextAlign.center),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: context.text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : () => _link(programId),
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(l.kitLink),
            ),
          ],
        );
      },
    );
  }
}
