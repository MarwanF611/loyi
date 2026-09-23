import 'package:flutter/material.dart';

import '../models.dart';
import '../services/repo.dart';

/// Streams the program and business behind a card and hands them to [builder]
/// once both are available.
class CardData extends StatefulWidget {
  const CardData({super.key, required this.card, required this.builder, this.placeholder});

  final LoyaltyCard card;
  final Widget Function(BuildContext context, Program program, Business business) builder;
  final Widget? placeholder;

  @override
  State<CardData> createState() => _CardDataState();
}

class _CardDataState extends State<CardData> {
  late Stream<Program?> _program;
  late Stream<Business?> _business;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(CardData old) {
    super.didUpdateWidget(old);
    if (old.card.programId != widget.card.programId || old.card.businessId != widget.card.businessId) _subscribe();
  }

  void _subscribe() {
    _program = repo.program(widget.card.programId);
    _business = repo.business(widget.card.businessId);
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Program?>(
    stream: _program,
    builder: (context, programSnap) => StreamBuilder<Business?>(
      stream: _business,
      builder: (context, businessSnap) {
        final program = programSnap.data;
        final business = businessSnap.data;
        if (program == null || business == null) {
          return widget.placeholder ?? const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
        }
        return widget.builder(context, program, business);
      },
    ),
  );
}
