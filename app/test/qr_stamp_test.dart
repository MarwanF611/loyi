import 'package:flutter_test/flutter_test.dart';
import 'package:loyi/services/qr_stamp.dart';

void main() {
  test('QR codes are signed exactly like the billing server checks them', () {
    // Computed with qrSignature() in billing-worker/src/index.js.
    expect(
      qrStampToken('s3cretS3cretS3cretS3cretS3cretS3cret1234', 'peeters-broodjeskaart', 117426240, 3),
      '117426240-3-R-wslTaiZmBIoN9vZb3yRw',
    );
  });

  test('every scan in a period gets its own code', () {
    final a = qrStampToken('secret', 'card', 10, 0);
    final b = qrStampToken('secret', 'card', 10, 1);
    expect(a, isNot(b));
    expect(RegExp(r'^\d+-\d+-[A-Za-z0-9_-]{22}$').hasMatch(a), isTrue);
  });
}
