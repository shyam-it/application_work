import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentTransaction {
  final String id;
  final String workerId;
  final String workerUid;
  final String workerName;
  final String type;
  final double amount;
  final String method;
  final String note;
  final DateTime date;
  final bool approved;

  const PaymentTransaction({
    required this.id,
    required this.workerId,
    required this.workerUid,
    required this.workerName,
    required this.type,
    required this.amount,
    required this.method,
    required this.note,
    required this.date,
    this.approved = false,
  });

  factory PaymentTransaction.fromMap(String id, Map<String, dynamic> map) {
    final rawDate = map['date'];
    return PaymentTransaction(
      id: id,
      workerId: map['workerId'] as String? ?? '',
      workerUid: map['workerUid'] as String? ?? '',
      workerName: map['workerName'] as String? ?? '',
      type: map['type'] as String? ?? 'Credit',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      method: map['method'] as String? ?? 'Cash',
      note: map['note'] as String? ?? '',
      date: rawDate is Timestamp
          ? rawDate.toDate()
          : rawDate is DateTime
          ? rawDate
          : DateTime.now(),
      approved: map['approved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'workerId': workerId,
    'workerUid': workerUid,
    'workerName': workerName,
    'type': type,
    'amount': amount,
    'method': method,
    'note': note,
    'date': date,
    'approved': approved,
  };
}
