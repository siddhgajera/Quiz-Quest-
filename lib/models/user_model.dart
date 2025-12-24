import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isEmailVerified;
  final bool isAdmin;
  final String role; // 'user', 'admin', 'super_admin'
  final int totalScore;
  final int quizzesCompleted;
  final Map<String, dynamic> preferences;
  final bool isActive;
  final String? bio;
  final DateTime? dateOfBirth;
  final String? location;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
    required this.isEmailVerified,
    this.isAdmin = false,
    this.role = 'user',
    this.totalScore = 0,
    this.quizzesCompleted = 0,
    this.preferences = const {},
    this.isActive = true,
    this.bio,
    this.dateOfBirth,
    this.location,
  });

  // Create UserModel from Firebase User and Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      isEmailVerified: data['isEmailVerified'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
      role: data['role'] ?? 'user',
      totalScore: data['totalScore'] ?? 0,
      quizzesCompleted: data['quizzesCompleted'] ?? 0,
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      isActive: data['isActive'] ?? true,
      bio: data['bio'],
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      location: data['location'],
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isEmailVerified': isEmailVerified,
      'isAdmin': isAdmin,
      'role': role,
      'totalScore': totalScore,
      'quizzesCompleted': quizzesCompleted,
      'preferences': preferences,
      'isActive': isActive,
      'bio': bio,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'location': location,
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    bool? isAdmin,
    String? role,
    int? totalScore,
    int? quizzesCompleted,
    Map<String, dynamic>? preferences,
    bool? isActive,
    String? bio,
    DateTime? dateOfBirth,
    String? location,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      role: role ?? this.role,
      totalScore: totalScore ?? this.totalScore,
      quizzesCompleted: quizzesCompleted ?? this.quizzesCompleted,
      preferences: preferences ?? this.preferences,
      isActive: isActive ?? this.isActive,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      location: location ?? this.location,
    );
  }

  // Helper getters
  bool get isSuperAdmin => role == 'super_admin';
  bool get isRegularAdmin => role == 'admin';
  bool get hasAdminRights => isAdmin || role == 'admin' || role == 'super_admin';
  
  String get displayName => name.isNotEmpty ? name : email.split('@').first;
  
  String get initials {
    if (name.isEmpty) return email.substring(0, 1).toUpperCase();
    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }
}
