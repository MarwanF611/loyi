import 'package:flutter/material.dart';

import '../models.dart';
import '../services/language.dart';
import '../widgets/color_picker.dart';
import '../widgets/loyi_icons.dart';
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
    final l = context.l10n;
    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(s, style: text.labelLarge),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label(l.cardColour),
        ColorPickerRow(
          value: design.background,
          onChanged: (c) => onChanged(design.copyWith(background: c)),
        ),
        label(l.style),
        SegmentedButton<CardStyle>(
          showSelectedIcon: false, // the dark fill already marks the choice; keeps labels on one line
          segments: [
            ButtonSegment(value: CardStyle.solid, icon: const Icon(LoyiIcons.square), label: Text(l.styleSolid)),
            ButtonSegment(value: CardStyle.gradient, icon: const Icon(LoyiIcons.blend), label: Text(l.styleGradient)),
            ButtonSegment(value: CardStyle.pattern, icon: const Icon(LoyiIcons.shapes), label: Text(l.stylePattern)),
          ],
          selected: {design.style},
          onSelectionChanged: (s) => onChanged(design.copyWith(style: s.first)),
        ),
        if (design.style != CardStyle.solid) ...[
          label(l.secondColour),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChoiceChip(
                label: Text(l.auto),
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
        label(l.stampColour),
        ColorPickerRow(
          value: design.stampColor,
          onChanged: (c) => onChanged(design.copyWith(stampColor: c)),
        ),
        label(l.stampIcon),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final MapEntry(key: key, value: icon) in stampIcons.entries)
              Tooltip(
                message: stampIconName(l, key),
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
                    child: Icon(icon, semanticLabel: stampIconName(l, key)),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
