import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/loyalty_card_view.dart';
import 'business_scope.dart';
import '../widgets/ui.dart';
import 'design_editor.dart';
import 'tags_section.dart';

/// Create (`programId == null`) or edit a loyalty card, and manage its NFC tags.
class ProgramPage extends StatelessWidget {
  const ProgramPage({super.key, this.programId});

  final String? programId;

  @override
  Widget build(BuildContext context) => BusinessScope(
    builder: (context, business) {
      if (business == null) return const _Redirect('/business');
      final id = programId;
      if (id == null) return _ProgramEditor(key: const ValueKey('new'), business: business);
      return FutureBuilder<Program?>(
        future: repo.program(id).first,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final program = snap.data;
          if (program == null || program.businessId != business.id) return const _Redirect('/business');
          return _ProgramEditor(key: ValueKey(id), business: business, initial: program);
        },
      );
    },
  );
}

class _Redirect extends StatelessWidget {
  const _Redirect(this.location);

  final String location;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go(location);
    });
    return const Scaffold();
  }
}

class _RewardRow {
  _RewardRow(this.id, String title, this.active) : title = TextEditingController(text: title);

  final String id;
  final TextEditingController title;
  bool active;
}

const _cooldownOptions = <int, String>{
  0: 'No limit',
  5: '5 minutes',
  15: '15 minutes',
  30: '30 minutes',
  60: '1 hour',
  120: '2 hours',
  720: '12 hours',
  1440: '1 day',
};

class _ProgramEditor extends StatefulWidget {
  const _ProgramEditor({super.key, required this.business, this.initial});

  final Business business;
  final Program? initial;

  @override
  State<_ProgramEditor> createState() => _ProgramEditorState();
}

