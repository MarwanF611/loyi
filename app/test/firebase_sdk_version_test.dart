import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reads firebase_core_web's `supportedFirebaseJsSdkVersion` from its source
/// (the library itself only compiles for the web).
String flutterFireJsSdkVersion() {
  final config = jsonDecode(File('.dart_tool/package_config.json').readAsStringSync()) as Map<String, dynamic>;
  final package = (config['packages'] as List).cast<Map<String, dynamic>>().firstWhere(
    (p) => p['name'] == 'firebase_core_web',
  );
  final root = Uri.parse('${package['rootUri']}/').resolve('lib/src/firebase_sdk_version.dart');
  final source = File.fromUri(
    root.isAbsolute ? root : Directory('.dart_tool').absolute.uri.resolveUri(root),
  ).readAsStringSync();
  return RegExp(r"supportedFirebaseJsSdkVersion = '([^']+)'").firstMatch(source)!.group(1)!;
}

void main() {
  test('web/firebase_sdk.js loads the Firebase JS SDK version FlutterFire expects', () {
    final script = File('web/firebase_sdk.js').readAsStringSync();
    final version = RegExp(r'const v = "([^"]+)"').firstMatch(script)?.group(1);
    expect(
      version,
      flutterFireJsSdkVersion(),
      reason: 'Update `const v` in web/firebase_sdk.js after upgrading the Firebase packages.',
    );
  });

  test('that SDK version is vendored, without references to Google\'s CDN', () {
    final version = RegExp(r'const v = "([^"]+)"').firstMatch(File('web/firebase_sdk.js').readAsStringSync())!.group(1);
    for (final name in ['app', 'auth', 'firestore-pipelines', 'app-check']) {
      final file = File('web/firebase/$version/firebase-$name.js');
      expect(file.existsSync(), isTrue, reason: 'Run ./scripts/vendor-firebase-sdk.sh $version');
      expect(file.readAsStringSync(), isNot(contains('www.gstatic.com/firebasejs')), reason: file.path);
    }
  });
}
