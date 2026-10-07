import 'document_language_native.dart' if (dart.library.js_interop) 'document_language_web.dart' as impl;

/// Sets `<html lang>` on the web; nothing to do in the apps.
void setDocumentLanguage(String code) => impl.setDocumentLanguage(code);
