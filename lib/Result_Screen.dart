import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'mode_selection_screen.dart';

class ResultsScreen extends StatelessWidget {
  final int score;
  final int total;
  final String? subject;

  const ResultsScreen({
    super.key, 
    required this.score, 
    required this.total,
    this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score / total * 100).round();
    final isPerfect = score == total;
    final isExcellent = percentage >= 80;
    final isGood = percentage >= 60;
    final isFair = percentage >= 40;

    // Determine performance message and color
    String performanceMessage;
    Color performanceColor;
    IconData performanceIcon;

    if (isPerfect) {
      performanceMessage = "Perfect! 🎉";
      performanceColor = Colors.amber;
      performanceIcon = Icons.emoji_events;
    } else if (isExcellent) {
      performanceMessage = "Excellent! 🌟";
      performanceColor = Colors.green;
      performanceIcon = Icons.star;
    } else if (isGood) {
      performanceMessage = "Good Job! 👍";
      performanceColor = Colors.blue;
      performanceIcon = Icons.thumb_up;
    } else if (isFair) {
      performanceMessage = "Keep Practicing! 💪";
      performanceColor = Colors.orange;
      performanceIcon = Icons.trending_up;
    } else {
      performanceMessage = "Try Again! 📚";
      performanceColor = Colors.red;
      performanceIcon = Icons.refresh;
    }

    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text("Quiz Results"),
        backgroundColor: Colors.teal[700],
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Performance Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: performanceColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  performanceIcon,
                  size: 80,
                  color: performanceColor,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Performance Message
              Text(
                performanceMessage,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: performanceColor,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Score Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        "Your Score",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "$score",
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[700],
                            ),
                          ),
                          Text(
                            " / $total",
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: performanceColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$percentage%",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: performanceColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Stats Breakdown
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Correct",
                      "$score",
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      "Wrong",
                      "${total - score}",
                      Icons.cancel,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Action Buttons
              if (subject != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ModeSelectionScreen(subject: subject!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      "Try Again",
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              
              if (subject != null) const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text(
                    "Go to Home",
                    style: TextStyle(fontSize: 18),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal[700],
                    padding: const EdgeInsets.all(16),
                    side: BorderSide(color: Colors.teal[700]!, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
