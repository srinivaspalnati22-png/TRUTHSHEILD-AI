import 'package:cloud_firestore/cloud_firestore.dart';

enum ThreatLevel { safe, low, medium, high, critical }
enum ScanType { message, url, document, notification, factCheck }

class ScanResult {
  final String id;
  final String userId;
  final ScanType scanType;
  final String content;
  final int trustScore;
  final ThreatLevel threatLevel;
  final String summary;
  final List<String> redFlags;
  final List<String> positiveSignals;
  final String explanation;
  final double confidence;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final bool isDeleted;

  const ScanResult({
    required this.id,
    required this.userId,
    required this.scanType,
    required this.content,
    required this.trustScore,
    required this.threatLevel,
    required this.summary,
    required this.redFlags,
    required this.positiveSignals,
    required this.explanation,
    required this.confidence,
    required this.metadata,
    required this.timestamp,
    this.isDeleted = false,
  });

  factory ScanResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScanResult(
      id: doc.id,
      userId: data['userId'] ?? '',
      scanType: ScanType.values.firstWhere(
        (e) => e.name == data['scanType'],
        orElse: () => ScanType.message,
      ),
      content: data['content'] ?? '',
      trustScore: data['trustScore'] ?? 50,
      threatLevel: ThreatLevel.values.firstWhere(
        (e) => e.name == data['threatLevel'],
        orElse: () => ThreatLevel.medium,
      ),
      summary: data['summary'] ?? '',
      redFlags: List<String>.from(data['redFlags'] ?? []),
      positiveSignals: List<String>.from(data['positiveSignals'] ?? []),
      explanation: data['explanation'] ?? '',
      confidence: (data['confidence'] ?? 0.5).toDouble(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'scanType': scanType.name,
      'content': content,
      'trustScore': trustScore,
      'threatLevel': threatLevel.name,
      'summary': summary,
      'redFlags': redFlags,
      'positiveSignals': positiveSignals,
      'explanation': explanation,
      'confidence': confidence,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
      'isDeleted': isDeleted,
    };
  }

  String get threatLevelLabel {
    switch (threatLevel) {
      case ThreatLevel.safe:
        return 'Safe';
      case ThreatLevel.low:
        return 'Low Risk';
      case ThreatLevel.medium:
        return 'Suspicious';
      case ThreatLevel.high:
        return 'Dangerous';
      case ThreatLevel.critical:
        return 'CRITICAL THREAT';
    }
  }
}

class UrlScanResult {
  final String url;
  final int trustScore;
  final ThreatLevel threatLevel;
  final bool hasSSL;
  final int domainAgeDays;
  final bool isBlacklisted;
  final List<String> suspiciousPatterns;
  final String explanation;
  final DateTime timestamp;

  const UrlScanResult({
    required this.url,
    required this.trustScore,
    required this.threatLevel,
    required this.hasSSL,
    required this.domainAgeDays,
    required this.isBlacklisted,
    required this.suspiciousPatterns,
    required this.explanation,
    required this.timestamp,
  });
}
