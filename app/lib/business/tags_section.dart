import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../config.dart';
import '../models.dart';
import '../services/repo.dart';
import '../theme.dart';
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
    final label = TextEditingController(text: type == TagType.join ? 'Entrance' : 'Counter');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == TagType.join ? 'New join tag' : 'New stamp tag'),
        content: TextField(
          controller: label,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Where is this tag?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );
    final text = label.text.trim();
    label.dispose();
    if (confirmed == true) await repo.createTag(widget.program, type, text.isEmpty ? type.name : text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'NFC tags', subtitle: 'Every tag is a link. Write it onto an NFC sticker.'),
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
                    child: Text(
                      'No tags yet. Create one join tag and one stamp tag to get started.',
                      style: context.text.bodyMedium,
                    ),
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
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text('Add join tag'),
            ),
            OutlinedButton.icon(
              onPressed: () => _addTag(TagType.stamp),
              icon: const Icon(Icons.approval_rounded),
              label: const Text('Add stamp tag'),
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
          step(1, 'Join tag, where clients can see it', 'At the door or on the counter. Tapping it adds the card.'),
          step(2, 'Stamp tag, behind the counter', 'Hold it out after a purchase. Every tap gives one stamp.'),
          step(
            3,
            'Program the stickers',
            'Use NTAG213/215 stickers. Copy the link and write it as a URL record with a free app like NFC Tools.',
          ),
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
    final lastTap = tag.lastTapAt == null ? 'never' : DateFormat('d MMM HH:mm').format(tag.lastTapAt!);
    return Panel(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: isJoin ? Icons.person_add_alt_rounded : Icons.approval_rounded,
                background: isJoin ? p.accentSoft : p.mintSoft,
                foreground: isJoin ? p.accent : p.mint,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${isJoin ? 'Join' : 'Stamp'} tag · ${tag.label}', style: context.text.titleMedium),
                    Text('${tag.tapCount} taps · last $lastTap', style: context.text.bodySmall),
                  ],
                ),
              ),
              Tooltip(
                message: tag.active ? 'Active' : 'Disabled',
                child: Switch(
                  value: tag.active,
                  onChanged: (v) => repo.setTagActive(tag, active: v),
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
                  tooltip: 'Copy link',
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied')));
                    }
                  },
                ),
                // QR is only offered for join tags: a visible stamp QR could be photographed and reused.
                if (isJoin)
                  IconButton(
                    tooltip: 'Show QR code',
                    icon: const Icon(Icons.qr_code_2_rounded, size: 22),
                    onPressed: () => showLoyiSheet<void>(
                      context,
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Join QR code', style: context.text.headlineSmall),
                          const SizedBox(height: 4),
                          Text('Print it for clients without NFC.', style: context.text.bodyMedium),
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
