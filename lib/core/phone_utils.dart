/// Normalizes a phone number so the same person's number matches
/// regardless of how it was entered (with country code, leading 0,
/// spaces, dashes, etc).
///
/// Strips everything except digits, then keeps only the last 10 digits
/// (standard local mobile number length). This means:
///   "+91 98765 43210" -> "9876543210"
///   "09876543210"      -> "9876543210"
///   "98765-43210"      -> "9876543210"
///   "9876543210"       -> "9876543210"
String normalizePhone(String raw) {
  final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.length > 10) {
    return digitsOnly.substring(digitsOnly.length - 10);
  }
  return digitsOnly;
}
