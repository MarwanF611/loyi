import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../services/language.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/message_card.dart';
import '../widgets/ui.dart';
import 'insights/analytics.dart';
import 'shell.dart';

/// Follow-up without personal data: a shop writes a short message for a group
/// ("slipping away", "reward waiting", …) and Loyi shows it on the card of
/// clients in that group. The group is worked out on the client's own phone, so
/// the shop never learns who saw it, and nothing is sent by email or push.

/// Opens the composer for a new message (optionally for [audience]) or to edit [existing].
Future<void> showMessageComposer(BuildContext context, {Audience? audience, ShopMessage? existing}) {
  final data = BusinessData.of(context);
  return showLoyiSheet<void>(
    context,
    builder: (_) => _Composer(data: data, audience: audience ?? existing?.audience ?? Audience.all, existing: existing),
  );
}

final _linkPattern = RegExp(r'https?:|www\.|\.(com|be|nl|net|org|eu|io|ly)\b', caseSensitive: false);

String? _noLinks(String? v) => v != null && _linkPattern.hasMatch(v) ? l10n.noLinksAllowed : null;

class _Composer extends StatefulWidget {
  const _Composer({required this.data, required this.audience, this.existing});

  final BusinessData data;
  final Audience audience;
  final ShopMessage? existing;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title)..addListener(_changed);
  late final _body = TextEditingController(text: widget.existing?.body)..addListener(_changed);
  late Audience _audience = widget.audience;
  late String? _programId = widget.existing?.programId;
  int _days = 14;
  bool _busy = false;

  void _changed() => setState(() {});

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final d = widget.data;
    final now = DateTime.now();
    final e = widget.existing;
    try {
      await repo.saveMessage(
        ShopMessage(
          id: e?.id ?? '',
          businessId: d.business.id,
          ownerUid: d.uid,
          programId: _programId,
          title: _title.text.trim(),
          body: _body.text.trim(),
          audience: _audience,
          active: true,
          endsAt: DateTime(now.year, now.month, now.day + _days, 23, 59),
        ),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(e == null ? l10n.messageIsLive : l10n.messageUpdated)));
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.couldNotSaveMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final p = context.loyi;
    final programs = d.programs ?? const <Program>[];
    final cards = d.cards ?? const <LoyaltyCard>[];
    final now = DateTime.now();
    final l = context.l10n;
    return SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Eyebrow(l.followUp),
            const SizedBox(height: 6),
            Text(widget.existing == null ? l.newMessage : l.editMessage, style: context.text.headlineMedium),
            const SizedBox(height: 20),
            Text(l.whoSeesIt, style: context.text.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in Audience.values)
                  ChoiceChip(
                    label: Text('${a.label(l)} · ${reach(cards, d.programById, a, _programId, now)}'),
                    selected: a == _audience,
                    onSelected: (_) => setState(() => _audience = a),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_audience.description(l), style: context.text.bodySmall),
            if (programs.length > 1) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _programId,
                decoration: InputDecoration(labelText: l.card),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.allCards)),
                  for (final pr in programs) DropdownMenuItem(value: pr.id, child: Text(pr.name)),
                ],
                onChanged: (v) => setState(() => _programId = v),
              ),
            ],
            const SizedBox(height: 20),
            TextFormField(
              controller: _title,
              maxLength: ShopMessage.maxTitle,
              decoration: InputDecoration(labelText: l.title, hintText: l.messageTitleHint),
              validator: (v) => (v ?? '').trim().isEmpty ? l.addShortTitle : _noLinks(v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _body,
              maxLength: ShopMessage.maxBody,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: l.message, hintText: l.messageBodyHint),
              validator: (v) => (v ?? '').trim().isEmpty ? l.writeYourMessage : _noLinks(v),
            ),
            const SizedBox(height: 12),
            Text(l.showItFor, style: context.text.titleSmall),
            const SizedBox(height: 10),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 7, label: Text(l.oneWeek)),
                ButtonSegment(value: 14, label: Text(l.twoWeeks)),
                ButtonSegment(value: 30, label: Text(l.oneMonth)),
              ],
              selected: {_days},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _days = s.first),
            ),
            const SizedBox(height: 24),
            Eyebrow(l.preview),
            const SizedBox(height: 10),
            Panel(
              muted: true,
              padding: const EdgeInsets.all(14),
              child: MessageCard(business: d.business, title: _title.text.trim(), body: _body.text.trim()),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LoyiIcons.shieldCheck, size: 18, color: p.mint),
                const SizedBox(width: 10),
                Expanded(child: Text(l.messagePrivacyNote, style: context.text.bodySmall)),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.existing == null ? l.publishMessage : l.save),
            ),
          ],
        ),
      ),
    );
  }
}

