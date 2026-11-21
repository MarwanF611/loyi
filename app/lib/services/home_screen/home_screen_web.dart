import 'dart:js_interop';
import 'dart:js_interop_unsafe';

// The functions come from web/install.js; a page served without it (an old cached shell) offers nothing.
bool _has(String name) => globalContext.has(name);

bool isStandalone() => _has('loyiIsStandalone') && globalContext.callMethod<JSBoolean>('loyiIsStandalone'.toJS).toDart;

bool canPromptInstall() => _has('loyiCanInstall') && globalContext.callMethod<JSBoolean>('loyiCanInstall'.toJS).toDart;

Future<bool> promptInstall() async {
  if (!_has('loyiPromptInstall')) return false;
  final accepted = await globalContext.callMethod<JSPromise<JSBoolean>>('loyiPromptInstall'.toJS).toDart;
  return accepted.toDart;
}
