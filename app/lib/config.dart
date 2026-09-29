import 'package:flutter/foundation.dart';

/// Connect to the local Firebase emulators:
///   flutter run -d chrome --dart-define=USE_EMULATORS=true
const useEmulators = bool.fromEnvironment('USE_EMULATORS');

/// `localhost` works for web and the iOS simulator; the Android emulator needs `10.0.2.2`.
const emulatorHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');

const _configuredBaseUrl = String.fromEnvironment('PUBLIC_BASE_URL');

/// Base URL written onto NFC tags, e.g. `--dart-define=PUBLIC_BASE_URL=https://loyi.be`.
/// Without it, web uses wherever the app is served from.
String get publicBaseUrl =>
    _configuredBaseUrl.isNotEmpty ? _configuredBaseUrl : (kIsWeb ? Uri.base.origin : 'https://loyi-b530b.web.app');

String tagUrl(String tagId) => '$publicBaseUrl/t/$tagId';

// ── Production keys ─────────────────────────────────────────────────────────
// Set in config/prod.json and passed with `--dart-define-from-file=config/prod.json`.
// All of these are public client keys (they ship inside the app), not secrets.

/// RevenueCat public SDK keys. Empty → subscriptions are unavailable in this build.
const revenueCatAppleKey = String.fromEnvironment('REVENUECAT_APPLE_KEY');
const revenueCatGoogleKey = String.fromEnvironment('REVENUECAT_GOOGLE_KEY');

/// RevenueCat Web Billing key (needs Stripe connected in RevenueCat). Empty →
/// businesses on the website are asked to subscribe in the app.
const revenueCatWebKey = String.fromEnvironment('REVENUECAT_WEB_KEY');

/// reCAPTCHA v3 site key for Firebase App Check on the web. Empty → App Check off on web.
const appCheckWebKey = String.fromEnvironment('APP_CHECK_WEB_KEY');

/// Legal pages, served as static files from Firebase Hosting (app/web/*.html).
const legalBaseUrl = 'https://loyi-b530b.web.app';
const privacyUrl = '$legalBaseUrl/privacy';
const termsUrl = '$legalBaseUrl/terms';
const supportEmail = String.fromEnvironment('SUPPORT_EMAIL', defaultValue: 'support@loyi.be');
