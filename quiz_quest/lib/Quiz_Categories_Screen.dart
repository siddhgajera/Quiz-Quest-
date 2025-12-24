import 'package:flutter/material.dart';
import 'dart:async';
import 'mode_selection_screen.dart';
import 'question_bank.dart';
import 'utils/question_update_notifier.dart';

// Helper to convert string icon names to IconData
IconData iconFromName(String name) {
  switch (name) {
    case 'history': return Icons.library_books;
    case 'science': return Icons.science;
    case 'geography': return Icons.travel_explore;
    case 'literature': return Icons.book;
    case 'artificial_intelligence': return Icons.computer;
    case 'python': return Icons.code;
    case 'cross_platform': return Icons.cast_for_education;
    case 'mathematical': return Icons.calculate;
    default: return Icons.help_outline;
  }
}

class QuizCategoriesScreen extends StatefulWidget {
  const QuizCategoriesScreen({super.key});

  @override
  State<QuizCategoriesScreen> createState() => QuizCategoriesScreenState();
}

class QuizCategoriesScreenState extends State<QuizCategoriesScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _categories = [];
  StreamSubscription<void>? _questionUpdateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCategories();
    
    // Listen for question updates
    _questionUpdateSubscription = QuestionUpdateNotifier().onQuestionUpdated.listen((_) {
      print('QuizCategoriesScreen: Received question update notification, refreshing categories...');
      _loadCategories();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _questionUpdateSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when app comes back to foreground
      _loadCategories();
    }
  }

  @override
  void didUpdateWidget(QuizCategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadCategories();
  }

  // Public method to be called when returning from other screens
  void refreshCategories() {
    if (mounted) {
      _loadCategories();
    }
  }

  void _loadCategories() {
    if (!mounted) return;
    
    final categories = <Map<String, dynamic>>[];
    
    // Get subjects from QuestionBank
    final subjects = QuestionBank.questions.keys.toList()..sort();
    
    for (final subject in subjects) {
      // Count total questions for this subject
      int totalQuestions = 0;
      final subjectData = QuestionBank.questions[subject]!;
      for (final difficulty in subjectData.keys) {
        totalQuestions += subjectData[difficulty]!.length;
      }
      
      categories.add({
        'name': subject,
        'icon': _getIconNameForSubject(subject),
        'questionCount': totalQuestions,
      });
    }
    
    // If no subjects in QuestionBank, use fallback categories
    if (categories.isEmpty) {
      for (final cat in _localCategories) {
        categories.add({
          'name': cat['name']!,
          'icon': cat['icon']!,
          'questionCount': 0,
        });
      }
    }
    
    setState(() {
      _categories = categories;
    });
  }

  String _getIconNameForSubject(String subject) {
    final lowerSubject = subject.toLowerCase();
    if (lowerSubject.contains('history')) return 'history';
    if (lowerSubject.contains('science')) return 'science';
    if (lowerSubject.contains('geography')) return 'geography';
    if (lowerSubject.contains('literature')) return 'literature';
    if (lowerSubject.contains('artificial') || lowerSubject.contains('ai')) return 'artificial_intelligence';
    if (lowerSubject.contains('python')) return 'python';
    if (lowerSubject.contains('cross') || lowerSubject.contains('platform')) return 'cross_platform';
    if (lowerSubject.contains('math')) return 'mathematical';
    return 'help_outline';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Categories'),
        backgroundColor: Colors.teal[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
            tooltip: 'Refresh Categories',
          ),
        ],
      ),
      body: _categories.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No quiz categories available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.85,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final questionCount = cat['questionCount'] as int;
                
                return GestureDetector(
                  onTap: questionCount > 0
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ModeSelectionScreen(subject: cat['name'] as String),
                            ),
                          );
                        }
                      : null,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: questionCount > 0 ? Colors.teal[100] : Colors.grey[300],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            iconFromName(cat['icon'] as String), 
                            size: 40, 
                            color: questionCount > 0 ? Colors.teal[700] : Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['name'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: questionCount > 0 ? Colors.black : Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Local fallback list of categories to display in quizzes and elsewhere
const List<Map<String, String>> _localCategories = [
  {'name': 'History', 'icon': 'history'},
  {'name': 'Science', 'icon': 'science'},
  {'name': 'Geography', 'icon': 'geography'},
  {'name': 'Literature', 'icon': 'literature'},
  {'name': 'Artificial Intelligence', 'icon': 'artificial_intelligence'},
  {'name': 'Python', 'icon': 'python'},
  {'name': 'Cross Platform', 'icon': 'cross_platform'},
  {'name': 'Mathematical', 'icon': 'mathematical'},
];
