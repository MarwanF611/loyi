import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../services/language.dart';
import '../services/repo.dart';
import '../services/save_file/save_file.dart';
import '../theme.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/ui.dart';
import 'insights/analytics.dart';
import 'messages.dart';
import 'shell.dart';

/// The Clients tab: every card holder as an anonymous code with their status,
/// and the follow-up messages for groups of them.
class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

enum _View { clients, messages }

class _ClientsPageState extends State<ClientsPage> {
  _View _view = _View.clients;
  ClientStatus? _filter;
  String _query = '';
  int _shown = 40;

  Future<void> _export(List<ClientSummary> clients, Rect origin) async {
    final now = DateTime.now();
    final day = DateFormat('yyyy-MM-dd');
    final l = context.l10n;
    String cell(Object? v) => '"${'${v ?? ''}'.replaceAll('"', '""')}"';
    final rows = [
      l.csvHeader.split(','),
      for (final c in clients)
        [
          c.code,
          c.statusAt(now).label(l),
          c.joined == null ? '' : day.format(c.joined!),
          c.lastVisit == null ? '' : day.format(c.lastVisit!),
          c.totalStamps,
          c.rewardsWaiting,
          c.redeemed,
        ],
    ];
    final csv = rows.map((r) => r.map(cell).join(',')).join('\r\n');
    await saveFile(
      'loyi-clients-${day.format(now)}.csv',
      Uint8List.fromList(utf8.encode(csv)),
      mimeType: 'text/csv',
      origin: origin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = BusinessData.of(context);
    final cards = data.cards;
    final now = DateTime.now();
    final l = context.l10n;
    final clients = cards == null ? null : summarizeClients(data.business.id, cards, data.programById);
    final counts = <ClientStatus, int>{};
    for (final c in clients ?? const <ClientSummary>[]) {
      final s = c.statusAt(now);
      counts[s] = (counts[s] ?? 0) + 1;
    }
    final q = _query.trim().toUpperCase().replaceAll('#', '');
    final filtered = [
      for (final c in clients ?? const <ClientSummary>[])
        if ((_filter == null || c.statusAt(now) == _filter) && (q.isEmpty || c.code.contains(q))) c,
    ];
    return TabPage(
      eyebrow: l.tabClients,
      title: l.clientsTitle,
      subtitle: clients == null ? null : l.clientsSubtitle(clients.length),
      actions: [
        if (_view == _View.clients && clients != null && clients.isNotEmpty)
          Builder(
            builder: (context) => IconButton(
              tooltip: l.downloadCsv,
              style: IconButton.styleFrom(backgroundColor: context.loyi.surfaceMuted, fixedSize: const Size(48, 48)),
              onPressed: () {
                final box = context.findRenderObject() as RenderBox?;
                final origin = box == null ? Rect.zero : box.localToGlobal(Offset.zero) & box.size;
                _export(filtered, origin);
              },
              icon: const Icon(LoyiIcons.fileDown, size: 20),
            ),
          ),
        if (_view == _View.messages)
          FilledButton.icon(
            onPressed: () => showMessageComposer(context),
            icon: const Icon(LoyiIcons.plus, size: 18),
            label: Text(l.newShort),
          ),
      ],
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<_View>(
            segments: [
              ButtonSegment(
                value: _View.clients,
                icon: const Icon(LoyiIcons.users, size: 18),
                label: Text(l.tabClients),
              ),
              ButtonSegment(
                value: _View.messages,
                icon: const Icon(LoyiIcons.megaphone, size: 18),
                label: Text(l.messages),
              ),
            ],
            selected: {_view},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _view = s.first),
          ),
        ),
        const SizedBox(height: 20),
        if (_view == _View.messages)
          const MessagesList()
        else ...[
          const _PrivacyNote(),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: l.filterAll,
                  count: clients?.length,
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final s in ClientStatus.values)
                  if ((counts[s] ?? 0) > 0)
                    _FilterChip(
                      label: s.label(l),
                      count: counts[s],
                      selected: _filter == s,
                      onTap: () => setState(() => _filter = _filter == s ? null : s),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            decoration: InputDecoration(hintText: l.findClientHint, prefixIcon: const Icon(LoyiIcons.search, size: 20)),
            textCapitalization: TextCapitalization.characters,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 14),
          if (clients == null)
            const Skeleton(height: 280, radius: Radii.lg)
          else if (filtered.isEmpty)
            Panel(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(LoyiIcons.searchX, size: 32, color: context.loyi.inkMuted),
                  const SizedBox(height: 10),
                  Text(clients.isEmpty ? l.clientsEmpty : l.noClientsMatch, style: context.text.bodyMedium),
                ],
              ),
            )
          else ...[
            Panel(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (final (i, c) in filtered.take(_shown).indexed) ...[
                    if (i > 0) const Divider(indent: 72, endIndent: 16),
                    _ClientRow(client: c, now: now),
                  ],
                ],
              ),
            ),
            if (filtered.length > _shown) ...[
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton(
                  onPressed: () => setState(() => _shown += 40),
                  child: Text(l.showMore(filtered.length - _shown)),
                ),
              ),
            ],
          ],
        ],
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    return Panel(
      color: p.mintSoft,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LoyiIcons.shieldCheck, color: p.mint, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(context.l10n.clientsPrivacyNote, style: context.text.bodyMedium?.copyWith(color: p.ink)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.count, required this.selected, required this.onTap});

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(count == null ? label : '$label  $count'),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    ),
  );
}

