import 'package:cloud_functions/cloud_functions.dart';
import 'package:splitpay/core/bill_saved_data.dart';

class UpiLinkResult {
  const UpiLinkResult({
    required this.noUpiId,
    required this.sent,
    required this.skipped,
  });

  final bool noUpiId;
  final int sent;
  final int skipped;
}

class UpiLinkService {
  static final _functions = FirebaseFunctions.instance;

  static Future<UpiLinkResult> send({
    required String billTitle,
    required List<BillSavedRow> rows,
  }) async {
    final callable = _functions.httpsCallable('sendUpiLink');
    final response = await callable.call({
      'billTitle': billTitle,
      'rows': [
        for (final row in rows)
          {'linkedUid': row.linkedUid, 'amount': row.amount},
      ],
    });
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Invalid UPI link response from server.');
    }
    final noUpiId = data['noUpiId'];
    final sent = data['sent'];
    final skipped = data['skipped'];
    if (noUpiId is! bool || sent is! num || skipped is! num) {
      throw const FormatException('Invalid UPI link response from server.');
    }
    return UpiLinkResult(
      noUpiId: noUpiId,
      sent: sent.toInt(),
      skipped: skipped.toInt(),
    );
  }
}
