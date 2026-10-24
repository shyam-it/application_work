import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/site.dart';

class SiteService {
  SiteService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _sites =>
      _firestore.collection('sites');

  // Verify that the signed-in user has the Owner role.
  Future<void> _requireOwner() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in first.');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.data()?['role']?.toString().toLowerCase() != 'owner') {
      throw Exception('Only the Owner can manage sites.');
    }
  }

  // Add a new site.
  Future<void> addSite(String name) async {
    await _requireOwner();

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw ArgumentError('Site name cannot be empty.');
    }

    final existing = await _sites
        .where('name', isEqualTo: cleanName)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw ArgumentError('This site already exists.');
    }

    await _sites.add({
      'name': cleanName,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _auth.currentUser!.uid,
    });
  }

  // Listen to active sites.
  Stream<List<Site>> watchActiveSites() {
    return _sites
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Site.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Deactivate a site without deleting its history.
  Future<void> deactivateSite(String siteId) async {
    await _requireOwner();

    await _sites.doc(siteId).update({
      'isActive': false,
      'deactivatedAt': FieldValue.serverTimestamp(),
      'deactivatedBy': _auth.currentUser!.uid,
    });
  }
}
