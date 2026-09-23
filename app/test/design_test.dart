import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loyi/models.dart';
import 'package:loyi/services/repo.dart';
import 'dart:typed_data';

void main() {
  test('text is white on dark cards and dark on light cards', () {
    expect(const CardDesign(background: 0xFF263238).textColor, Colors.white);
    expect(const CardDesign(background: 0xFFFFF3E0).textColor, isNot(Colors.white));
  });

  test('white stamps use the card colour for the icon, unless the card is light', () {
    const dark = CardDesign(background: 0xFF263238);
    expect(dark.stampIconColor, dark.backgroundColor);
    const light = CardDesign(background: 0xFFFFF3E0);
    expect(light.stampIconColor, isNot(light.backgroundColor));
  });

  test('design survives a Firestore round-trip', () {
    const d = CardDesign(
      background: 0xFF6D4C41,
      background2: 0xFF3E2723,
      style: CardStyle.pattern,
      stampColor: 0xFFFFD699,
      stampIcon: 'coffee',
    );
    final back = CardDesign.fromMap(d.toMap());
    expect(back.toMap(), d.toMap());
  });

  test('programs without a design fall back to the business colour', () {
    const business = Business(id: 'b', name: 'Mokka', ownerUid: 'o', color: 0xFF263238);
    const program = Program(
      id: 'p',
      businessId: 'b',
      ownerUid: 'o',
      name: 'Koffiekaart',
      stampsRequired: 8,
      stampCooldownMinutes: 0,
      rewards: [],
      active: true,
    );
    expect(program.designFor(business).background, 0xFF263238);
  });

  test('logo type is detected from file bytes', () {
    expect(imageContentType(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0])), 'image/png');
    expect(imageContentType(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])), 'image/jpeg');
    expect(imageContentType(Uint8List.fromList('<svg xmlns="">'.codeUnits)), isNull);
  });
}
