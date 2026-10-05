import 'package:phone_numbers_parser/phone_numbers_parser.dart';

String? phoneCountryFlag({
  required String countryCode,
  required String phoneNumber,
}) {
  final codeDigits = countryCode.replaceAll(RegExp(r'\D'), '');
  if (codeDigits.isEmpty) return null;

  final numberDigits = phoneNumber.replaceAll(RegExp(r'\D'), '');
  if (numberDigits.isNotEmpty) {
    try {
      return _flagForIsoCode(
        PhoneNumber.parse('+$codeDigits$numberDigits').isoCode,
      );
    } on PhoneNumberException {
      // Incomplete or unknown input is normal while the user is typing.
    }
  }

  try {
    // Shared calling codes use their default region until the number
    // identifies a more specific territory.
    return _flagForIsoCode(
      PhoneNumber.parse('+${codeDigits}0000000000').isoCode,
    );
  } on PhoneNumberException {
    return null;
  }
}

String _flagForIsoCode(IsoCode isoCode) {
  return String.fromCharCodes(
    isoCode.name.codeUnits.map((letter) => 0x1F1E6 + letter - 0x41),
  );
}
