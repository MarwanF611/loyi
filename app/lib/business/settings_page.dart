import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/loyalty_card_view.dart';
import '../widgets/ui.dart';
import 'business_form.dart';
import 'business_scope.dart';

/// Business name, brand colour and logo.
class BusinessSettingsPage extends StatelessWidget {
  const BusinessSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => BusinessScope(
    builder: (context, business) {
      if (business == null) return const Scaffold();
      return Scaffold(
        appBar: AppBar(
          title: const Text('Business settings'),
          leading: BackButton(onPressed: () => context.go('/business')),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            PageBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Panel(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Logo', style: context.text.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Shown on all your loyalty cards. A square PNG with a transparent background works best.',
                          style: context.text.bodySmall,
                        ),
                        const SizedBox(height: 18),
                        _LogoEditor(business: business),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Details', style: context.text.titleLarge),
                        const SizedBox(height: 16),
                        BusinessForm(
                          // Re-create the form if the stored values change elsewhere.
                          key: ValueKey('${business.name}-${business.color}'),
                          initialName: business.name,
                          initialColor: business.color,
                          submitLabel: 'Save',
                          onSubmit: (name, color) async {
                            await repo.updateBusiness(business.id, name: name, color: color);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _LogoEditor extends StatefulWidget {
  const _LogoEditor({required this.business});

  final Business business;

  @override
  State<_LogoEditor> createState() => _LogoEditorState();
}

class _LogoEditorState extends State<_LogoEditor> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on FormatException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Could not update the logo. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pick() async {
    // Downscaled on the device so uploads stay small.
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 90,
    );
    if (file == null) return;
    await _run(() async => repo.uploadLogo(widget.business, await file.readAsBytes()));
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = widget.business.logoUrl != null;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: context.loyi.surfaceMuted, borderRadius: BorderRadius.circular(26)),
          child: BusinessLogo(url: widget.business.logoUrl, name: widget.business.name, size: 84),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _pick,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload),
                label: Text(hasLogo ? 'Replace logo' : 'Upload logo'),
              ),
              if (hasLogo)
                TextButton(
                  onPressed: _busy ? null : () => _run(() => repo.removeLogo(widget.business)),
                  child: const Text('Remove'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
