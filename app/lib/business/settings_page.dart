import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../services/appearance.dart';
import '../services/language.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/account_widgets.dart';
import '../widgets/loyalty_card_view.dart';
import '../widgets/loyi_icons.dart';
import '../widgets/ui.dart';
import 'business_form.dart';
import 'business_scope.dart';
import 'shell.dart';

/// The Settings tab: logo, name and brand colours, appearance, subscription and account.
class BusinessSettingsPage extends StatelessWidget {
  const BusinessSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => BusinessScope(
    builder: (context, business) {
      if (business == null) return const Scaffold();
      final l = context.l10n;
      return TabPage(
        eyebrow: l.tabSettings,
        title: l.yourShop,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Panel(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.logo, style: context.text.titleLarge),
                        const SizedBox(height: 4),
                        Text(l.logoHint, style: context.text.bodySmall),
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
                        Text(l.details, style: context.text.titleLarge),
                        const SizedBox(height: 16),
                        BusinessForm(
                          // Re-create the form if the stored values change elsewhere.
                          key: ValueKey('${business.name}-${business.brandColors}'),
                          initialName: business.name,
                          initialColors: business.brandColors,
                          submitLabel: l.save,
                          onSubmit: (name, colors) async {
                            await repo.updateBusiness(business.id, name: name, colors: colors);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.saved)));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.appearance, style: context.text.titleLarge),
                        const SizedBox(height: 4),
                        Text(l.appearanceHint, style: context.text.bodySmall),
                        const SizedBox(height: 16),
                        const AppearancePicker(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.language, style: context.text.titleLarge),
                        const SizedBox(height: 4),
                        Text(l.languageHint, style: context.text.bodySmall),
                        const SizedBox(height: 16),
                        const LanguagePicker(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    onTap: () => context.go('/business/subscribe'),
                    child: Row(
                      children: [
                        IconBadge(
                          icon: LoyiIcons.badgeCheck,
                          background: context.loyi.sunSoft,
                          foreground: context.loyi.ink,
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text(l.subscription, style: context.text.titleMedium)),
                        const Icon(LoyiIcons.chevronRight),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    onTap: () => context.go('/business/account'),
                    child: Row(
                      children: [
                        IconBadge(
                          icon: LoyiIcons.shield,
                          background: context.loyi.mintSoft,
                          foreground: context.loyi.mint,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.accountAndPrivacy, style: context.text.titleMedium),
                              Text(l.accountSettingsSub, style: context.text.bodySmall),
                            ],
                          ),
                        ),
                        const Icon(LoyiIcons.chevronRight),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const LegalLinks(),
                ],
              ),
            ),
          ),
        ],
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
      if (mounted) _snack(context.l10n.couldNotUpdateLogo);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pick() async {
    // Downscaled on the device: logos are stored in Firestore (max 200 KB).
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // No photo library permission needed: iOS's picker only hands over the chosen image.
      requestFullMetadata: false,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 85,
    );
    if (file == null) return;
    await _run(() async => repo.uploadLogo(widget.business, await file.readAsBytes()));
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = widget.business.logo != null;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: context.loyi.surfaceMuted, borderRadius: BorderRadius.circular(26)),
          child: BusinessLogo(logo: widget.business.logo, name: widget.business.name, size: 84),
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
                    : const Icon(LoyiIcons.upload),
                label: Text(hasLogo ? context.l10n.replaceLogo : context.l10n.uploadLogo),
              ),
              if (hasLogo)
                TextButton(
                  onPressed: _busy ? null : () => _run(() => repo.removeLogo(widget.business)),
                  child: Text(context.l10n.remove),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
