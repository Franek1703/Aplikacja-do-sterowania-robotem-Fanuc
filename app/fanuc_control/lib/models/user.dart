import 'package:cloud_firestore/cloud_firestore.dart';

/// User model based on Firestore /users/{uid} collection
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // "admin" | "engineer" | "viewer"
  final String? photoUrl;
  final String? company;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoUrl,
    this.company,
    this.createdAt,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return null;
    }

    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
      photoUrl: json['photoUrl'] as String?,
      company: json['company'] as String?,
      createdAt: parseDateTime(json['createdAt']),
      // Handle both lastLoginAt and lastTimeSeen fields
      lastLoginAt: parseDateTime(json['lastLoginAt'] ?? json['lastTimeSeen']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (company != null) 'company': company,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (lastLoginAt != null) 'lastLoginAt': lastLoginAt!.toIso8601String(),
    };
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserModel.fromJson(doc.data()!);
  }
  
  Map<String, dynamic> toFirestore() {
    return toJson();
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    String? photoUrl,
    String? company,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      company: company ?? this.company,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

