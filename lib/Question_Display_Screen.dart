import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'result_screen.dart';
import 'services/question_service.dart';
import 'services/score_service.dart';
import 'services/config_service.dart';
import 'services/activity_service.dart';
import 'models/user_model.dart';

class QuestionDisplayScreen extends StatefulWidget {
  final String subject;
  final String difficulty;

  const QuestionDisplayScreen({
    super.key,
    required this.subject,
    required this.difficulty,
  });

  @override
  State<QuestionDisplayScreen> createState() => _QuestionDisplayScreenState();
}

class _QuestionDisplayScreenState extends State<QuestionDisplayScreen> {
  final QuestionService _questionService = QuestionService();
  final ScoreService _scoreService = ScoreService();
  final ConfigService _configService = ConfigService();
  List<Map<String, dynamic>> _questions = [];
  int currentIndex = 0;
  int score = 0;
  bool _loading = true;
  String? _error;
  bool _isAnswering = false; // Prevent multiple answer submissions

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _error = null;
      currentIndex = 0;
      score = 0;
    });
    try {
      // Get the current questions per quiz setting
      final questionsPerQuiz = await _configService.getQuestionsPerQuiz(fallback: 10);
      
      final items = await _questionService.fetchQuestions(
        subject: widget.subject,
        difficulty: widget.difficulty,
        limit: questionsPerQuiz, // Explicitly pass the configured limit
      );
      if (!mounted) return;
      setState(() {
        _questions = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _answerQuestion(String answer) async {
    // Prevent multiple submissions for the same question
    if (_isAnswering) return;
    
    setState(() {
      _isAnswering = true;
    });

    if (answer == (_questions[currentIndex]['correct'] as String? ?? '')) {
      score++;
    }

    if (currentIndex < _questions.length - 1) {
      setState(() {
        currentIndex++;
        _isAnswering = false; // Reset for next question
      });
    } else {
      // Submit quiz attempt and save statistics
      final total = _questions.length;
      print('🎯 Quiz Complete: Submitting results...');
      
      try {
        await _scoreService.submitQuizAttempt(
          subject: widget.subject,
          difficulty: widget.difficulty,
          totalQuestions: total,
          correctAnswers: score,
        );
        
        // Track quiz completion activity
        await _trackQuizCompletion(total, score);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Quiz completed! Score: $score/$total (${((score/total)*100).round()}%)'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        print('✅ Quiz data saved successfully!');
      } catch (e) {
        print('❌ Error saving quiz: $e');
        
        // Show error but don't block navigation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Warning: $e')),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            score: score, 
            total: total,
            subject: widget.subject,
          ),
        ),
      );
      // Note: No need to reset _isAnswering here as we're navigating away
    }
  }

  // Track quiz completion activity
  Future<void> _trackQuizCompletion(int total, int score) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userModel = UserModel(
          uid: user.uid,
          name: userData['name'] ?? 'Unknown User',
          email: userData['email'] ?? '',
          profileImageUrl: userData['profileImageUrl'],
          isActive: userData['isActive'] ?? true,
          role: userData['role'] ?? 'user',
          createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastLoginAt: (userData['lastLogin'] as Timestamp?)?.toDate(),
          isEmailVerified: userData['isEmailVerified'] ?? false,
        );
        
        // Calculate quiz ID
        final quizId = '${widget.subject}_${widget.difficulty}_${DateTime.now().millisecondsSinceEpoch}';
        
        // Track the quiz completion
        await ActivityService.trackQuizCompletion(
          userModel,
          '${widget.subject} (${widget.difficulty})',
          score,
          quizId,
        );
        
        // Track high score if applicable (80%+)
        final percentage = (score / total) * 100;
        if (percentage >= 80) {
          await ActivityService.trackHighScore(
            userModel,
            score,
            '${widget.subject} (${widget.difficulty})',
          );
        }
      }
    } catch (e) {
      print('Error tracking quiz completion: $e');
      // Don't throw error, just log it
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.teal[50],
        appBar: AppBar(
          backgroundColor: Colors.teal[700],
          title: Text("${widget.subject} (${widget.difficulty})"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.teal[50],
        appBar: AppBar(
          backgroundColor: Colors.teal[700],
          title: Text("${widget.subject} (${widget.difficulty})"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load questions', style: TextStyle(color: Colors.red[700])),
              if (_error != null) Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadQuestions,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.teal[50],
        appBar: AppBar(
          backgroundColor: Colors.teal[700],
          title: Text("${widget.subject} (${widget.difficulty})"),
          actions: [
            IconButton(onPressed: _loadQuestions, icon: const Icon(Icons.refresh))
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_outlined, size: 64, color: Colors.teal[300]),
              const SizedBox(height: 12),
              const Text('No questions available for this selection.'),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _loadQuestions,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload'),
              )
            ],
          ),
        ),
      );
    }

    final question = _questions[currentIndex];
    final answers = (question['answers'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];

    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        backgroundColor: Colors.teal[700],
        title: Column(
          children: [
            Text(
              "${widget.subject} (${widget.difficulty})",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              "Quiz Length: ${_questions.length} Questions",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 6,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: (currentIndex + 1) / _questions.length,
                    backgroundColor: Colors.teal[100],
                    color: Colors.teal[600],
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 12),

                  // Question Number
                  Text(
                    "Question ${currentIndex + 1} of ${_questions.length}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Question Text
                  Text(
                    question['question'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Answer Options
                  ...answers.map((ans) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isAnswering ? null : () => _answerQuestion(ans),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          ans,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )).toList(),

                  const SizedBox(height: 12),

                  // Score tracker
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.teal[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Score: $score",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
