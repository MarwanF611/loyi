import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets/color_picker.dart';
import '../widgets/stamp_icons.dart';

/// Colours, style and stamp icon of a loyalty card.
class DesignEditor extends StatelessWidget {
  const DesignEditor({super.key, required this.design, required this.onChanged});

  final CardDesign design;
  final ValueChanged<CardDesign> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(s, style: text.labelLarge),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label('Card colour'),
        ColorPickerRow(
          value: design.background,
          onChanged: (c) => onChanged(design.copyWith(background: c)),
        ),
        label('Style'),
        SegmentedButton<CardStyle>(
          segments: const [
            ButtonSegment(value: CardStyle.solid, icon: Icon(Icons.square_rounded), label: Text('Solid')),
            ButtonSegment(value: CardStyle.gradient, icon: Icon(Icons.gradient), label: Text('Gradient')),
            ButtonSegment(value: CardStyle.pattern, icon: Icon(Icons.blur_on), label: Text('Pattern')),
          ],
          selected: {design.style},
          onSelectionChanged: (s) => onChanged(design.copyWith(style: s.first)),
        ),
        if (design.style != CardStyle.solid) ...[
          label('Second colour'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Auto'),
                selected: design.background2 == null,
                onSelected: (_) => onChanged(design.copyWith(background2: () => null)),
              ),
              ColorPickerRow(
                value: design.background2,
                onChanged: (c) => onChanged(design.copyWith(background2: () => c)),
              ),
            ],
          ),
        ],
        label('Stamp colour'),
        ColorPickerRow(
          value: design.stampColor,
          onChanged: (c) => onChanged(design.copyWith(stampColor: c)),
        ),
        label('Stamp icon'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final MapEntry(key: key, value: (icon, name)) in stampIcons.entries)
              Tooltip(
                message: name,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onChanged(design.copyWith(stampIcon: key)),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: key == design.stampIcon ? scheme.primaryContainer : null,
                      border: Border.all(
                        color: key == design.stampIcon ? scheme.primary : scheme.outlineVariant,
                        width: key == design.stampIcon ? 2 : 1,
                      ),
                    ),
                    child: Icon(icon, semanticLabel: name),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
