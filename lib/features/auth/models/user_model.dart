import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, moderator, admin }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String role;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final int totalScans;
  final int threatsDetected;
  final bool notificationListenerEnabled;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    this.lastSeen,
    this.totalScans = 0,
    this.threatsDetected = 0,
    this.notificationListenerEnabled = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'user',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      totalScans: data['totalScans'] ?? 0,
      threatsDetected: data['threatsDetected'] ?? 0,
      notificationListenerEnabled: data['notificationListenerEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'totalScans': totalScans,
      'threatsDetected': threatsDetected,
      'notificationListenerEnabled': notificationListenerEnabled,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? role,
    DateTime? lastSeen,
    int? totalScans,
    int? threatsDetected,
    bool? notificationListenerEnabled,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      totalScans: totalScans ?? this.totalScans,
      threatsDetected: threatsDetected ?? this.threatsDetected,
      notificationListenerEnabled:
          notificationListenerEnabled ?? this.notificationListenerEnabled,
    );
  }
}
