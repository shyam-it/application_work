import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/worker.dart';
import 'package:flutter/foundation.dart';

class WorkerService {
  WorkerService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  CollectionReference<Map<String, dynamic>> get _workers =>
      _db.collection('workers');

  Future<String> _role() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please sign in first.');
    final doc = await _db.collection('users').doc(user.uid).get();
    return (doc.data()?['role'] as String? ?? '').toLowerCase();
  }

  Future<void> _requireManager() async {
    final role = await _role();
    if (role != 'owner' && role != 'member') {
      throw Exception('Only Owner or Member can manage workers.');
    }
  }

  Stream<List<Worker>> watchWorkers({bool activeOnly = true}) {
    Query<Map<String, dynamic>> query = _workers;

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query
        .snapshots()
        .map((snapshot) {
          debugPrint('Workers loaded: ${snapshot.docs.length}');

          return snapshot.docs
              .map((doc) => Worker.fromMap(doc.id, doc.data()))
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
        })
        .handleError((Object error, StackTrace stackTrace) {
          debugPrint('WORKERS FIRESTORE ERROR: $error');
          debugPrintStack(stackTrace: stackTrace);
        });
  }

  Future<void> addWorker({
    required String name,
    required String phone,
    String? uid,
  }) async {
    await _requireManager();
    final cleanName = name.trim();
    final cleanPhone = phone.trim();
    if (cleanName.isEmpty) throw ArgumentError('Worker name is required.');
    if (!RegExp(r'^\d{10}$').hasMatch(cleanPhone)) {
      throw ArgumentError('Enter a valid 10-digit phone number.');
    }
    final duplicate = await _workers
        .where('phone', isEqualTo: cleanPhone)
        .limit(1)
        .get();
    if (duplicate.docs.isNotEmpty)
      throw ArgumentError('This phone number already exists.');
    final doc = _workers.doc();
    await doc.set({
      'name': cleanName,
      'phone': cleanPhone,
      'uid': uid?.trim().isEmpty == true ? null : uid?.trim(),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _auth.currentUser!.uid,
    });
  }

  Future<void> updateWorker(
    Worker worker, {
    required String name,
    required String phone,
    String? uid,
  }) async {
    await _requireManager();
    if (name.trim().isEmpty) throw ArgumentError('Worker name is required.');
    if (!RegExp(r'^\d{10}$').hasMatch(phone.trim()))
      throw ArgumentError('Enter a valid 10-digit phone number.');
    await _workers.doc(worker.id).update({
      'name': name.trim(),
      'phone': phone.trim(),
      'uid': uid?.trim().isEmpty == true ? null : uid?.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser!.uid,
    });
  }

  Future<void> deactivateWorker(String id) async {
    await _requireManager();
    await _workers.doc(id).update({
      'isActive': false,
      'deactivatedAt': FieldValue.serverTimestamp(),
      'deactivatedBy': _auth.currentUser!.uid,
    });
  }
}
