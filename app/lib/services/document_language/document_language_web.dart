import 'package:web/web.dart' as web;

void setDocumentLanguage(String code) => web.document.documentElement?.setAttribute('lang', code);
