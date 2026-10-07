import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../account/account_privacy.dart';
import '../services/language.dart';
import '../theme.dart';

/// Account & privacy for business owners. Reachable during sign-up too, so an
/// unpaid account can always be inspected or deleted.
class BusinessAccountPage extends StatelessWidget {
  const BusinessAccountPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.accountAndPrivacy),
      leading: BackButton(onPressed: () => context.go('/business')),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        PageBody(
          maxWidth: 560,
          child: AccountPrivacySections(
            business: true,
            onDeleted: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.accountDeleted)));
              context.go('/business/login');
            },
          ),
        ),
      ],
    ),
  );
}
