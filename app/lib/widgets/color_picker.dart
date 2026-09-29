import 'package:flutter/material.dart';

import '../models.dart';

/// Preset swatches for card and brand colours.
const cardPalette = <Color>[
  Color(0xFFFF5A3C), // coral (Loyi accent)
  Color(0xFFD32F2F), // red
  Color(0xFFD81B60), // pink
  Color(0xFF7C4DFF), // violet
  Color(0xFF3949AB), // indigo
  Color(0xFF1E88E5), // blue
  Color(0xFF00ACC1), // cyan
  Color(0xFF00897B), // teal
  Color(0xFF43A047), // green
  Color(0xFF827717), // olive
  Color(0xFFF9A825), // mustard
  Color(0xFFFB8C00), // orange
  Color(0xFF6D4C41), // coffee
  Color(0xFFD7CCC8), // sand
  Color(0xFFFFF3E0), // cream
  Color(0xFF263238), // charcoal
  Color(0xFF000000), // black
  Color(0xFFFFFFFF), // white
];

/// A row of swatches plus a "custom" button that accepts any hex colour.
class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({super.key, required this.value, required this.onChanged, this.palette = cardPalette});

  /// Null when nothing is selected (e.g. an "Auto" option elsewhere is active).
  final int? value;
  final ValueChanged<int> onChanged;
  final List<Color> palette;

  Future<void> _custom(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _HexDialog(initial: value ?? palette.first.toARGB32()),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = value != null && !palette.any((c) => c.toARGB32() == value);
    final outline = Theme.of(context).colorScheme.outline;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in palette)
          _Swatch(color: c, selected: c.toARGB32() == value, outline: outline, onTap: () => onChanged(c.toARGB32())),
        Tooltip(
          message: 'Custom colour',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _custom(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCustom ? Color(value!) : null,
                border: Border.all(color: outline),
              ),
              child: Icon(Icons.colorize, size: 18, color: isCustom ? readableOn(Color(value!)) : null),
            ),
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, required this.outline, required this.onTap});

  final Color color;
  final bool selected;
  final Color outline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '#${_hex(color.toARGB32())}',
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          // Light swatches (white, cream) need an outline to be visible.
          border: Border.all(color: color.computeLuminance() > 0.8 ? outline : color),
        ),
        child: selected ? Icon(Icons.check, size: 20, color: readableOn(color)) : null,
      ),
    ),
  );
}

String _hex(int argb) => (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

class _HexDialog extends StatefulWidget {
  const _HexDialog({required this.initial});

  final int initial;

  @override
  State<_HexDialog> createState() => _HexDialogState();
}

class _HexDialogState extends State<_HexDialog> {
  late final _controller = TextEditingController(text: _hex(widget.initial));
  int? _parsed;

  @override
  void initState() {
    super.initState();
    _parsed = widget.initial;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parse(String text) {
    final hex = text.replaceAll('#', '').trim();
    final valid = RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex);
    setState(() => _parsed = valid ? 0xFF000000 | int.parse(hex, radix: 16) : null);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Custom colour'),
    content: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _parsed != null ? Color(_parsed!) : null,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 7,
            onChanged: _parse,
            decoration: InputDecoration(
              prefixText: '#',
              labelText: 'Hex code',
              hintText: 'E8553D',
              errorText: _parsed == null ? 'Use 6 hex digits, e.g. E8553D' : null,
            ),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _parsed == null ? null : () => Navigator.pop(context, _parsed), child: const Text('Use')),
    ],
  );
}

/// Pick up to [max] colours; the selection order is shown as 1, 2, 3.
/// Tapping a selected colour removes it; when full, a new colour replaces the last one.
class MultiColorPicker extends StatelessWidget {
  const MultiColorPicker({
    super.key,
    required this.values,
    required this.onChanged,
    this.max = 3,
    this.palette = cardPalette,
  });

  final List<int> values;
  final ValueChanged<List<int>> onChanged;
  final int max;
  final List<Color> palette;

  void _toggle(int argb) {
    final next = [...values];
    if (next.contains(argb)) {
      next.remove(argb);
    } else if (next.length < max) {
      next.add(argb);
    } else {
      next[max - 1] = argb;
    }
    onChanged(next);
  }

  Future<void> _custom(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _HexDialog(initial: values.isEmpty ? palette.first.toARGB32() : values.last),
    );
    if (result != null && !values.contains(result)) _toggle(result);
  }

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    final custom = [
      for (final v in values)
        if (!palette.any((c) => c.toARGB32() == v)) v,
    ];
    Widget swatch(int argb) {
      final color = Color(argb);
      final index = values.indexOf(argb);
      return Semantics(
        button: true,
        selected: index >= 0,
        label: '#${_hex(argb)}${index >= 0 ? ', colour ${index + 1}' : ''}',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _toggle(argb),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: index >= 0
                    ? readableOn(Theme.of(context).colorScheme.surface)
                    : color.computeLuminance() > 0.8
                    ? outline
                    : color,
                width: index >= 0 ? 3 : 1,
              ),
            ),
            child: index >= 0
                ? Text(
                    '${index + 1}',
                    style: TextStyle(color: readableOn(color), fontWeight: FontWeight.w800, fontSize: 16),
                  )
                : null,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in palette) swatch(c.toARGB32()),
        for (final c in custom) swatch(c),
        Tooltip(
          message: 'Custom colour',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _custom(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: outline),
              ),
              child: const Icon(Icons.colorize, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}
