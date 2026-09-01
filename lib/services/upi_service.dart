import 'package:url_launcher/url_launcher.dart';

enum UpiLaunchResult { launched, noAppFound, failed }

class UpiService {
  static Uri buildUpiUri({
    required String upiId,
    required String receiverName,
    required double amount,
  }) {
    final amountStr = amount.toStringAsFixed(2);
    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': upiId,
        'pn': receiverName,
        'am': amountStr,
        'cu': 'INR',
      },
    );
  }

  static Future<UpiLaunchResult> launchUpiPayment({
    required String upiId,
    required String receiverName,
    required double amount,
  }) async {
    final uri = buildUpiUri(
      upiId: upiId,
      receiverName: receiverName,
      amount: amount,
    );
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) return UpiLaunchResult.noAppFound;
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return launched ? UpiLaunchResult.launched : UpiLaunchResult.failed;
    } catch (_) {
      return UpiLaunchResult.failed;
    }
  }
}