/// A soft colour per client code, so codes are easy to tell apart.
Color _codeColor(String code) {
  const hues = [8.0, 28.0, 45.0, 150.0, 175.0, 200.0, 260.0, 320.0];
  return HSLColor.fromAHSL(1, hues[code.codeUnits.fold(0, (a, b) => a + b) % hues.length], 0.65, 0.55).toColor();
}

class ClientAvatar extends StatelessWidget {
  const ClientAvatar({super.key, required this.code, this.size = 42});

  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = _codeColor(code);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.16), shape: BoxShape.circle),
      child: Text(
        code.substring(1, 3),
        style: context.eyebrow.copyWith(color: c, fontSize: size * 0.3, letterSpacing: 0),
      ),
    );
  }
}

(Color, Color) statusTone(BuildContext context, ClientStatus s) {
  final p = context.loyi;
  return switch (s) {
    ClientStatus.reward => (p.sunSoft, p.onSunSoft),
    ClientStatus.newcomer || ClientStatus.regular => (p.mintSoft, p.mint),
    ClientStatus.almost => (p.accentSoft, p.onAccentSoft),
    ClientStatus.occasional => (p.surfaceMuted, p.inkMuted),
    ClientStatus.slipping || ClientStatus.lost => (p.surfaceMuted, p.ink),
  };
}

