import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api.dart';
import '../services/billing.dart';
import '../services/language.dart';
import '../theme.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/ui.dart';

/// Loyi admin, preparing a starter kit: the tag just tapped goes to a shop's
/// card (or a first card made here), so the kit works the moment it arrives.
/// Shown on `/k` when the billing server says the signed-in user is an admin.
class KitAdminForm extends StatefulWidget {
  const KitAdminForm({super.key, required this.e, required this.c});

  final String e;
  final String c;

  @override
  State<KitAdminForm> createState() => _KitAdminFormState();
}

/// "New card" in the card list.
const _newCard = '';

class _KitAdminFormState extends State<KitAdminForm> {
  late final Future<List<AdminShop>> _shops = billing.adminShops();
  final _search = TextEditingController();
  final _label = TextEditingController(text: l10n.defaultStampTagLabel);
  final _cardName = TextEditingController(text: l10n.adminDefaultCardName);
  final _stamps = TextEditingController(text: '10');
  final _reward = TextEditingController();
  AdminShop? _shop;
  String? _programId;
  TagType _type = TagType.stamp;
  bool _busy = false;
  String? _error;
  AdminShop? _linkedTo;

  @override
  void dispose() {
    for (final c in [_search, _label, _cardName, _stamps, _reward]) {
      c.dispose();
    }
    super.dispose();
  }

  void _pick(AdminShop shop) => setState(() {
    _shop = shop;
    _programId = shop.programs.isEmpty ? _newCard : shop.programs.first.id;
    _error = null;
  });

  void _setType(TagType type) {
    final defaults = {l10n.defaultJoinTagLabel, l10n.defaultStampTagLabel, ''};
    setState(() {
      _type = type;
      if (defaults.contains(_label.text.trim())) {
        _label.text = type == TagType.join ? l10n.defaultJoinTagLabel : l10n.defaultStampTagLabel;
      }
    });
  }

  Future<void> _link() async {
    final shop = _shop!;
    final newCard = _programId == _newCard;
    final stamps = int.tryParse(_stamps.text.trim());
    if (newCard &&
        (_cardName.text.trim().isEmpty || _reward.text.trim().isEmpty || stamps == null || stamps < 1 || stamps > 50)) {
      setState(() => _error = l10n.fieldRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final label = _label.text.trim();
      await billing.adminKitLink(
        e: widget.e,
        c: widget.c,
        programId: newCard ? null : _programId,
        newCard: newCard
            ? {
                'businessId': shop.businessId,
                'name': _cardName.text.trim(),
                'stampsRequired': stamps!,
                'reward': _reward.text.trim(),
              }
            : null,
        type: _type.name,
        label: label.isEmpty ? (_type == TagType.join ? l10n.defaultJoinTagLabel : l10n.defaultStampTagLabel) : label,
      );
      if (mounted) setState(() => _linkedTo = shop);
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
    final linked = _linkedTo;
    if (linked != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: IconBadge(icon: LoyiIcons.shieldCheck, background: p.mintSoft, foreground: p.mint, size: 72),
          ),
          const SizedBox(height: 20),
          Text(l.adminLinked(linked.name), style: context.text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Panel(
            color: p.surfaceMuted,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.adminShipTo, style: context.text.labelMedium),
                const SizedBox(height: 4),
                SelectableText(
                  [
                    if (linked.legalName.isNotEmpty) linked.legalName,
                    linked.address.isEmpty ? l.adminNoDetails : linked.address,
                    if (linked.phone.isNotEmpty) linked.phone,
                  ].join('\n'),
                  style: context.text.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l.adminNextTag, style: context.text.bodyMedium, textAlign: TextAlign.center),
        ],
      );
    }

    return FutureBuilder<List<AdminShop>>(
      future: _shops,
      builder: (context, snap) {
        if (snap.hasError) {
          return Text(friendlyError(snap.error!), style: context.text.bodyMedium, textAlign: TextAlign.center);
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final shops = snap.data!.where((s) => s.matches(_search.text)).toList();
        final shop = _shop;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: IconBadge(icon: LoyiIcons.nfc, background: p.sunSoft, foreground: p.ink, size: 72),
            ),
            const SizedBox(height: 20),
            Text(l.adminKitTitle, style: context.text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(l.adminKitSub, style: context.text.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (shop == null) ...[
              TextField(
                controller: _search,
                decoration: InputDecoration(labelText: l.adminSearchShops, prefixIcon: const Icon(LoyiIcons.search)),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              if (shops.isEmpty) Text(l.adminNoShops, style: context.text.bodyMedium, textAlign: TextAlign.center),
              for (final s in shops.take(30)) ...[
                Panel(
                  onTap: () => _pick(s),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: context.text.titleSmall),
                            Text(
                              [if (s.legalName.isNotEmpty) s.legalName, if (s.city.isNotEmpty) s.city].join(' · '),
                              style: context.text.bodySmall,
                            ),
                            Text(
                              '${s.trial
                                  ? l.adminTrial
                                  : s.subscribed
                                  ? l.adminActive
                                  : l.adminNotSubscribed}'
                              ' · ${l.adminTags(s.secureTags)}',
                              style: context.text.labelSmall?.copyWith(color: p.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LoyiIcons.chevronRight),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ] else ...[
              Panel(
                color: p.surfaceMuted,
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(child: Text(shop.name, style: context.text.titleSmall)),
                    TextButton(onPressed: () => setState(() => _shop = null), child: Text(l.adminChange)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _programId,
                decoration: InputDecoration(labelText: l.kitCard),
                items: [
                  for (final x in shop.programs) DropdownMenuItem(value: x.id, child: Text(x.name)),
                  DropdownMenuItem(value: _newCard, child: Text(l.adminNewCard)),
                ],
                onChanged: (v) => setState(() => _programId = v),
              ),
              if (_programId == _newCard) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _cardName,
                  maxLength: 60,
                  decoration: InputDecoration(labelText: l.adminCardName, counterText: ''),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _stamps,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.adminStamps),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reward,
                  maxLength: 80,
                  decoration: InputDecoration(labelText: l.adminReward, counterText: ''),
                ),
              ],
              const SizedBox(height: 16),
              SegmentedButton<TagType>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: TagType.stamp, icon: const Icon(LoyiIcons.stamp), label: Text(l.tagTypeStamp)),
                  ButtonSegment(value: TagType.join, icon: const Icon(LoyiIcons.userPlus), label: Text(l.tagTypeJoin)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => _setType(s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _label,
                maxLength: 40,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l.whereIsTag, counterText: ''),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: context.text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _link,
                child: _busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(l.adminLinkTo(shop.name)),
              ),
            ],
          ],
        );
      },
    );
  }
}
