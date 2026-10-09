import 'package:flutter/foundation.dart';

import 'services/language.dart';

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

/// Loyi's billing server (billing-worker/ on Cloudflare), e.g. https://loyi-billing.you.workers.dev.
/// Empty → subscriptions are unavailable in this build.
const billingApiUrl = String.fromEnvironment('BILLING_API_URL');

/// Shown next to the Subscribe button; Stripe's checkout shows the exact amount incl. VAT.
const subscriptionPrice = String.fromEnvironment('SUBSCRIPTION_PRICE', defaultValue: '€19');

/// Free days before the first payment; the billing server's TRIAL_DAYS decides, this is for the texts.
const trialDays = int.fromEnvironment('TRIAL_DAYS', defaultValue: 14);

/// reCAPTCHA v3 site key for Firebase App Check on the web. Empty → App Check off on web.
const appCheckWebKey = String.fromEnvironment('APP_CHECK_WEB_KEY');

/// Legal pages, served as static files from Firebase Hosting (app/web/*.html):
/// Dutch at the root, French and English under /fr and /en.
const legalBaseUrl = 'https://loyi-b530b.web.app';
String get _legalLanguagePrefix => language.code == 'nl' ? '' : '/${language.code}';
String get privacyUrl => '$legalBaseUrl$_legalLanguagePrefix/privacy';
String get termsUrl => '$legalBaseUrl$_legalLanguagePrefix/terms';
const supportEmail = String.fromEnvironment('SUPPORT_EMAIL', defaultValue: 'marwan.fikri20@gmail.com');
