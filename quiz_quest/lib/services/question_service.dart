import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../question_bank.dart';
import 'config_service.dart';

class QuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final math.Random _random = math.Random();

  // Check if user has attempted this subject/difficulty combination before
  Future<bool> _hasUserAttemptedBefore(String subject, String difficulty) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final attempts = await _firestore
          .collection('quizAttempts')
          .where('uid', isEqualTo: user.uid)
          .where('subject', isEqualTo: subject)
          .where('difficulty', isEqualTo: difficulty)
          .limit(1)
          .get();

      return attempts.docs.isNotEmpty;
    } catch (e) {
      print('Error checking user attempts: $e');
      return false;
    }
  }

  // Get user's attempt count for this subject/difficulty
  Future<int> _getUserAttemptCount(String subject, String difficulty) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final attempts = await _firestore
          .collection('quizAttempts')
          .where('uid', isEqualTo: user.uid)
          .where('subject', isEqualTo: subject)
          .where('difficulty', isEqualTo: difficulty)
          .get();

      return attempts.docs.length;
    } catch (e) {
      print('Error getting attempt count: $e');
      return 0;
    }
  }

  // Shuffle questions with different strategies based on attempt count
  List<Map<String, dynamic>> _shuffleQuestions(List<Map<String, dynamic>> questions, int attemptCount) {
    final shuffled = List<Map<String, dynamic>>.from(questions);
    
    if (attemptCount == 0) {
      // First attempt: simple shuffle
      shuffled.shuffle(_random);
      print('Quiz Shuffle: First attempt - simple shuffle applied');
    } else if (attemptCount == 1) {
      // Second attempt: reverse order + shuffle
      shuffled.shuffle(_random);
      final reversed = shuffled.reversed.toList();
      reversed.shuffle(_random);
      shuffled.clear();
      shuffled.addAll(reversed);
      print('Quiz Shuffle: Second attempt - reverse + shuffle applied');
    } else {
      // Multiple attempts: advanced shuffling with seed based on attempt count
      final seed = attemptCount * 1000 + DateTime.now().millisecondsSinceEpoch % 1000;
      final seededRandom = math.Random(seed);
      
      // Multiple shuffle passes for more randomization
      for (int i = 0; i < 3; i++) {
        shuffled.shuffle(seededRandom);
      }
      print('Quiz Shuffle: Attempt #${attemptCount + 1} - advanced shuffling with seed $seed');
    }
    
    return shuffled;
  }

  // Get additional questions from other difficulties for variety
  List<Map<String, dynamic>> _getVarietyQuestions(String subject, String currentDifficulty, int count) {
    final allDifficulties = ['easy', 'medium', 'hard'];
    final otherDifficulties = allDifficulties.where((d) => d != currentDifficulty.toLowerCase()).toList();
    
    List<Map<String, dynamic>> varietyQuestions = [];
    
    for (String difficulty in otherDifficulties) {
      final questions = QuestionBank.getQuestions(subject, difficulty);
      if (questions.isNotEmpty) {
        final mapped = questions.map((q) => {
          'question': q['question'],
          'answers': q['answers'],
          'correct': q['correct'],
          'originalDifficulty': difficulty, // Track original difficulty
        }).toList();
        varietyQuestions.addAll(mapped);
      }
    }
    
    varietyQuestions.shuffle(_random);
    return varietyQuestions.take(count).toList();
  }

  // Get dynamic question count based on available questions
  int _getDynamicQuestionCount(int availableQuestions, int configuredLimit) {
    // Use minimum of available questions or configured limit, but ensure at least 5 questions
    // Use minimum of available questions or configured limit, but ensure at least 5 questions
    
    // Smart scaling based on available questions
    if (availableQuestions <= 5) {
      return availableQuestions; // Use all available if very few
    } else if (availableQuestions <= 10) {
      return math.min(availableQuestions, 8); // Cap at 8 for small sets
    } else if (availableQuestions <= 20) {
      return math.min(availableQuestions, 15); // Cap at 15 for medium sets
    } else {
      return math.min(availableQuestions, math.max(configuredLimit, 20)); // Use configured or at least 20 for large sets
    }
  }

  // Fetch questions by subject and difficulty. If subject == 'All', do not filter by subject.
  // Returns up to [limit] randomized questions with automatic shuffling for repeat attempts.
  // Quiz length is now dynamic based on available questions in the question bank.
  Future<List<Map<String, dynamic>>> fetchQuestions({
    required String subject,
    required String difficulty,
    int? limit, // if null, read from ConfigService
  }) async {
    // Use local QuestionBank instead of Firestore
    final List<String> subjects = QuestionBank.questions.keys.toList();
    final String chosenSubject = subject.toLowerCase() == 'all'
        ? (subjects.isNotEmpty ? subjects.first : 'Science')
        : subject;
    final String chosenDifficulty = difficulty.toLowerCase() == 'all'
        ? 'easy'
        : difficulty.toLowerCase();

    // Get base questions to determine available count
    final baseQuestions = QuestionBank.getQuestions(chosenSubject, chosenDifficulty);
    final availableCount = baseQuestions.length;

    // Get configured limit from admin settings
    final configuredLimit = limit ?? await ConfigService().getQuestionsPerQuiz(fallback: 10);
    
    // Calculate dynamic question count based on available questions
    final effectiveLimit = _getDynamicQuestionCount(availableCount, configuredLimit);
    
    print('Quiz Dynamic: Available=$availableCount, Configured=$configuredLimit, Using=$effectiveLimit questions for $chosenSubject/$chosenDifficulty');

    // Check if user has attempted this quiz before
    final hasAttempted = await _hasUserAttemptedBefore(chosenSubject, chosenDifficulty);
    final attemptCount = await _getUserAttemptCount(chosenSubject, chosenDifficulty);

    print('Quiz Shuffle: User has ${hasAttempted ? "attempted" : "not attempted"} $chosenSubject/$chosenDifficulty before (attempts: $attemptCount)');

    // Map base questions to the required format
    final mappedBaseQuestions = baseQuestions
        .map((q) => {
              'question': q['question'],
              'answers': q['answers'],
              'correct': q['correct'],
            })
        .toList();

    List<Map<String, dynamic>> finalQuestions = [];

    if (!hasAttempted) {
      // First time: use regular questions with simple shuffle
      finalQuestions = _shuffleQuestions(mappedBaseQuestions, 0);
      print('Quiz Shuffle: First attempt - using ${finalQuestions.length} regular questions');
    } else {
      // Repeat attempt: mix original questions with variety questions
      final baseCount = (effectiveLimit * 0.7).round(); // 70% from original difficulty
      final varietyCount = effectiveLimit - baseCount;   // 30% from other difficulties
      
      // Get shuffled base questions
      final shuffledBase = _shuffleQuestions(mappedBaseQuestions, attemptCount);
      finalQuestions.addAll(shuffledBase.take(baseCount));
      
      // Add variety questions from other difficulties
      if (varietyCount > 0) {
        final varietyQuestions = _getVarietyQuestions(chosenSubject, chosenDifficulty, varietyCount);
        finalQuestions.addAll(varietyQuestions);
        print('Quiz Shuffle: Added $varietyCount variety questions from other difficulties');
      }
      
      // Final shuffle of the mixed questions
      finalQuestions.shuffle(_random);
      print('Quiz Shuffle: Repeat attempt - mixed ${baseCount} base + ${varietyCount} variety questions');
    }

    // Ensure we don't exceed the requested limit
    final result = finalQuestions.take(effectiveLimit).toList();
    print('Quiz Shuffle: Returning ${result.length} questions for $chosenSubject/$chosenDifficulty');
    
    return result;
  }

  // Stream categories in real-time
  Stream<List<String>> streamCategories() {
    final controller = StreamController<List<String>>();
    // Emit once with local categories from QuestionBank
    controller.add(QuestionBank.questions.keys.toList());
    // Close immediately as this is static data
    controller.close();
    return controller.stream;
  }

  // Ensure a category exists (idempotent)
  Future<void> upsertCategory(String name, {bool active = true, int order = 0}) async {
    // No-op for local QuestionBank implementation
    return;
  }
}
