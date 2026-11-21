import 'home_screen_native.dart' if (dart.library.js_interop) 'home_screen_web.dart' as impl;

/// Loyi runs from the home screen (an installed web app), not in a browser tab.
bool get isStandalone => impl.isStandalone();

/// The browser can show its own install dialog (Android Chrome).
bool get canPromptInstall => impl.canPromptInstall();

/// Shows the browser's install dialog; true when the customer installed Loyi.
Future<bool> promptInstall() => impl.promptInstall();
