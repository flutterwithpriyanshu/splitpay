import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? toDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
