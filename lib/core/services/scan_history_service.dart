import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/scanner/models/scan_result.dart';
import '../providers/auth_provider.dart';

final scanHistoryServiceProvider = Provider<ScanHistoryService>((ref) {
  return ScanHistoryService(ref);
});

class ScanHistoryService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ScanHistoryService(this._ref);

  Future<void> saveScan(ScanResult result) async {
    try {
      // Only save metadata, not full content (privacy-first design)
      final sanitized = {
        'userId': result.userId,
        'scanType': result.scanType.name,
        'contentPreview': result.content.length > 100
            ? '${result.content.substring(0, 100)}...'
            : result.content,
        'trustScore': result.trustScore,
        'threatLevel': result.threatLevel.name,
        'summary': result.summary,
        'redFlags': result.redFlags,
        'positiveSignals': result.positiveSignals,
        'explanation': result.explanation,
        'confidence': result.confidence,
        'timestamp': Timestamp.fromDate(result.timestamp),
        // Content is NOT stored permanently - privacy first
        'isDeleted': false,
      };

      await _firestore
          .collection('scan_history')
          .doc(result.userId)
          .collection('scans')
          .add(sanitized);

      // Update user stats
      await _firestore.collection('users').doc(result.userId).update({
        'totalScans': FieldValue.increment(1),
        'threatsDetected': result.threatLevel == ThreatLevel.high ||
                result.threatLevel == ThreatLevel.critical
            ? FieldValue.increment(1)
            : FieldValue.increment(0),
        'lastSeen': Timestamp.now(),
      });
    } catch (e) {
      // Silently fail - don't block user flow for analytics
    }
  }

  Stream<List<Map<String, dynamic>>> getUserScans(String userId) {
    return _firestore
        .collection('scan_history')
        .doc(userId)
        .collection('scans')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  Future<void> deleteScan(String userId, String scanId) async {
    await _firestore
        .collection('scan_history')
        .doc(userId)
        .collection('scans')
        .doc(scanId)
        .update({'isDeleted': true});
  }
}
