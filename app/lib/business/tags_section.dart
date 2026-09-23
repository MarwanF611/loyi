import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../config.dart';
import '../models.dart';
import '../services/repo.dart';

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
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('NFC tags', style: text.titleLarge),
        const SizedBox(height: 8),
        const _HowTo(),
        const SizedBox(height: 16),
        StreamBuilder<List<LoyiTag>>(
          stream: _tags,
          builder: (context, snap) {
            final tags = snap.data ?? const <LoyiTag>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final tag in tags) ...[_TagTile(tag: tag), const SizedBox(height: 8)],
                if (snap.hasData && tags.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('No tags yet. Create one join tag and one stamp tag to get started.'),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _addTag(TagType.join),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Add join tag'),
            ),
            OutlinedButton.icon(
              onPressed: () => _addTag(TagType.stamp),
              icon: const Icon(Icons.approval),
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
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.bodyMedium,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Join tag: place it where clients can see it (door, counter). Tapping it adds the card.'),
            SizedBox(height: 6),
            Text(
              '• Stamp tag: keep it behind the counter and hold it out after a purchase. '
              'Every tap gives one stamp.',
            ),
            SizedBox(height: 6),
            Text(
              '• To program a sticker (NTAG213/215), copy the link and write it as a URL record '
              'with a free app like "NFC Tools".',
            ),
          ],
        ),
      ),
    ),
  );
}

class _TagTile extends StatelessWidget {
  const _TagTile({required this.tag});

  final LoyiTag tag;

  @override
  Widget build(BuildContext context) {
    final url = tagUrl(tag.id);
    final isJoin = tag.type == TagType.join;
    final lastTap = tag.lastTapAt == null ? 'never' : DateFormat('d MMM HH:mm').format(tag.lastTapAt!);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isJoin ? Icons.person_add_alt : Icons.approval),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isJoin ? 'Join' : 'Stamp'} tag · ${tag.label}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('${tag.tapCount} taps · last: $lastTap', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Switch(
                  value: tag.active,
                  onChanged: (v) => repo.setTagActive(tag, active: v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: SelectableText(url, style: Theme.of(context).textTheme.bodySmall)),
                IconButton(
                  tooltip: 'Copy link',
                  icon: const Icon(Icons.copy),
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
                    icon: const Icon(Icons.qr_code_2),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Join QR code'),
                        content: SizedBox(
                          width: 260,
                          height: 260,
                          child: QrImageView(data: url, backgroundColor: Colors.white),
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
