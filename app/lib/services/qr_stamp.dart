import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The token in a counter-screen QR code ("Stempel uitdelen"): `<period>-<n>-<signature>`, where the signature is the
/// first 16 bytes of HMAC-SHA256(secret, "programId:period:n") in base64url. billing-worker's qrClaim checks it the
/// same way (qrSignature in billing-worker/src/index.js).
String qrStampToken(String secret, String programId, int period, int n) {
  final mac = Hmac(sha256, utf8.encode(secret)).convert(utf8.encode('$programId:$period:$n')).bytes.sublist(0, 16);
  return '$period-$n-${base64Url.encode(mac).replaceAll('=', '')}';
}
