import 'package:flutter_test/flutter_test.dart';
import 'package:loyi/models.dart';

void main() {
  test('Belgian company numbers: format and mod-97 check digits', () {
    expect(BusinessDetails.normalizeCompanyNumber('BE', '0123.456.749'), '0123.456.749');
    expect(BusinessDetails.normalizeCompanyNumber('BE', 'BE 0123 456 749'), '0123.456.749');
    expect(BusinessDetails.normalizeCompanyNumber('BE', '123456749'), '0123.456.749'); // old 9-digit form
    expect(BusinessDetails.normalizeCompanyNumber('BE', '0123.456.748'), isNull); // wrong check digits
    expect(BusinessDetails.normalizeCompanyNumber('BE', '0123.456'), isNull);
    expect(BusinessDetails.normalizeCompanyNumber('BE', '2123.456.749'), isNull);
    expect(BusinessDetails.normalizeCompanyNumber('NL', ' 12345678 '), '12345678');
    expect(BusinessDetails.normalizeCompanyNumber('NL', ''), isNull);
  });

  test('VAT numbers: EU format, and BE + company number in Belgium', () {
    expect(BusinessDetails.normalizeVat('BE', 'be 0123.456.749', '0123456749'), 'BE0123456749');
    expect(BusinessDetails.normalizeVat('BE', 'BE0999999999', '0123456749'), isNull);
    expect(BusinessDetails.normalizeVat('NL', 'NL123456789B01', '12345678'), 'NL123456789B01');
    expect(BusinessDetails.normalizeVat('NL', '123', '12345678'), isNull);
  });

  test('postcodes per country', () {
    expect(BusinessDetails.validPostcode('BE', '9000'), isTrue);
    expect(BusinessDetails.validPostcode('BE', '90000'), isFalse);
    expect(BusinessDetails.validPostcode('NL', '1234 ab'), isTrue);
    expect(BusinessDetails.validPostcode('LU', 'L-1234'), isTrue);
    expect(BusinessDetails.validPostcode('FR', '75001'), isTrue);
    expect(BusinessDetails.validPostcode('DE', '1011'), isFalse);
  });

  test('complete only with every required field valid', () {
    const ok = BusinessDetails(
      legalName: 'Bakkerij Peeters BV',
      street: 'Kerkstraat 1',
      postcode: '9000',
      city: 'Gent',
      country: 'BE',
      companyNumber: '0123.456.749',
    );
    expect(ok.complete, isTrue);
    expect(BusinessDetails.fromMap({...ok.toMap(), 'city': ''}).complete, isFalse);
    expect(BusinessDetails.fromMap({...ok.toMap(), 'vatNumber': 'BE0999999999'}).complete, isFalse);
    expect(BusinessDetails.fromMap({...ok.toMap(), 'vatNumber': 'BE0123456749'}).complete, isTrue);
  });
}
