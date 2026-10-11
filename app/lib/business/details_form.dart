import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../services/api.dart';
import '../services/language.dart';
import '../theme.dart';

/// The shop's official details: name, address, company and VAT number.
/// Used in sign-up (step 3) and in Settings.
class BusinessDetailsForm extends StatefulWidget {
  const BusinessDetailsForm({super.key, this.initial, required this.submitLabel, required this.onSubmit});

  final BusinessDetails? initial;
  final String submitLabel;
  final Future<void> Function(BusinessDetails details) onSubmit;

  @override
  State<BusinessDetailsForm> createState() => _BusinessDetailsFormState();
}

String countryName(L10n l, String code) => switch (code) {
  'BE' => l.countryBE,
  'NL' => l.countryNL,
  'LU' => l.countryLU,
  'FR' => l.countryFR,
  'DE' => l.countryDE,
  _ => code,
};

class _BusinessDetailsFormState extends State<BusinessDetailsForm> {
  late final _legalName = TextEditingController(text: widget.initial?.legalName);
  late final _street = TextEditingController(text: widget.initial?.street);
  late final _postcode = TextEditingController(text: widget.initial?.postcode);
  late final _city = TextEditingController(text: widget.initial?.city);
  late final _companyNumber = TextEditingController(text: widget.initial?.companyNumber);
  late final _vat = TextEditingController(text: widget.initial?.vatNumber);
  late final _phone = TextEditingController(text: widget.initial?.phone);
  late String _country = BusinessDetails.countries.contains(widget.initial?.country) ? widget.initial!.country : 'BE';
  final _errors = <String, String>{};
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_legalName, _street, _postcode, _city, _companyNumber, _vat, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    final required = l.fieldRequired;
    final company = BusinessDetails.normalizeCompanyNumber(_country, _companyNumber.text);
    final vatInput = _vat.text.trim();
    final vat = vatInput.isEmpty ? '' : BusinessDetails.normalizeVat(_country, vatInput, _companyNumber.text);
    final postcode = _postcode.text.trim().toUpperCase();
    setState(() {
      _errors
        ..clear()
        ..addAll({
          if (_legalName.text.trim().isEmpty) 'legalName': required,
          if (_street.text.trim().isEmpty) 'street': required,
          if (postcode.isEmpty)
            'postcode': required
          else if (!BusinessDetails.validPostcode(_country, postcode))
            'postcode': l.invalidPostcode,
          if (_city.text.trim().isEmpty) 'city': required,
          if (_companyNumber.text.trim().isEmpty)
            'companyNumber': required
          else if (company == null)
            'companyNumber': l.invalidCompanyNumber,
          if (vat == null) 'vat': _country == 'BE' ? l.vatMustMatchBE : l.invalidVat,
        });
      _error = null;
    });
    if (_errors.isNotEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(
        BusinessDetails(
          legalName: _legalName.text.trim(),
          street: _street.text.trim(),
          postcode: postcode,
          city: _city.text.trim(),
          country: _country,
          companyNumber: company!,
          vatNumber: vat!,
          phone: _phone.text.trim(),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    String key,
    TextEditingController controller,
    String label, {
    String? hint,
    String? helper,
    int maxLength = 120,
    TextInputType? keyboard,
    List<String>? autofill,
    TextCapitalization caps = TextCapitalization.words,
  }) => TextField(
    controller: controller,
    maxLength: maxLength,
    keyboardType: keyboard,
    autofillHints: autofill,
    textCapitalization: caps,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 2,
      errorMaxLines: 2,
      errorText: _errors[key],
      counterText: '',
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const gap = SizedBox(height: 14);
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            'legalName',
            _legalName,
            l.legalName,
            helper: l.legalNameHint,
            autofill: const [AutofillHints.organizationName],
          ),
          gap,
          _field('street', _street, l.streetAndNumber, autofill: const [AutofillHints.streetAddressLine1]),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field(
                  'postcode',
                  _postcode,
                  l.postcode,
                  maxLength: 10,
                  autofill: const [AutofillHints.postalCode],
                  caps: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field('city', _city, l.city, maxLength: 80, autofill: const [AutofillHints.addressCity]),
              ),
            ],
          ),
          gap,
          DropdownButtonFormField<String>(
            initialValue: _country,
            decoration: InputDecoration(labelText: l.country),
            items: [
              for (final c in BusinessDetails.countries) DropdownMenuItem(value: c, child: Text(countryName(l, c))),
            ],
            onChanged: (v) => setState(() => _country = v ?? 'BE'),
          ),
          gap,
          _field(
            'companyNumber',
            _companyNumber,
            l.companyNumber,
            hint: _country == 'BE' ? '0123.456.749' : null,
            helper: _country == 'BE' ? l.companyNumberHintBE : null,
            maxLength: 30,
            caps: TextCapitalization.characters,
          ),
          gap,
          _field(
            'vat',
            _vat,
            l.vatNumberOptional,
            helper: l.vatHelper,
            hint: _country == 'BE' ? 'BE0123456749' : null,
            maxLength: 20,
            caps: TextCapitalization.characters,
          ),
          gap,
          _field(
            'phone',
            _phone,
            l.phoneOptional,
            maxLength: 30,
            keyboard: TextInputType.phone,
            autofill: const [AutofillHints.telephoneNumber],
            caps: TextCapitalization.none,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: context.text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 8),
          Text(l.detailsPrivate, style: context.text.bodySmall?.copyWith(color: context.loyi.inkMuted)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
