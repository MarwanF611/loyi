import 'dart:typed_data';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

Future<void> saveFile(String name, Uint8List bytes, {required String mimeType, Rect? origin}) =>
    SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: mimeType, name: name)],
        fileNameOverrides: [name],
        sharePositionOrigin: origin,
      ),
    );