/// The shop's messages, live and past, with pause, edit and delete.
class MessagesList extends StatefulWidget {
  const MessagesList({super.key});

  @override
  State<MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList> {
  Stream<List<ShopMessage>>? _messages;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final d = BusinessData.of(context);
    _messages ??= repo.messagesForBusiness(d.uid, d.business.id);
  }

  Future<void> _delete(ShopMessage m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteMessageQuestion),
        content: Text(context.l10n.deleteMessageBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.delete)),
        ],
      ),
    );
    if (ok == true) await repo.deleteMessage(m);
  }

  @override
  Widget build(BuildContext context) {
    final d = BusinessData.of(context);
    final p = context.loyi;
    final names = {for (final pr in d.programs ?? const <Program>[]) pr.id: pr.name};
    final now = DateTime.now();
    final l = context.l10n;
    return StreamBuilder<List<ShopMessage>>(
      stream: _messages,
      builder: (context, snap) {
        final list = snap.data;
        if (list == null) return const Skeleton(height: 120, radius: Radii.lg);
        if (list.isEmpty) {
          return Panel(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                IconBadge(icon: LoyiIcons.megaphone, background: p.accentSoft, foreground: p.accent, size: 56),
                const SizedBox(height: 14),
                Text(l.noMessagesYet, style: context.text.titleLarge),
                const SizedBox(height: 4),
                Text(l.noMessagesBody, textAlign: TextAlign.center, style: context.text.bodyMedium),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => showMessageComposer(context),
                  icon: const Icon(LoyiIcons.plus, size: 18),
                  label: Text(l.writeAMessage),
                ),
              ],
            ),
          );
        }
        return Panel(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (final (i, m) in list.indexed) ...[
                if (i > 0) const Divider(indent: 16, endIndent: 16),
                _MessageRow(
                  message: m,
                  cardName: m.programId == null ? l.allCards : (names[m.programId] ?? l.card),
                  reach: reach(d.cards ?? const [], d.programById, m.audience, m.programId, now),
                  onEdit: () => showMessageComposer(context, existing: m),
                  onToggle: () => repo.setMessageActive(m, active: !m.active),
                  onDelete: () => _delete(m),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.cardName,
    required this.reach,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final ShopMessage message;
  final String cardName;
  final int reach;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    final m = message;
    final now = DateTime.now();
    final ended = !m.endsAt.isAfter(now);
    final l = context.l10n;
    final date = DateFormat('d MMM').format(m.endsAt);
    final (label, bg, fg) = ended
        ? (l.messageEnded, p.surfaceMuted, p.inkMuted)
        : m.active
        ? (l.live, p.mintSoft, p.mint)
        : (l.messagePaused, p.sunSoft, p.onSunSoft);
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Pill(label: label, background: bg, foreground: fg),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(m.title, style: context.text.titleSmall, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${m.audience.label(l)} · $cardName · '
                    '${ended ? l.messageEndedOn(date) : l.messageReachUntil(reach, date)}',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: l.messageOptions,
              icon: const Icon(LoyiIcons.ellipsis),
              onSelected: (v) => switch (v) {
                'edit' => onEdit(),
                'toggle' => onToggle(),
                _ => onDelete(),
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(ended ? l.editAndRunAgain : l.edit)),
                if (!ended) PopupMenuItem(value: 'toggle', child: Text(m.active ? l.pause : l.resume)),
                PopupMenuItem(value: 'delete', child: Text(l.delete)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
