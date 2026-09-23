import 'package:flutter/material.dart';

import '../widgets/color_picker.dart';

/// Name + brand colour. Used for onboarding and in business settings.
class BusinessForm extends StatefulWidget {
  const BusinessForm({
    super.key,
    this.initialName = '',
    this.initialColor,
    required this.submitLabel,
    required this.onSubmit,
  });

  final String initialName;
  final int? initialColor;
  final String submitLabel;
  final Future<void> Function(String name, int color) onSubmit;

  @override
  State<BusinessForm> createState() => _BusinessFormState();
}

class _BusinessFormState extends State<BusinessForm> {
  late final _name = TextEditingController(text: widget.initialName);
  late int _color = widget.initialColor ?? cardPalette.first.toARGB32();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter your business name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(name, _color);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      TextField(
        controller: _name,
        maxLength: 80,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: 'Business name', hintText: 'e.g. Bakkerij Peeters', errorText: _error),
      ),
      const SizedBox(height: 8),
      Text('Brand colour', style: Theme.of(context).textTheme.titleSmall),
      Text('Used as the starting colour for new cards.', style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 12),
      ColorPickerRow(value: _color, onChanged: (c) => setState(() => _color = c)),
      const SizedBox(height: 24),
      FilledButton(onPressed: _busy ? null : _submit, child: Text(widget.submitLabel)),
    ],
  );
}