class _ProgramEditorState extends State<_ProgramEditor> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '')..addListener(_rebuild);
  late int _stampsRequired = widget.initial?.stampsRequired ?? 10;
  late int _cooldown = widget.initial?.stampCooldownMinutes ?? 30;
  late bool _active = widget.initial?.active ?? true;
  late CardDesign _design = widget.initial?.designFor(widget.business) ?? CardDesign(background: widget.business.color);
  late final List<_RewardRow> _rewards = [
    for (final r in widget.initial?.rewards ?? const <Reward>[]) _RewardRow(r.id, r.title, r.active),
    if (widget.initial == null) _RewardRow(repo.newId(), '', true),
  ];
  bool _saving = false;
  String? _error;

  bool get _isNew => widget.initial == null;

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    for (final r in _rewards) {
      r.title.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final rewards = [
      for (final r in _rewards)
        if (r.title.text.trim().isNotEmpty) Reward(id: r.id, title: r.title.text.trim(), active: r.active),
    ];
    final error = switch (()) {
      _ when _name.text.trim().isEmpty => 'Give your card a name.',
      _ when rewards.isEmpty => 'Add at least one reward.',
      _ => null,
    };
    setState(() => _error = error);
    if (error != null) return;

    setState(() => _saving = true);
    try {
      final id = await repo.saveProgram(
        Program(
          id: widget.initial?.id ?? '',
          businessId: widget.business.id,
          ownerUid: auth.user!.uid,
          name: _name.text.trim(),
          stampsRequired: _stampsRequired,
          stampCooldownMinutes: _cooldown,
          rewards: rewards,
          active: _active,
          design: _design,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_isNew ? 'Card created. Now add your NFC tags below.' : 'Saved')));
      if (_isNew) context.go('/business/programs/$id');
    } catch (e) {
      setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final preview = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoyaltyCardView(
          businessName: widget.business.name,
          programName: _name.text.isEmpty ? 'Your card name' : _name.text,
          design: _design,
          logoUrl: widget.business.logoUrl,
          stamps: (_stampsRequired / 3).ceil(),
          stampsRequired: _stampsRequired,
        ),
        const SizedBox(height: 8),
        Text('Preview', style: text.bodySmall, textAlign: TextAlign.center),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New loyalty card' : 'Edit loyalty card'),
        leading: BackButton(onPressed: () => context.go('/business')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: _saving ? null : _save,
              child: Text(_isNew ? 'Create' : 'Save'),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Wide screens: form on the left, preview stays visible on the right.
          final wide = constraints.maxWidth >= 1000;
          final form = ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PageBody(
                maxWidth: 640,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!wide) ...[preview, const SizedBox(height: 24)],
                    ..._formFields(text),
                  ],
                ),
              ),
            ],
          );
          if (!wide) return form;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: form),
              SizedBox(
                width: 420,
                child: Padding(padding: const EdgeInsets.fromLTRB(8, 16, 32, 16), child: preview),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _formFields(TextTheme text) => [
    _Section(
      title: 'Card name',
      subtitle: 'Short and descriptive; clients see it under your business name.',
      child: TextField(
        controller: _name,
        maxLength: 30,
        decoration: const InputDecoration(hintText: 'e.g. Koffiekaart'),
      ),
    ),
    _Section(
      title: 'Design',
      child: DesignEditor(design: _design, onChanged: (d) => setState(() => _design = d)),
    ),
    _Section(
      title: 'Stamps for a full card',
      subtitle: '6 to 10 stamps feels achievable for most clients; more can feel out of reach.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                tooltip: 'Fewer stamps',
                onPressed: _stampsRequired > 1 ? () => setState(() => _stampsRequired--) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Container(
                width: 72,
                alignment: Alignment.center,
                child: Text('$_stampsRequired', style: text.headlineLarge),
              ),
              IconButton.filledTonal(
                tooltip: 'More stamps',
                onPressed: _stampsRequired < 50 ? () => setState(() => _stampsRequired++) : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          for (final n in const [5, 8, 10])
            ChoiceChip(
              label: Text('$n'),
              selected: _stampsRequired == n,
              onSelected: (_) => setState(() => _stampsRequired = n),
            ),
        ],
      ),
    ),
    _Section(
      title: 'Rewards',
      subtitle:
          'Clients with a full card choose one of the active rewards. '
          'Switch rewards on or off anytime, e.g. a different reward each week.',
      child: Column(
        children: [
          for (final r in _rewards)
            Padding(
              key: ObjectKey(r),
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: r.title,
                      maxLength: 60,
                      onChanged: (_) => _rebuild(),
                      decoration: const InputDecoration(hintText: 'e.g. Free coffee', counterText: '', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: r.active ? 'Active' : 'Hidden from clients',
                    child: Switch(value: r.active, onChanged: (v) => setState(() => r.active = v)),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() => _rewards.remove(r));
                      WidgetsBinding.instance.addPostFrameCallback((_) => r.title.dispose());
                    },
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _rewards.length >= 20
                  ? null
                  : () => setState(() => _rewards.add(_RewardRow(repo.newId(), '', true))),
              icon: const Icon(Icons.add),
              label: const Text('Add reward'),
            ),
          ),
        ],
      ),
    ),
    _Section(
      title: 'Time between stamps',
      subtitle: 'The minimum wait before the same client can get another stamp. Stops double taps.',
      child: DropdownButtonFormField<int>(
        initialValue: _cooldownOptions.containsKey(_cooldown) ? _cooldown : 30,
        items: [for (final e in _cooldownOptions.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
        onChanged: (v) => setState(() => _cooldown = v ?? 0),
      ),
    ),
    Panel(
      padding: const EdgeInsets.fromLTRB(22, 14, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Card is live', style: text.titleLarge),
                Text('When paused, taps are refused but clients keep their stamps.', style: text.bodySmall),
              ],
            ),
          ),
          Switch(value: _active, onChanged: (v) => setState(() => _active = v)),
        ],
      ),
    ),
    if (_error != null) ...[
      const SizedBox(height: 8),
      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
    ],
    const SizedBox(height: 16),
    FilledButton(onPressed: _saving ? null : _save, child: Text(_isNew ? 'Create card' : 'Save changes')),
    if (!_isNew) ...[const SizedBox(height: 36), TagsSection(program: widget.initial!)],
  ];
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Panel(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleLarge),
          if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: context.text.bodySmall)],
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}
