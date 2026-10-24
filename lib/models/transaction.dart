class PaymentTransaction {
  final String id;
  final String workerId;
  final String type;
  final double amount;
  final String method;
  final String note;
  final DateTime date;

  const PaymentTransaction({
    required this.id,
    required this.workerId,
    required this.type,
    required this.amount,
    required this.method,
    required this.note,
    required this.date,
  });
}
