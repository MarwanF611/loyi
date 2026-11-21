import 'dart:js_interop';
import 'dart:js_interop_unsafe';

JSObject? _sentinel;

Future<void> keepScreenAwake(bool on) async {
  try {
    if (!on) {
      final sentinel = _sentinel;
      _sentinel = null;
      if (sentinel != null) await sentinel.callMethod<JSPromise<JSAny?>>('release'.toJS).toDart;
      return;
    }
    final navigator = globalContext['navigator'] as JSObject;
    if (!navigator.has('wakeLock')) return;
    final wakeLock = navigator['wakeLock'] as JSObject;
    _sentinel = await wakeLock.callMethod<JSPromise<JSObject>>('request'.toJS, 'screen'.toJS).toDart;
  } catch (_) {
    // Refused (battery saver, page hidden): the screen just dims as usual.
  }
}
