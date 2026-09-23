import 'package:flutter/material.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/repo.dart';

/// Streams the signed-in owner's business. [builder] gets `null` when the
/// owner has not created one yet.
class BusinessScope extends StatefulWidget {
  const BusinessScope({super.key, required this.builder});

  final Widget Function(BuildContext context, Business? business) builder;

  @override
  State<BusinessScope> createState() => _BusinessScopeState();
}

class _BusinessScopeState extends State<BusinessScope> {
  late final Stream<Business?> _business = repo.businessForOwner(auth.user!.uid);

  @override
  Widget build(BuildContext context) => StreamBuilder<Business?>(
    stream: _business,
    builder: (context, snap) {
      if (snap.hasError) return Scaffold(body: Center(child: Text('Could not load your business.\n${snap.error}')));
      if (!snap.hasData && snap.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return widget.builder(context, snap.data);
    },
  );
}
