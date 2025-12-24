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
  Future<List<Map<String, dynamic>>> _getVarietyQuestions(String subject, String currentDifficulty, int count) async {
    final allDifficulties = ['easy', 'medium', 'hard'];
    final otherDifficulties = allDifficulties.where((d) => d != currentDifficulty.toLowerCase()).toList();
    
    List<Map<String, dynamic>> varietyQuestions = [];
    
    for (String difficulty in otherDifficulties) {
      // 1. Try Firestore variety
      try {
        final snap = await _firestore.collection(_questionsCollection)
            .where('subject', isEqualTo: subject)
            .where('difficulty', isEqualTo: difficulty.toLowerCase())
            .limit(count)
            .get();
        
        if (snap.docs.isNotEmpty) {
          varietyQuestions.addAll(snap.docs.map((doc) => {
            'id': doc.id,
            ...(doc.data() as Map<String, dynamic>),
            'originalDifficulty': difficulty,
          }));
        }
      } catch (e) {
        print('QuestionService: Variety fetch from Firestore failed: $e');
      }

      // 2. Try Local Variety (if we still need more or as fallback)
      if (varietyQuestions.length < count) {
        final localQs = QuestionBank.getQuestions(subject, difficulty);
        if (localQs.isNotEmpty) {
          final mapped = localQs.map((q) => {
            'question': q['question'],
            'answers': q['answers'],
            'correct': q['correct'],
            'originalDifficulty': difficulty,
          }).toList();
          varietyQuestions.addAll(mapped);
        }
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

  // --- Firestore Persistence Methods ---

  // Collection name for questions
  static const String _questionsCollection = 'questions';

  /// Add a new question to Firestore
  Future<void> addQuestion({
    required String subject,
    required String difficulty,
    required String question,
    required List<String> answers,
    required String correct,
  }) async {
    try {
      await _firestore.collection(_questionsCollection).add({
        'subject': subject,
        'difficulty': difficulty.toLowerCase(),
        'question': question,
        'answers': answers,
        'correct': correct,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('QuestionService: Added question to Firestore: $subject/$difficulty');
    } catch (e) {
      print('QuestionService: Error adding question: $e');
      throw Exception('Failed to add question to Firestore: $e');
    }
  }

  /// Update an existing question in Firestore
  Future<void> updateQuestion({
    required String docId,
    required String subject,
    required String difficulty,
    required String question,
    required List<String> answers,
    required String correct,
  }) async {
    try {
      await _firestore.collection(_questionsCollection).doc(docId).update({
        'subject': subject,
        'difficulty': difficulty.toLowerCase(),
        'question': question,
        'answers': answers,
        'correct': correct,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('QuestionService: Updated question in Firestore: $docId');
    } catch (e) {
      print('QuestionService: Error updating question: $e');
      throw Exception('Failed to update question in Firestore: $e');
    }
  }

  /// Delete a question from Firestore
  Future<void> deleteQuestion(String docId) async {
    try {
      await _firestore.collection(_questionsCollection).doc(docId).delete();
      print('QuestionService: Deleted question from Firestore: $docId');
    } catch (e) {
      print('QuestionService: Error deleting question: $e');
      throw Exception('Failed to delete question from Firestore: $e');
    }
  }

  /// Stream questions from Firestore with optional filters
  Stream<List<Map<String, dynamic>>> streamQuestions({String? subject, String? difficulty}) {
    Query query = _firestore.collection(_questionsCollection);

    if (subject != null && subject != 'All') {
      query = query.where('subject', isEqualTo: subject);
    }
    if (difficulty != null && difficulty != 'all') {
      query = query.where('difficulty', isEqualTo: difficulty.toLowerCase());
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Import initial data from QuestionBank if collection is empty
  Future<int> importInitialData() async {
    try {
      final existing = await _firestore.collection(_questionsCollection).limit(1).get(
        const GetOptions(source: Source.server)
      );
      
      if (existing.docs.isNotEmpty) {
        print('QuestionService: Firestore already has questions. Skipping import.');
        return 0;
      }

      print('QuestionService: Starting initial import from QuestionBank...');
      int count = 0;
      final batch = _firestore.batch();

      for (var subject in QuestionBank.questions.keys) {
        for (var difficulty in QuestionBank.questions[subject]!.keys) {
          final questions = QuestionBank.questions[subject]![difficulty]!;
          for (var q in questions) {
            final docRef = _firestore.collection(_questionsCollection).doc();
            batch.set(docRef, {
              'subject': subject,
              'difficulty': difficulty,
              'question': q['question'],
              'answers': q['answers'],
              'correct': q['correct'],
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            count++;
            
            // Batches are limited to 500 operations
            if (count % 400 == 0) {
              await batch.commit();
              // Start a new batch if we have more
            }
          }
        }
      }

      await batch.commit();
      print('QuestionService: Imported $count questions successfully.');
      return count;
    } catch (e) {
      print('QuestionService: Error during import: $e');
      throw Exception('Failed to import initial data: $e');
    }
  }

  // Fetch questions by subject and difficulty. (Optimized for Persistence & Variety)
  Future<List<Map<String, dynamic>>> fetchQuestions({
    required String subject,
    required String difficulty,
    int? limit,
  }) async {
    List<Map<String, dynamic>> rawQuestions = [];
    bool isFromFirestore = false;

    try {
      // 1. Fetch from Firestore
      final snap = await _firestore.collection(_questionsCollection)
          .where('subject', isEqualTo: subject)
          .where('difficulty', isEqualTo: difficulty.toLowerCase())
          .get();
      
      if (snap.docs.isNotEmpty) {
        rawQuestions = snap.docs.map((doc) => {
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        }).toList();
        isFromFirestore = true;
        print('QuestionService: Fetched ${rawQuestions.length} raw questions from Firestore');
      }
    } catch (e) {
      print('QuestionService: Firestore fetch error: $e');
    }

    // 2. Fallback to local if Firestore is empty
    if (rawQuestions.isEmpty) {
      final subjects = QuestionBank.questions.keys.toList();
      String? matchedSubject;
      for (var s in subjects) {
        if (s.toLowerCase() == subject.toLowerCase()) {
          matchedSubject = s;
          break;
        }
      }

      final String chosenSubject = matchedSubject ?? (subjects.isNotEmpty ? subjects.first : 'Science');
      final String chosenDifficulty = difficulty.toLowerCase() == 'all' ? 'easy' : difficulty.toLowerCase();

      final localQs = QuestionBank.getQuestions(chosenSubject, chosenDifficulty);
      rawQuestions = localQs.map((q) => {
        'question': q['question'],
        'answers': q['answers'],
        'correct': q['correct'],
      }).toList();
      print('QuestionService: Using ${rawQuestions.length} local questions as fallback');
    }

    if (rawQuestions.isEmpty) return [];

    // 3. Apply Advanced Shuffling Strategy
    final attemptCount = await _getUserAttemptCount(subject, difficulty);
    final processedQuestions = _shuffleQuestions(rawQuestions, attemptCount);

    // 4. Calculate Dynamic Limit
    final configuredLimit = limit ?? await ConfigService().getQuestionsPerQuiz(fallback: 10);
    final dynamicLimit = _getDynamicQuestionCount(processedQuestions.length, configuredLimit);

    // 5. Variety Injection (Mix in other difficulties on repeat attempts)
    List<Map<String, dynamic>> finalQuestions = processedQuestions.take(dynamicLimit).toList();
    
    if (attemptCount > 0 && finalQuestions.length < dynamicLimit + 2) {
      final varietyNeed = (dynamicLimit * 0.2).round().clamp(1, 3);
      final varietyExtras = await _getVarietyQuestions(subject, difficulty, varietyNeed);
      
      if (varietyExtras.isNotEmpty) {
        print('QuestionService: Injected ${varietyExtras.length} variety questions');
        finalQuestions.addAll(varietyExtras);
        finalQuestions.shuffle(_random);
      }
    }

    return finalQuestions.take(dynamicLimit).toList();
  }

  // Stream categories (Updated to use Firestore if available)
  Stream<List<String>> streamCategories() {
    return _firestore.collection(_questionsCollection).snapshots().map((snapshot) {
      final subjects = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['subject'] as String)
          .toSet()
          .toList();
      
      if (subjects.isEmpty) {
        return QuestionBank.getSubjects();
      }
      subjects.sort();
      return subjects;
    });
  }

  /// Stream categories with metadata (total questions, counts per difficulty)
  Stream<List<Map<String, dynamic>>> streamCategoriesWithMetadata() {
    return _firestore.collection(_questionsCollection).snapshots().map((snapshot) {
      final Map<String, Map<String, dynamic>> categories = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final subject = data['subject'] as String;
        final difficulty = data['difficulty'] as String;

        if (!categories.containsKey(subject)) {
          categories[subject] = {
            'name': subject,
            'total': 0,
            'easy': 0,
            'medium': 0,
            'hard': 0,
          };
        }

        categories[subject]!['total'] = (categories[subject]!['total'] as int) + 1;
        if (categories[subject]!.containsKey(difficulty)) {
          categories[subject]![difficulty] = (categories[subject]![difficulty] as int) + 1;
        }
      }

      // If Firestore is empty, fallback to local QuestionBank
      if (categories.isEmpty) {
        final List<Map<String, dynamic>> fallback = [];
        for (var subject in QuestionBank.questions.keys) {
          int subjectTotal = 0;
          final diffCounts = <String, int>{};
          for (var diff in QuestionBank.questions[subject]!.keys) {
            final count = QuestionBank.questions[subject]![diff]!.length;
            diffCounts[diff] = count;
            subjectTotal += count;
          }
          fallback.add({
            'name': subject,
            'total': subjectTotal,
            ...diffCounts,
          });
        }
        fallback.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        return fallback;
      }

      final result = categories.values.toList();
      result.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      return result;
    });
  }

  // Ensure a category exists (idempotent)
  Future<void> upsertCategory(String name, {bool active = true, int order = 0}) async {
    // No-op for now as we infer categories from questions
    return;
  }
}
