import 'screen_awake_native.dart' if (dart.library.js_interop) 'screen_awake_web.dart' as impl;

/// Keeps the screen from dimming while [on] (the counter screen with the QR code). Best effort: browsers without the
/// Screen Wake Lock API, or a page in the background, simply ignore it.
Future<void> keepScreenAwake(bool on) => impl.keepScreenAwake(on);
