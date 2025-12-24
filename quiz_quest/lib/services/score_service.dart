import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Calculate score based on difficulty
  int _calculateScore(String difficulty, int correct) {
    final multiplier = {
      'easy': 10,
      'medium': 20,
      'hard': 30,
    };
    return (multiplier[difficulty.toLowerCase()] ?? 10) * correct;
  }

  // Calculate percentage
  int _calculatePercentage(int correct, int total) {
    if (total == 0) return 0;
    return ((correct / total) * 100).round();
  }

  /// Submit quiz attempt and update user statistics
  Future<void> submitQuizAttempt({
    required String subject,
    required String difficulty,
    required int totalQuestions,
    required int correctAnswers,
    int? timeTakenSeconds,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final uid = user.uid;
      final score = _calculateScore(difficulty, correctAnswers);
      final percentage = _calculatePercentage(correctAnswers, totalQuestions);
      final timestamp = FieldValue.serverTimestamp();

      print('🎯 ScoreService: Starting quiz submission');
      print('📊 Subject: $subject, Difficulty: $difficulty');
      print('📈 Score: $score, Percentage: $percentage%');
      
      // 1. Create quiz attempt record (simplified)
      final attemptRef = _firestore.collection('quizAttempts').doc();
      await attemptRef.set({
        'uid': uid,
        'subject': subject,
        'difficulty': difficulty,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'score': score,
        'percentage': percentage,
        'timeTakenSeconds': timeTakenSeconds ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
        
      print('✅ Quiz attempt saved successfully');

      // 2. Update user's overall statistics (simplified)
      final userRef = _firestore.collection('users').doc(uid);
      final userDoc = await userRef.get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final currentQuizzes = (userData['quizzesCompleted'] ?? 0) as int;
        final currentTotalScore = (userData['totalScore'] ?? 0) as int;
        final currentHighestScore = (userData['highestScore'] ?? 0) as int;
        
        // Calculate new statistics
        final newQuizzesCompleted = currentQuizzes + 1;
        final newTotalScore = currentTotalScore + score;
        final newAverageScore = (newTotalScore / newQuizzesCompleted).round();
        final newHighestScore = score > currentHighestScore ? score : currentHighestScore;

        await userRef.update({
          'quizzesCompleted': newQuizzesCompleted,
          'totalScore': newTotalScore,
          'averageScore': newAverageScore,
          'highestScore': newHighestScore,
          'lastActive': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        print('📊 Updated user stats: quizzes=$newQuizzesCompleted, total=$newTotalScore, avg=$newAverageScore, highest=$newHighestScore');
      } else {
        // Create new user document
        await userRef.set({
          'uid': uid,
          'email': user.email ?? '',
          'name': user.displayName ?? 'Quiz Player',
          'quizzesCompleted': 1,
          'totalScore': score,
          'averageScore': score,
          'highestScore': score,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('👤 Created new user document with initial stats');
      }

      // 3. Update subject-wise performance (simplified)
      final categoryRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('categoryStats')
          .doc(subject);
      
      final categoryDoc = await categoryRef.get();
      
      if (categoryDoc.exists) {
        final categoryData = categoryDoc.data()!;
        final currentAttempts = (categoryData['attempts'] ?? 0) as int;
        final currentCorrect = (categoryData['correct'] ?? 0) as int;
        final currentCategoryScore = (categoryData['score'] ?? 0) as int;
        
        final newAttempts = currentAttempts + 1;
        final newCorrect = currentCorrect + correctAnswers;
        final newCategoryScore = currentCategoryScore + score;
        final newAccuracy = ((newCorrect / (newAttempts * totalQuestions)) * 100).round();

        await categoryRef.update({
          'subject': subject,
          'attempts': newAttempts,
          'correct': newCorrect,
          'score': newCategoryScore,
          'averageScore': (newCategoryScore / newAttempts).round(),
          'accuracy': newAccuracy,
          'lastDifficulty': difficulty,
          'lastAttempt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('📚 Updated category stats: attempts=$newAttempts, accuracy=$newAccuracy%');
      } else {
        // Create new category stats
        final accuracy = ((correctAnswers / totalQuestions) * 100).round();
        
        await categoryRef.set({
          'subject': subject,
          'attempts': 1,
          'correct': correctAnswers,
          'score': score,
          'averageScore': score,
          'accuracy': accuracy,
          'lastDifficulty': difficulty,
          'lastAttempt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('📚 Created new category stats for $subject');
      }

      print('✅ Quiz submission completed successfully!');
      
    } catch (e, stackTrace) {
      print('❌ ScoreService Error: $e');
      print('📍 Stack trace: $stackTrace');
      
      // Provide specific error messages
      if (e.toString().contains('permission-denied')) {
        throw Exception('Permission denied: Please check your account permissions');
      } else if (e.toString().contains('unauthenticated')) {
        throw Exception('Authentication required: Please log in again');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error: Please check your internet connection');
      } else {
        throw Exception('Failed to save quiz data: ${e.toString()}');
      }
    }
  }

  /// Get user's quiz statistics
  Future<Map<String, dynamic>> getUserStats(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (userDoc.exists) {
        return userDoc.data()!;
      } else {
        return {
          'quizzesCompleted': 0,
          'totalScore': 0,
          'averageScore': 0,
          'highestScore': 0,
        };
      }
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'quizzesCompleted': 0,
        'totalScore': 0,
        'averageScore': 0,
        'highestScore': 0,
      };
    }
  }

  /// Get user's category-wise performance
  Future<List<Map<String, dynamic>>> getCategoryStats(String uid) async {
    try {
      final categorySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('categoryStats')
          .orderBy('score', descending: true)
          .get();

      return categorySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting category stats: $e');
      return [];
    }
  }

  /// Get user's global rank
  Future<int> getUserRank(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return 0;
      
      final userScore = userDoc.data()!['totalScore'] ?? 0;
      
      final higherScoreUsers = await _firestore
          .collection('users')
          .where('totalScore', isGreaterThan: userScore)
          .where('isActive', isEqualTo: true)
          .get();

      return higherScoreUsers.docs.length + 1;
    } catch (e) {
      print('Error getting user rank: $e');
      return 0;
    }
  }

  /// Stream global leaderboard (real-time updates)
  Stream<List<Map<String, dynamic>>> streamGlobalLeaderboard({int limit = 100}) {
    return _firestore
        .collection('users')
        .where('isActive', isEqualTo: true)
        .orderBy('totalScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['name'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'totalScore': data['totalScore'] ?? 0,
          'quizzesCompleted': data['quizzesCompleted'] ?? 0,
          'averageScore': data['averageScore'] ?? 0,
          'profileImageUrl': data['profileImageUrl'] ?? '',
        };
      }).toList();
    });
  }

  /// Stream category leaderboard (real-time updates)
  Stream<List<Map<String, dynamic>>> streamCategoryLeaderboard(String subject, {int limit = 100}) {
    return _firestore
        .collectionGroup('categoryStats')
        .where('subject', isEqualTo: subject)
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'subject': data['subject'] ?? subject,
          'score': data['score'] ?? 0,
          'attempts': data['attempts'] ?? 0,
          'accuracy': data['accuracy'] ?? 0,
          'averageScore': data['averageScore'] ?? 0,
        };
      }).toList();
    });
  }
}
