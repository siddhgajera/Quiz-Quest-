import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../question_bank.dart';

class AdminStatsProvider with ChangeNotifier {
  int _totalQuestions = 0;
  int _activeUsers = 0;
  int _quizCategories = 0;
  int _totalQuizzes = 0;
  bool _isLoading = false;
  String? _error;

  int get totalQuestions => _totalQuestions;
  int get activeUsers => _activeUsers;
  int get quizCategories => _quizCategories;
  int get totalQuizzes => _totalQuizzes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AdminStatsProvider() {
    loadStats();
  }

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadTotalQuestions(),
        _loadActiveUsers(),
        _loadQuizCategories(),
        _loadTotalQuizzes(),
      ]);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTotalQuestions() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('questions').get();
      if (snap.docs.isNotEmpty) {
        _totalQuestions = snap.docs.length;
      } else {
        // Fallback to QuestionBank
        int count = 0;
        for (final subject in QuestionBank.questions.keys) {
          final subjectData = QuestionBank.questions[subject]!;
          for (final difficulty in subjectData.keys) {
            count += subjectData[difficulty]!.length;
          }
        }
        _totalQuestions = count;
      }
    } catch (e) {
      print('Error loading total questions: $e');
      _totalQuestions = 0;
    }
  }

  Future<void> _loadActiveUsers() async {
    try {
      // Count active users from Firestore (excluding sample users)
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      // Filter out sample users (those with email starting with 'sample_' or userId starting with 'sample_')
      final realUsers = usersSnapshot.docs.where((doc) {
        final data = doc.data();
        final email = data['email'] as String? ?? '';
        final userId = doc.id;
        return !email.startsWith('sample_') && !userId.startsWith('sample_');
      }).toList();

      _activeUsers = realUsers.length;
    } catch (e) {
      print('Error loading active users: $e');
      _activeUsers = 0;
    }
  }

  Future<void> _loadQuizCategories() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('questions').get();
      if (snap.docs.isNotEmpty) {
        final categories = snap.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['subject'] as String)
            .toSet();
        _quizCategories = categories.length;
      } else {
        _quizCategories = QuestionBank.questions.keys.length;
      }
    } catch (e) {
      print('Error loading quiz categories: $e');
      _quizCategories = 0;
    }
  }

  Future<void> _loadTotalQuizzes() async {
    try {
      // Count total quiz completions from quizAttempts collection (excluding sample data)
      final quizAttemptsSnapshot = await FirebaseFirestore.instance
          .collection('quizAttempts')
          .get();

      // Filter out sample quiz attempts (those with uid starting with 'sample_')
      final realQuizzes = quizAttemptsSnapshot.docs.where((doc) {
        final data = doc.data();
        final uid = data['uid'] as String? ?? '';
        return !uid.startsWith('sample_');
      }).toList();

      _totalQuizzes = realQuizzes.length;
      
      print('✅ AdminStatsProvider: Loaded ${_totalQuizzes} total quizzes');
    } catch (e) {
      print('❌ Error loading total quizzes: $e');
      _totalQuizzes = 0;
    }
  }

  Future<void> refreshStats() async {
    await loadStats();
  }
}
