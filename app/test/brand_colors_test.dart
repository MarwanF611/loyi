import 'package:flutter_test/flutter_test.dart';
import 'package:loyi/models.dart';

void main() {
  test('one brand colour: a solid card with white stamps', () {
    final d = CardDesign.fromBrand([0xFFFF5A3C]);
    expect([d.background, d.background2, d.style, d.stampColor], [0xFFFF5A3C, null, CardStyle.solid, 0xFFFFFFFF]);
  });

  test('two colours: a gradient', () {
    final d = CardDesign.fromBrand([0xFF263238, 0xFF00897B]);
    expect([d.background, d.background2, d.style], [0xFF263238, 0xFF00897B, CardStyle.gradient]);
  });

  test('three colours: the third colours the stamps', () {
    expect(CardDesign.fromBrand([1, 2, 3]).stampColor, 3);
  });

  test('a business without chosen colours falls back to its main colour', () {
    const b = Business(id: 'b', name: 'Shop', ownerUid: 'u', color: 0xFF123456);
    expect(b.brandColors, [0xFF123456]);
    const c = Business(id: 'b', name: 'Shop', ownerUid: 'u', color: 1, colors: [7, 8]);
    expect(c.brandColors, [7, 8]);
  });
}
