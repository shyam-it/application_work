import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attendance_record.dart';

class AttendanceService {
  AttendanceService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<String> _role() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please sign in first.');
    final d = await _db.collection('users').doc(user.uid).get();
    return (d.data()?['role'] as String? ?? '').toLowerCase();
  }

  Future<void> save({
    required String workerId,
    required String workerUid,
    required String workerName,
    required String date,
    required String status,
    required List<SiteWorkTime> siteWorkTimes,
  }) async {
    final role = await _role();
    if (role != 'owner' && role != 'member')
      throw Exception('Only Owner or Member can mark attendance.');
    if (!['Present', 'Absent', 'Half-day'].contains(status))
      throw ArgumentError('Invalid attendance status.');
    if (status == 'Absent' && siteWorkTimes.isNotEmpty)
      throw ArgumentError('Absent workers cannot have site work times.');
    if (status != 'Absent' && siteWorkTimes.isEmpty)
      throw ArgumentError('Select at least one site and time.');
    final docId = '${workerId}_$date';
    await _db.collection('attendance_records').doc(docId).set({
      'workerId': workerId,
      'workerUid': workerUid,
      'workerName': workerName,
      'date': date,
      'status': status,
      'siteWorkTimes': siteWorkTimes.map((x) => x.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser!.uid,
    }, SetOptions(merge: true));
  }

  Stream<Map<String, AttendanceRecord>> watchForDate(String date) {
    return _db
        .collection('attendance_records')
        .where('date', isEqualTo: date)
        .snapshots()
        .map((s) {
          return {
            for (final d in s.docs) d.id: AttendanceRecord.fromMap(d.data()),
          };
        });
  }

  Stream<List<AttendanceRecord>> watchMyRecords() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _db
        .collection('attendance_records')
        .where('workerUid', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => AttendanceRecord.fromMap(d.data())).toList(),
        );
  }
}
