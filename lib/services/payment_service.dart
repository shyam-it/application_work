import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart';
import '../models/worker.dart';

class PaymentService {
  PaymentService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  CollectionReference<Map<String, dynamic>> get _transactions =>
      _db.collection('transactions');

  Future<void> _requireManager() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please sign in first.');
    final d = await _db.collection('users').doc(user.uid).get();
    final role = (d.data()?['role'] as String? ?? '').toLowerCase();
    if (role != 'owner' && role != 'member')
      throw Exception('Only Owner or Member can manage payments.');
  }

  Stream<List<PaymentTransaction>> watchTransactions() => _transactions
      .orderBy('date', descending: true)
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => PaymentTransaction.fromMap(d.id, d.data()))
            .toList(),
      );

  Stream<List<PaymentTransaction>> watchMyApprovedTransactions() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _transactions
        .where('workerUid', isEqualTo: uid)
        .where('approved', isEqualTo: true)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => PaymentTransaction.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> addTransaction({
    required Worker worker,
    required String type,
    required double amount,
    required String method,
    required String note,
    required bool approved,
    DateTime? date,
  }) async {
    await _requireManager();
    if (amount <= 0) throw ArgumentError('Amount must be greater than zero.');
    if (!['Salary', 'Advance', 'Credit', 'Debit', 'Deposit'].contains(type))
      throw ArgumentError('Invalid transaction type.');
    await _transactions.add({
      'workerId': worker.id,
      'workerUid': worker.uid ?? '',
      'workerName': worker.name,
      'type': type,
      'amount': amount,
      'method': method,
      'note': note.trim(),
      'date': Timestamp.fromDate(date ?? DateTime.now()),
      'approved': approved,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _auth.currentUser!.uid,
    });
  }

  Future<void> setApproved(
    PaymentTransaction transaction,
    bool approved,
  ) async {
    await _requireManager();
    await _transactions.doc(transaction.id).update({
      'approved': approved,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser!.uid,
    });
  }
}
