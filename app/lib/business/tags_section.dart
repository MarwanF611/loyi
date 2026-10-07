import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../config.dart';
import '../models.dart';
import '../services/api.dart';
import '../services/language.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/ui.dart';

/// Lists a program's NFC tags and lets the business create new ones.
/// Each tag is just a URL (`/t/<tagId>`) written onto an NFC sticker.
class TagsSection extends StatefulWidget {
  const TagsSection({super.key, required this.program});

  final Program program;

  @override
  State<TagsSection> createState() => _TagsSectionState();
}

class _TagsSectionState extends State<TagsSection> {
  late final Stream<List<LoyiTag>> _tags = repo.tagsForProgram(
    ownerUid: widget.program.ownerUid,
    programId: widget.program.id,
  );

  Future<void> _addTag(TagType type) async {
    final label = await showDialog<String>(
      context: context,
      builder: (_) => _TagLabelDialog(type: type),
    );
    if (label == null) return;
    try {
      await repo.createTag(widget.program, type, label.isEmpty ? type.name : label);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: context.l10n.nfcTags, subtitle: context.l10n.nfcTagsSub),
        const _HowTo(),
        const SizedBox(height: 16),
        StreamBuilder<List<LoyiTag>>(
          stream: _tags,
          builder: (context, snap) {
            final tags = snap.data ?? const <LoyiTag>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final tag in tags) ...[_TagTile(tag: tag), const SizedBox(height: 12)],
                if (snap.hasData && tags.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(context.l10n.noTagsYet, style: context.text.bodyMedium),
                  ),
              ],
            );
          },
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => _addTag(TagType.join),
              icon: const Icon(LoyiIcons.userPlus),
              label: Text(context.l10n.addJoinTag),
            ),
            OutlinedButton.icon(
              onPressed: () => _addTag(TagType.stamp),
              icon: const Icon(LoyiIcons.stamp),
              label: Text(context.l10n.addStampTag),
            ),
          ],
        ),
      ],
    );
  }
}

class _HowTo extends StatelessWidget {
  const _HowTo();

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    Widget step(int n, String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: p.ink,
            child: Text('$n', style: context.text.labelMedium?.copyWith(color: p.canvas)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                Text(body, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
    return Panel(
      color: p.surfaceMuted,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
      child: Column(
        children: [
          step(1, context.l10n.tagStep1, context.l10n.tagStep1Sub),
          step(2, context.l10n.tagStep2, context.l10n.tagStep2Sub),
          step(3, context.l10n.programStickers, context.l10n.programStickersSub),
        ],
      ),
    );
  }
}

class _TagTile extends StatelessWidget {
  const _TagTile({required this.tag});

  final LoyiTag tag;

  @override
  Widget build(BuildContext context) {
    final p = context.loyi;
    final url = tagUrl(tag.id);
    final isJoin = tag.type == TagType.join;
    final lastTap = tag.lastTapAt == null ? context.l10n.never : DateFormat('d MMM HH:mm').format(tag.lastTapAt!);
    return Panel(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: isJoin ? LoyiIcons.userPlus : LoyiIcons.stamp,
                background: isJoin ? p.accentSoft : p.mintSoft,
                foreground: isJoin ? p.accent : p.mint,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isJoin ? context.l10n.joinTagLabel(tag.label) : context.l10n.stampTagLabel(tag.label),
                      style: context.text.titleMedium,
                    ),
                    Text(context.l10n.tapsSummary(tag.tapCount, lastTap), style: context.text.bodySmall),
                  ],
                ),
              ),
              Tooltip(
                message: tag.active ? context.l10n.active : context.l10n.disabled,
                child: Switch(
                  value: tag.active,
                  onChanged: (v) => repo.setTagActive(tag, active: v).catchError((Object e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
                    }
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(color: p.surfaceMuted, borderRadius: BorderRadius.circular(Radii.sm)),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(url, maxLines: 1, style: context.text.bodySmall?.copyWith(color: p.ink)),
                ),
                IconButton(
                  tooltip: context.l10n.copyLink,
                  icon: const Icon(LoyiIcons.copy, size: 20),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.linkCopied)));
                    }
                  },
                ),
                // QR is only offered for join tags: a visible stamp QR could be photographed and reused.
                if (isJoin)
                  IconButton(
                    tooltip: context.l10n.showQrCode,
                    icon: const Icon(LoyiIcons.qrCode, size: 22),
                    onPressed: () => showLoyiSheet<void>(
                      context,
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(context.l10n.joinQrCode, style: context.text.headlineSmall),
                          const SizedBox(height: 4),
                          Text(context.l10n.joinQrCodeSub, style: context.text.bodyMedium),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(Radii.lg),
                              border: Border.all(color: p.line),
                            ),
                            child: SizedBox(width: 240, height: 240, child: QrImageView(data: url)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks where a new tag will be placed. Owns its text controller, so it is only
/// disposed after the dialog has fully closed.
class _TagLabelDialog extends StatefulWidget {
  const _TagLabelDialog({required this.type});

  final TagType type;

  @override
  State<_TagLabelDialog> createState() => _TagLabelDialogState();
}

class _TagLabelDialogState extends State<_TagLabelDialog> {
  late final _label = TextEditingController(
    text: widget.type == TagType.join ? l10n.defaultJoinTagLabel : l10n.defaultStampTagLabel,
  );

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _create() => Navigator.pop(context, _label.text.trim());

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.type == TagType.join ? context.l10n.newJoinTag : context.l10n.newStampTag),
    content: TextField(
      controller: _label,
      autofocus: true,
      autocorrect: false,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: context.l10n.whereIsTag),
      onSubmitted: (_) => _create(),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
      FilledButton(onPressed: _create, child: Text(context.l10n.create)),
    ],
  );
}
