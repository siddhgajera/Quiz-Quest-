import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  userRegistered,
  userLogin,
  quizCompleted,
  questionAdded,
  userPromoted,
  userDemoted,
  userActivated,
  userDeactivated,
  highScore,
  profileUpdated,
  passwordChanged,
  emailVerified,
}

class ActivityModel {
  final String id;
  final ActivityType type;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userProfileImage;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? relatedId; // Quiz ID, Question ID, etc.

  ActivityModel({
    required this.id,
    required this.type,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userProfileImage,
    required this.title,
    required this.description,
    required this.timestamp,
    this.metadata = const {},
    this.relatedId,
  });

  factory ActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityModel(
      id: doc.id,
      type: ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ActivityType.userLogin,
      ),
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userProfileImage: data['userProfileImage'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      relatedId: data['relatedId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.toString().split('.').last,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userProfileImage': userProfileImage,
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
      'relatedId': relatedId,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  ActivityIcon get activityIcon {
    switch (type) {
      case ActivityType.userRegistered:
        return ActivityIcon(icon: 'person_add', color: 'green');
      case ActivityType.userLogin:
        return ActivityIcon(icon: 'login', color: 'blue');
      case ActivityType.quizCompleted:
        return ActivityIcon(icon: 'check_circle', color: 'green');
      case ActivityType.questionAdded:
        return ActivityIcon(icon: 'add', color: 'blue');
      case ActivityType.userPromoted:
        return ActivityIcon(icon: 'arrow_upward', color: 'orange');
      case ActivityType.userDemoted:
        return ActivityIcon(icon: 'arrow_downward', color: 'red');
      case ActivityType.userActivated:
        return ActivityIcon(icon: 'check', color: 'green');
      case ActivityType.userDeactivated:
        return ActivityIcon(icon: 'block', color: 'red');
      case ActivityType.highScore:
        return ActivityIcon(icon: 'star', color: 'amber');
      case ActivityType.profileUpdated:
        return ActivityIcon(icon: 'edit', color: 'purple');
      case ActivityType.passwordChanged:
        return ActivityIcon(icon: 'security', color: 'orange');
      case ActivityType.emailVerified:
        return ActivityIcon(icon: 'verified', color: 'green');
    }
  }
}

class ActivityIcon {
  final String icon;
  final String color;

  ActivityIcon({required this.icon, required this.color});
}
