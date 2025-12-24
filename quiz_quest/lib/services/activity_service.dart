import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';

class ActivityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'activities';

  // Track user registration
  static Future<void> trackUserRegistration(UserModel user) async {
    await _createActivity(
      type: ActivityType.userRegistered,
      user: user,
      title: 'New User Registered',
      description: '${user.name} joined Quiz Quest',
    );
  }

  // Track user login
  static Future<void> trackUserLogin(UserModel user) async {
    await _createActivity(
      type: ActivityType.userLogin,
      user: user,
      title: 'User Login',
      description: '${user.name} logged in',
    );
  }

  // Track quiz completion
  static Future<void> trackQuizCompletion(
    UserModel user,
    String quizName,
    int score,
    String quizId,
  ) async {
    await _createActivity(
      type: ActivityType.quizCompleted,
      user: user,
      title: 'Quiz Completed',
      description: '${user.name} completed $quizName with score: $score',
      metadata: {
        'quizName': quizName,
        'score': score,
        'quizId': quizId,
      },
      relatedId: quizId,
    );
  }

  // Track high score achievement
  static Future<void> trackHighScore(
    UserModel user,
    int score,
    String quizName,
  ) async {
    await _createActivity(
      type: ActivityType.highScore,
      user: user,
      title: 'High Score Achievement',
      description: '${user.name} achieved high score: $score in $quizName',
      metadata: {
        'score': score,
        'quizName': quizName,
      },
    );
  }

  // Track question addition
  static Future<void> trackQuestionAdded(
    UserModel user,
    String category,
    String questionId,
  ) async {
    await _createActivity(
      type: ActivityType.questionAdded,
      user: user,
      title: 'Question Added',
      description: '${user.name} added a question to $category',
      metadata: {
        'category': category,
        'questionId': questionId,
      },
      relatedId: questionId,
    );
  }

  // Track user promotion
  static Future<void> trackUserPromotion(
    UserModel promotedUser,
    UserModel adminUser,
    String newRole,
  ) async {
    await _createActivity(
      type: ActivityType.userPromoted,
      user: promotedUser,
      title: 'User Promoted',
      description: '${promotedUser.name} was promoted to $newRole by ${adminUser.name}',
      metadata: {
        'newRole': newRole,
        'promotedBy': adminUser.name,
        'promotedById': adminUser.uid,
      },
    );
  }

  // Track user demotion
  static Future<void> trackUserDemotion(
    UserModel demotedUser,
    UserModel adminUser,
    String newRole,
  ) async {
    await _createActivity(
      type: ActivityType.userDemoted,
      user: demotedUser,
      title: 'User Demoted',
      description: '${demotedUser.name} was demoted to $newRole by ${adminUser.name}',
      metadata: {
        'newRole': newRole,
        'demotedBy': adminUser.name,
        'demotedById': adminUser.uid,
      },
    );
  }

  // Track user activation/deactivation
  static Future<void> trackUserStatusChange(
    UserModel user,
    UserModel adminUser,
    bool isActive,
  ) async {
    await _createActivity(
      type: isActive ? ActivityType.userActivated : ActivityType.userDeactivated,
      user: user,
      title: isActive ? 'User Activated' : 'User Deactivated',
      description: '${user.name} was ${isActive ? 'activated' : 'deactivated'} by ${adminUser.name}',
      metadata: {
        'isActive': isActive,
        'changedBy': adminUser.name,
        'changedById': adminUser.uid,
      },
    );
  }

  // Track profile updates
  static Future<void> trackProfileUpdate(UserModel user) async {
    await _createActivity(
      type: ActivityType.profileUpdated,
      user: user,
      title: 'Profile Updated',
      description: '${user.name} updated their profile',
    );
  }

  // Track email verification
  static Future<void> trackEmailVerification(UserModel user) async {
    await _createActivity(
      type: ActivityType.emailVerified,
      user: user,
      title: 'Email Verified',
      description: '${user.name} verified their email address',
    );
  }

  // Track password change
  static Future<void> trackPasswordChange(UserModel user) async {
    await _createActivity(
      type: ActivityType.passwordChanged,
      user: user,
      title: 'Password Changed',
      description: '${user.name} changed their password',
    );
  }

  // Log password change by user ID (for admin profile)
  Future<void> logPasswordChange(String userId) async {
    try {
      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final user = UserModel(
          uid: userId,
          name: userData['name'] ?? 'Unknown User',
          email: userData['email'] ?? '',
          profileImageUrl: userData['profileImageUrl'],
          isActive: userData['isActive'] ?? true,
          role: userData['role'] ?? 'user',
          createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastLoginAt: (userData['lastLogin'] as Timestamp?)?.toDate(),
          isEmailVerified: userData['isEmailVerified'] ?? false,
        );
        
        await trackPasswordChange(user);
      }
    } catch (e) {
      print('Error logging password change: $e');
    }
  }

  // Log profile update by user ID (for admin profile)
  Future<void> logProfileUpdate(String userId) async {
    try {
      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final user = UserModel(
          uid: userId,
          name: userData['name'] ?? 'Unknown User',
          email: userData['email'] ?? '',
          profileImageUrl: userData['profileImageUrl'],
          isActive: userData['isActive'] ?? true,
          role: userData['role'] ?? 'user',
          createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastLoginAt: (userData['lastLogin'] as Timestamp?)?.toDate(),
          isEmailVerified: userData['isEmailVerified'] ?? false,
        );
        
        await trackProfileUpdate(user);
      }
    } catch (e) {
      print('Error logging profile update: $e');
    }
  }

  // Get recent activities with pagination (excluding sample data)
  static Stream<List<ActivityModel>> getRecentActivities({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) {
    Query query = _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.snapshots().map((snapshot) {
      // Filter out sample activities (userId starting with 'sample_')
      return snapshot.docs
          .map((doc) => ActivityModel.fromFirestore(doc))
          .where((activity) => !activity.userId.startsWith('sample_'))
          .toList();
    });
  }

  // Get activities for a specific user (excluding sample data)
  static Stream<List<ActivityModel>> getUserActivities(
    String userId, {
    int limit = 10,
  }) {
    // Don't return activities for sample users
    if (userId.startsWith('sample_')) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ActivityModel.fromFirestore(doc)).toList();
    });
  }

  // Get activities by type (excluding sample data)
  static Stream<List<ActivityModel>> getActivitiesByType(
    ActivityType type, {
    int limit = 10,
  }) {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: type.toString().split('.').last)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      // Filter out sample activities (userId starting with 'sample_')
      return snapshot.docs
          .map((doc) => ActivityModel.fromFirestore(doc))
          .where((activity) => !activity.userId.startsWith('sample_'))
          .toList();
    });
  }

  // Private method to create activity
  static Future<void> _createActivity({
    required ActivityType type,
    required UserModel user,
    required String title,
    required String description,
    Map<String, dynamic> metadata = const {},
    String? relatedId,
  }) async {
    try {
      final activity = ActivityModel(
        id: '', // Will be set by Firestore
        type: type,
        userId: user.uid,
        userName: user.name,
        userEmail: user.email,
        userProfileImage: user.profileImageUrl,
        title: title,
        description: description,
        timestamp: DateTime.now(),
        metadata: metadata,
        relatedId: relatedId,
      );

      await _firestore.collection(_collection).add(activity.toFirestore());
    } catch (e) {
      print('Error creating activity: $e');
      // Don't throw error to avoid breaking main functionality
    }
  }

  // Clean up old activities (optional - can be called periodically)
  static Future<void> cleanupOldActivities({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final query = await _firestore
          .collection(_collection)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error cleaning up old activities: $e');
    }
  }

  // Clear all sample activities (activities with sample user IDs)
  static Future<void> clearSampleActivities() async {
    try {
      // Query for activities with sample user IDs (they start with 'sample_')
      final query = await _firestore
          .collection(_collection)
          .where('userId', isGreaterThanOrEqualTo: 'sample_')
          .where('userId', isLessThan: 'sample_\uf8ff')
          .get();

      if (query.docs.isEmpty) {
        print('No sample activities found to clear');
        return;
      }

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      print('Successfully cleared ${query.docs.length} sample activities');
    } catch (e) {
      print('Error clearing sample activities: $e');
    }
  }

  // Clear all activities (use with caution - for testing only)
  static Future<void> clearAllActivities() async {
    try {
      final query = await _firestore.collection(_collection).get();
      
      if (query.docs.isEmpty) {
        print('No activities found to clear');
        return;
      }

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      print('Successfully cleared ${query.docs.length} activities');
    } catch (e) {
      print('Error clearing all activities: $e');
    }
  }
}
