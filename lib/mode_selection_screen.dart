import 'package:flutter/material.dart';
import 'question_display_screen.dart';
import 'question_bank.dart';
import 'services/config_service.dart';

class ModeSelectionScreen extends StatefulWidget {
  final String subject;
  final Map<String, dynamic>? categoryMetadata;

  const ModeSelectionScreen({
    super.key, 
    required this.subject,
    this.categoryMetadata,
  });

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  int _configuredQuestionCount = 10;

  @override
  void initState() {
    super.initState();
    _loadConfiguredQuestionCount();
  }

  Future<void> _loadConfiguredQuestionCount() async {
    final count = await ConfigService().getQuestionsPerQuiz(fallback: 10);
    if (mounted) {
      setState(() {
        _configuredQuestionCount = count;
      });
    }
  }

  int _getExpectedQuestionCount(String difficulty) {
    if (widget.categoryMetadata != null) {
      final availableCount = (widget.categoryMetadata![difficulty] ?? 0) as int;
      
      if (availableCount <= 5) {
        return availableCount;
      } else if (availableCount <= 10) {
        return availableCount.clamp(0, 8);
      } else if (availableCount <= 20) {
        return availableCount.clamp(0, 15);
      } else {
        return availableCount.clamp(0, _configuredQuestionCount.clamp(20, availableCount));
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.subject} - Select Mode"),
        backgroundColor: Colors.teal[700],
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Choose Your Difficulty",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
            ),
            const SizedBox(height: 24),

            // Difficulty Cards
            _difficultyCard(context, "Easy", Icons.sentiment_very_satisfied, widget.subject, "easy",
                Colors.green.shade100, _getExpectedQuestionCount("easy")),
            _difficultyCard(context, "Medium", Icons.sentiment_neutral, widget.subject, "medium",
                Colors.orange.shade100, _getExpectedQuestionCount("medium")),
            _difficultyCard(context, "Hard", Icons.sentiment_very_dissatisfied, widget.subject, "hard",
                Colors.red.shade100, _getExpectedQuestionCount("hard")),
          ],
        ),
      ),
    );
  }

  Widget _difficultyCard(BuildContext context, String title, IconData icon, String subject,
      String difficulty, Color color, int questionCount) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                QuestionDisplayScreen(subject: subject, difficulty: difficulty),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 30,
              child: Icon(icon, color: Colors.teal[700], size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                  Text(
                    "$questionCount Questions Available",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.teal[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.teal, size: 20),
          ],
        ),
      ),
    );
  }
}
