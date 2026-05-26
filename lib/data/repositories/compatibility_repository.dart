import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/compatibility_report.dart';

class CompatibilityRepository {
  CompatibilityRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _reports(String uid) =>
      _firestore.collection('users').doc(uid).collection('compatibility_reports');

  Future<void> saveReport(String uid, CompatibilityReport report) async {
    await _reports(uid).doc(report.id).set(report.toMap());
  }

  Stream<List<CompatibilityReport>> watchReports(String uid, {int limit = 20}) {
    return _reports(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map(CompatibilityReport.fromFirestore).toList());
  }

  Future<CompatibilityReport?> getReport(String uid, String reportId) async {
    final doc = await _reports(uid).doc(reportId).get();
    if (!doc.exists) return null;
    return CompatibilityReport.fromFirestore(doc);
  }
}
