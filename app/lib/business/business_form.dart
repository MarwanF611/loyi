import 'package:flutter/material.dart';

import '../theme.dart';

/// Name + card colour. Used for onboarding and for editing the business.
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
  late int _color = widget.initialColor ?? businessColors.first.toARGB32();
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
      Text('Card colour', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final c in businessColors)
            Semantics(
              button: true,
              selected: c.toARGB32() == _color,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() => _color = c.toARGB32()),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: c,
                  child: c.toARGB32() == _color ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 24),
      FilledButton(onPressed: _busy ? null : _submit, child: Text(widget.submitLabel)),
    ],
  );
}
