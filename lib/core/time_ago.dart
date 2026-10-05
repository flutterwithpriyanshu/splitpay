import 'package:splitpay/core/app_date_format.dart';

String clockText(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
}

/// "Just now", "12m ago", "2h ago", "Yesterday, 6:30 PM", "3 days ago".
String timeAgo(DateTime t) {
  final now = DateTime.now();
  final diff = now.difference(t);
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final dayDiff = today.difference(day).inDays;

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (dayDiff == 0) return '${diff.inHours}h ago';
  if (dayDiff == 1) return 'Yesterday, ${clockText(t)}';
  if (dayDiff < 7) return '$dayDiff days ago';
  return formatDate(t);
}
