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
    _configuredBaseUrl.isNotEmpty ? _configuredBaseUrl : (kIsWeb ? Uri.base.origin : 'https://loyi.web.app');

String tagUrl(String tagId) => '$publicBaseUrl/t/$tagId';
