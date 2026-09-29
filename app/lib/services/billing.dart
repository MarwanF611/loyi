import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config.dart';

/// Business subscriptions through RevenueCat: App Store and Google Play in the
/// app, RevenueCat Web Billing on the website when a web key is configured.
///
/// The app only uses RevenueCat to buy, restore and show the status right away.
/// What actually switches a business's tags on is `subscriptions/{uid}` in
/// Firestore, written by billing-worker/ from RevenueCat's webhook.
class Billing {
  /// RevenueCat entitlement that unlocks Loyi for a business.
  static const entitlementId = 'business';

  String get _apiKey {
    if (kIsWeb) return revenueCatWebKey;
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => revenueCatAppleKey,
      TargetPlatform.android => revenueCatGoogleKey,
      _ => '',
    };
  }

  /// False in builds without a RevenueCat key, such as local emulator builds.
  bool get available => _apiKey.isNotEmpty && !useEmulators;

  bool _configured = false;
  String? _userId;
  CustomerInfo? _last;
  final _updates = StreamController<CustomerInfo?>.broadcast();

  /// Latest known customer info, then every change.
  Stream<CustomerInfo?> get customerInfo async* {
    yield _last;
    yield* _updates.stream;
  }

  CustomerInfo? get lastCustomerInfo => _last;

  void _emit(CustomerInfo? info) {
    _last = info;
    _updates.add(info);
  }

  /// Links purchases to the business owner's Firebase uid (the webhook uses it
  /// to find the Firestore document). Safe to call repeatedly.
  Future<void> identify(String uid) async {
    if (!available || _userId == uid) return;
    _userId = uid;
    try {
      if (_configured) {
        _emit((await Purchases.logIn(uid)).customerInfo);
      } else {
        await Purchases.configure(PurchasesConfiguration(_apiKey)..appUserID = uid);
        _configured = true;
        Purchases.addCustomerInfoUpdateListener(_emit);
        _emit(await Purchases.getCustomerInfo());
      }
    } catch (e) {
      _userId = null;
      debugPrint('RevenueCat setup failed: $e');
    }
  }

  Future<void> signOut() async {
    if (!_configured || _userId == null) return;
    _userId = null;
    _emit(null);
    try {
      await Purchases.logOut();
    } catch (_) {
      // Already anonymous in RevenueCat.
    }
  }

  static bool isActive(CustomerInfo? info) => info?.entitlements.active.containsKey(entitlementId) ?? false;

  /// The monthly plan from RevenueCat's current offering, with the store's localized price.
  Future<Package?> monthlyPackage() async {
    final offering = (await Purchases.getOfferings()).current;
    return offering?.monthly ?? offering?.availablePackages.firstOrNull;
  }

  /// Buys [package]. Returns false when the user cancelled. [email] pre-fills web checkout.
  Future<bool> purchase(Package package, {String? email}) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package, customerEmail: kIsWeb ? email : null));
      _emit(result.customerInfo);
      return isActive(result.customerInfo);
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }

  /// Restores an App Store / Google Play subscription bought earlier. Returns true if it's active.
  Future<bool> restore() async {
    final info = await Purchases.restorePurchases();
    _emit(info);
    return isActive(info);
  }

  /// Store page where the subscription can be changed or cancelled.
  String? get managementUrl => _last?.managementURL;
}

/// Readable message for a failed purchase or restore.
String billingError(Object error) {
  if (error is PlatformException) {
    return switch (PurchasesErrorHelper.getErrorCode(error)) {
      PurchasesErrorCode.networkError => 'No connection. Check your internet and try again.',
      PurchasesErrorCode.purchaseNotAllowedError => 'Purchases are not allowed on this device.',
      PurchasesErrorCode.paymentPendingError => 'Your payment is pending. Loyi switches on as soon as it goes through.',
      PurchasesErrorCode.productAlreadyPurchasedError => 'You already have this subscription. Tap "Restore purchases".',
      PurchasesErrorCode.storeProblemError => 'The store is having trouble. Please try again in a moment.',
      _ => 'The purchase didn\'t go through. Please try again.',
    };
  }
  return 'Something went wrong. Please try again.';
}

final billing = Billing();
