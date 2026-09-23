import 'package:flutter/foundation.dart';

/// Connect to the local Firebase emulators:
///   flutter run -d chrome --dart-define=USE_EMULATORS=true
const useEmulators = bool.fromEnvironment('USE_EMULATORS');

/// `localhost` works for web and the iOS simulator; the Android emulator needs `10.0.2.2`.
const emulatorHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');

const functionsRegion = 'europe-west1';

/// Base URL written onto NFC tags. On web we use wherever the app is served from.
String get publicBaseUrl =>
    kIsWeb ? Uri.base.origin : const String.fromEnvironment('PUBLIC_BASE_URL', defaultValue: 'https://loyi.web.app');

String tagUrl(String tagId) => '$publicBaseUrl/t/$tagId';
