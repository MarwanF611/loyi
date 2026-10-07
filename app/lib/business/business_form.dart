import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api.dart';
import '../services/language.dart';
import '../widgets/color_picker.dart';

/// Name + up to three brand colours, in business settings.
class BusinessForm extends StatefulWidget {
  const BusinessForm({
    super.key,
    this.initialName = '',
    this.initialColors = const [],
    required this.submitLabel,
    required this.onSubmit,
  });

  final String initialName;
  final List<int> initialColors;
  final String submitLabel;
  final Future<void> Function(String name, List<int> colors) onSubmit;

  @override
  State<BusinessForm> createState() => _BusinessFormState();
}

class _BusinessFormState extends State<BusinessForm> {
  late final _name = TextEditingController(text: widget.initialName);
  late List<int> _colors = widget.initialColors.isEmpty ? [cardPalette.first.toARGB32()] : widget.initialColors;
  bool _busy = false;
  String? _nameError;
  String? _colorsError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    setState(() {
      _nameError = name.isEmpty ? context.l10n.enterBusinessName : null;
      _colorsError = _colors.isEmpty ? context.l10n.chooseOneColour : null;
    });
    if (_nameError != null || _colorsError != null) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(name, _colors);
    } catch (e) {
      if (mounted) setState(() => _nameError = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _name,
          maxLength: 80,
          autocorrect: false,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l.businessName, hintText: l.businessNameHint, errorText: _nameError),
        ),
        const SizedBox(height: 8),
        Text(l.brandColours, style: text.titleSmall),
        Text(l.brandColoursHint(Business.maxBrandColors), style: text.bodySmall),
        const SizedBox(height: 12),
        MultiColorPicker(values: _colors, onChanged: (c) => setState(() => _colors = c)),
        if (_colorsError != null) ...[
          const SizedBox(height: 8),
          Text(_colorsError!, style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 24),
        FilledButton(onPressed: _busy ? null : _submit, child: Text(widget.submitLabel)),
      ],
    );
  }
}