String _ago(L10n l, DateTime? t, DateTime now) {
  if (t == null) return '–';
  final days = DateTime(now.year, now.month, now.day).difference(DateTime(t.year, t.month, t.day)).inDays;
  if (days <= 0) return l.today;
  if (days == 1) return l.yesterday;
  if (days < 30) return l.daysAgo(days);
  return DateFormat('d MMM y').format(t);
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.client, required this.now});

  final ClientSummary client;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final status = client.statusAt(now);
    final tone = statusTone(context, status);
    // The card closest to its next reward.
    double? best;
    for (final c in client.cards) {
      final p = client.programs[c.programId];
      if (p == null) continue;
      final f = c.progressFor(p.stampsRequired).stamps / p.stampsRequired;
      if (best == null || f > best) best = f;
    }
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => showClientDetail(context, client),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ClientAvatar(code: client.code),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(client.code, style: context.text.titleSmall?.copyWith(fontFamily: 'JetBrainsMono')),
                        Pill(label: status.label(context.l10n), background: tone.$1, foreground: tone.$2),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.clientRowSummary(client.totalStamps, _ago(context.l10n, client.lastVisit, now)),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              if (best != null) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: client.rewardsWaiting > 0 ? 1 : best,
                      minHeight: 6,
                      color: client.rewardsWaiting > 0 ? context.loyi.sun : context.loyi.accent,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Icon(LoyiIcons.chevronRight, size: 18, color: context.loyi.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Everything the shop knows about one client: dates and counts, nothing personal.
Future<void> showClientDetail(BuildContext context, ClientSummary client) {
  final data = BusinessData.of(context);
  return showLoyiSheet<void>(
    context,
    builder: (_) => _ClientDetail(client: client, data: data),
  );
}

class _ClientDetail extends StatefulWidget {
  const _ClientDetail({required this.client, required this.data});

  final ClientSummary client;
  final BusinessData data;

  @override
  State<_ClientDetail> createState() => _ClientDetailState();
}

class _ClientDetailState extends State<_ClientDetail> {
  late final Future<List<ActivityItem>> _visits = repo.visitsOfCards(widget.data.uid, [
    for (final c in widget.client.cards) c.id,
  ]);

  @override
  Widget build(BuildContext context) {
    final c = widget.client;
    final p = context.loyi;
    final now = DateTime.now();
    final status = c.statusAt(now);
    final tone = statusTone(context, status);
    final day = DateFormat('d MMM y');
    final l = context.l10n;
    Widget fact(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(label),
          const SizedBox(height: 4),
          Text(value, style: context.text.titleMedium),
        ],
      ),
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClientAvatar(code: c.code, size: 54),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.code, style: context.text.headlineMedium?.copyWith(fontFamily: 'JetBrainsMono')),
                    const SizedBox(height: 4),
                    Pill(label: status.label(context.l10n), background: tone.$1, foreground: tone.$2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Panel(
            muted: true,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    fact(l.factJoined, c.joined == null ? '–' : day.format(c.joined!)),
                    fact(l.factLastVisit, _ago(l, c.lastVisit, now)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(children: [fact(l.factStamps, '${c.totalStamps}'), fact(l.factRewardsUsed, '${c.redeemed}')]),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final card in c.cards)
            if (c.programs[card.programId] case final program?) ...[
              () {
                final pr = card.progressFor(program.stampsRequired);
                return Panel(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(program.name, style: context.text.titleSmall)),
                          if (pr.rewards > 0)
                            Pill(
                              icon: LoyiIcons.gift,
                              label: l.rewardsWaitingCount(pr.rewards),
                              background: p.sunSoft,
                              foreground: p.onSunSoft,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: pr.stamps / program.stampsRequired,
                          minHeight: 8,
                          color: p.accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(l.stampsOfRequired(pr.stamps, program.stampsRequired), style: context.text.bodySmall),
                    ],
                  ),
                );
              }(),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 12),
          Text(l.recentVisits, style: context.text.titleMedium),
          const SizedBox(height: 10),
          FutureBuilder<List<ActivityItem>>(
            future: _visits,
            builder: (context, snap) {
              final visits = snap.data;
              if (snap.hasError) return Text(l.couldNotLoadVisits, style: context.text.bodySmall);
              if (visits == null) return const Skeleton(height: 80);
              if (visits.isEmpty) return Text(l.noStampsYet, style: context.text.bodySmall);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in visits)
                    Pill(
                      icon: LoyiIcons.stamp,
                      label: DateFormat('EEE d MMM · HH:mm').format(v.at),
                      background: p.surfaceMuted,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LoyiIcons.info, size: 16, color: p.inkMuted),
              const SizedBox(width: 8),
              Expanded(child: Text(l.whyNoName, style: context.text.bodySmall)),
            ],
          ),
        ],
      ),
    );
  }
}
