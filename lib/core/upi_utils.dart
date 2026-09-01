/// Format-only check for a UPI VPA like "name@bankhandle".
/// This does NOT confirm the account exists or belongs to anyone —
/// real name-verification needs a paid PSP/gateway API (Cashfree,
/// Razorpay, Decentro, etc.) with a backend, which this app doesn't use.
final RegExp _upiPattern = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');

bool isValidUpiFormat(String value) {
  return _upiPattern.hasMatch(value.trim());
}