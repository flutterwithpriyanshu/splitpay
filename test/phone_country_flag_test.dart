import 'package:flutter_test/flutter_test.dart';
import 'package:splitpay/core/phone_country_flag.dart';

void main() {
  group('phoneCountryFlag', () {
    test('detects the flag from an international calling code', () {
      expect(phoneCountryFlag(countryCode: '+44', phoneNumber: ''), '🇬🇧');
    });

    test('detects a different country from its calling code', () {
      expect(
        phoneCountryFlag(countryCode: '+61', phoneNumber: ''),
        '🇦🇺',
      );
    });

    test('returns null for empty or unrecognized country codes', () {
      expect(phoneCountryFlag(countryCode: '+', phoneNumber: ''), isNull);
      expect(phoneCountryFlag(countryCode: '+999', phoneNumber: ''), isNull);
    });
  });
}
