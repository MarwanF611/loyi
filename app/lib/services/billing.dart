import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import 'api.dart';
import 'auth_service.dart';
import 'language.dart';

/// Business subscriptions through Stripe, sold on the website only.
///
/// The billing server (billing-worker/) creates Stripe Checkout and customer
/// portal sessions, and turns Stripe's webhooks into `subscriptions/{uid}`,
/// which is what the dashboard and tags follow. The native apps are free
/// companions: they show the status but never sell (App Store rule 3.1.3).
class Billing {
  /// False in builds without a billing server, such as local emulator builds.
  bool get available => billingApiUrl.isNotEmpty;

  /// Buying and managing the subscription happens in the browser.
  bool get canManageHere => kIsWeb && available;

  /// Sends the shop to Stripe Checkout; Stripe returns it to /business?checkout=done.
  Future<void> startCheckout() async => _go(await _post('/checkout'));

  /// Stripe's customer portal: change card, download invoices, cancel.
  Future<void> openPortal() async => _go(await _post('/portal'));

  /// Account deletion: cancel the subscription so the shop is never charged again.
  Future<void> cancelForAccountDeletion() async {
    if (!available) return;
    await _post('/delete-account');
  }

  Future<Map<String, dynamic>> _post(String path) async {
    final token = await auth.user?.getIdToken();
    if (token == null) throw LoyiException(l10n.signInFirst);
    final http.Response res;
    try {
      // The language makes Stripe's checkout and billing pages match the app.
      final uri = Uri.parse('$billingApiUrl$path').replace(queryParameters: {'locale': language.code});
      res = await http.post(uri, headers: {'Authorization': 'Bearer $token'});
    } catch (_) {
      throw LoyiException(l10n.noConnection);
    }
    final body = jsonDecode(res.body.isEmpty ? '{}' : res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw LoyiException(switch ((res.statusCode, path)) {
        (401, _) => l10n.signInAgain,
        (403, _) => l10n.onlyBusinessCanSubscribe,
        (409, '/checkout') => l10n.alreadySubscribed,
        (404, '/portal') => l10n.noSubscriptionToManage,
        _ => l10n.somethingWentWrong,
      });
    }
    return body;
  }

  Future<void> _go(Map<String, dynamic> body) async {
    final url = body['url'] as String?;
    if (url == null) throw LoyiException(l10n.somethingWentWrong);
    // Same tab on the web, so Stripe brings the shop back into Loyi.
    await launchUrl(Uri.parse(url), webOnlyWindowName: '_self', mode: LaunchMode.externalApplication);
  }
}

final billing = Billing();
