import 'dart:typed_data';
import 'dart:ui';

import 'save_file_native.dart' if (dart.library.js_interop) 'save_file_web.dart' as impl;

/// Hands a generated file to the user: a download in the browser, the share
/// sheet (Save to Files, Mail, …) in the app. [origin] anchors the iPad popover.
Future<void> saveFile(String name, Uint8List bytes, {required String mimeType, Rect? origin}) =>
    impl.saveFile(name, bytes, mimeType: mimeType, origin: origin);
