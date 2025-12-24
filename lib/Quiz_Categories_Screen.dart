import 'package:flutter/material.dart';
import 'dart:async';
import 'mode_selection_screen.dart';
import 'services/question_service.dart';
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
  // Removed _loadCategories and associated manual state

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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: QuestionService().streamCategoriesWithMetadata(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return const Center(
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
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.85,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final String subjectName = cat['name'] as String;
              final int totalQuestions = cat['total'] as int;
              
              return GestureDetector(
                onTap: totalQuestions > 0
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ModeSelectionScreen(
                              subject: subjectName,
                              categoryMetadata: cat,
                            ),
                          ),
                        );
                      }
                    : null,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: totalQuestions > 0 ? Colors.teal[100] : Colors.grey[300],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          iconFromName(_getIconNameForSubject(subjectName)), 
                          size: 40, 
                          color: totalQuestions > 0 ? Colors.teal[700] : Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subjectName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: totalQuestions > 0 ? Colors.black : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (totalQuestions > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$totalQuestions Questions',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.teal[800],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
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
