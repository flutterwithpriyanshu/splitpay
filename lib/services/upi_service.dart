import 'package:flutter/services.dart';
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
    // canLaunchUrl is unreliable on Android 11+ (package visibility).
    // Launch directly, treat false / ACTIVITY_NOT_FOUND as no app.
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return launched ? UpiLaunchResult.launched : UpiLaunchResult.noAppFound;
    } on PlatformException catch (e) {
      if (e.code == 'ACTIVITY_NOT_FOUND') return UpiLaunchResult.noAppFound;
      return UpiLaunchResult.failed;
    } catch (_) {
      return UpiLaunchResult.failed;
    }
  }
}
