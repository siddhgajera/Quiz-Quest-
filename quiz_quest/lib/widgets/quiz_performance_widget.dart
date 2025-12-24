import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/performance_details_screen.dart';

class QuizPerformanceWidget extends StatelessWidget {
  const QuizPerformanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Please log in to view performance data'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quiz-wise Performance',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PerformanceDetailsScreen(),
                  ),
                );
              },
              icon: Icon(Icons.analytics, color: Colors.teal[600], size: 20),
              label: Text(
                'View Details',
                style: TextStyle(
                  color: Colors.teal[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.teal[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Instructions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.teal[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.teal[600], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Showing your most recent quiz attempts. Click "View Details" for complete analytics.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.teal[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('categoryStats')
              .orderBy('lastAttempt', descending: true)
              .limit(2) // Show only 2 most recent
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorWidget();
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingWidget();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyWidget();
            }

            final categoryStats = snapshot.data!.docs;
            return _buildPerformanceGrid(categoryStats);
          },
        ),
      ],
    );
  }

  Widget _buildPerformanceGrid(List<QueryDocumentSnapshot> categoryStats) {
    return Column(
      children: [
        // Summary card
        _buildSummaryCard(categoryStats),
        const SizedBox(height: 16),
        // Individual subject cards
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categoryStats.length,
          itemBuilder: (context, index) {
            final data = categoryStats[index].data() as Map<String, dynamic>;
            return _buildSubjectCard(data);
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(List<QueryDocumentSnapshot> categoryStats) {
    int totalAttempts = 0;
    int totalCorrect = 0;
    int totalScore = 0;
    
    for (var doc in categoryStats) {
      final data = doc.data() as Map<String, dynamic>;
      totalAttempts += (data['attempts'] ?? 0) as int;
      totalCorrect += (data['correct'] ?? 0) as int;
      totalScore += (data['score'] ?? 0) as int;
    }

    final overallAccuracy = totalAttempts > 0 
        ? ((totalCorrect / (totalAttempts * 10)) * 100).round() // Assuming 10 questions per quiz
        : 0;

    return Card(
      elevation: 3,
      color: Colors.teal[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              icon: Icons.category,
              label: 'Recent Subjects',
              value: '${categoryStats.length}',
              color: Colors.blue,
            ),
            _buildSummaryItem(
              icon: Icons.quiz,
              label: 'Recent Attempts',
              value: '$totalAttempts',
              color: Colors.green,
            ),
            _buildSummaryItem(
              icon: Icons.check_circle,
              label: 'Accuracy',
              value: '$overallAccuracy%',
              color: Colors.orange,
            ),
            _buildSummaryItem(
              icon: Icons.star,
              label: 'Total Points',
              value: '$totalScore',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> data) {
    final subject = data['subject'] ?? 'Unknown';
    final attempts = data['attempts'] ?? 0;
    final score = data['score'] ?? 0;
    final accuracy = data['accuracy'] ?? 0;
    final averageScore = data['averageScore'] ?? 0;
    final lastDifficulty = data['lastDifficulty'] ?? 'Unknown';

    // Get subject color
    final subjectColor = _getSubjectColor(subject);
    
    // Get performance icon
    final performanceIcon = _getPerformanceIcon(accuracy);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              subjectColor.withValues(alpha: 0.1),
              subjectColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subject,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: subjectColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(performanceIcon, color: subjectColor, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              
              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow('Attempts', '$attempts', Icons.replay),
                    _buildStatRow('Accuracy', '$accuracy%', Icons.track_changes),
                    _buildStatRow('Avg Score', '$averageScore', Icons.trending_up),
                    _buildStatRow('Total Points', '$score', Icons.stars),
                  ],
                ),
              ),
              
              // Difficulty badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(lastDifficulty),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Last: $lastDifficulty',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.quiz_outlined, color: Colors.teal[300], size: 64),
            const SizedBox(height: 16),
            const Text(
              'No recent quiz attempts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Take some quizzes to see your recent performance here!',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading performance data',
              style: TextStyle(color: Colors.red[300]),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    final colors = {
      'Science': Colors.green,
      'Math': Colors.blue,
      'History': Colors.orange,
      'Geography': Colors.teal,
      'Literature': Colors.purple,
      'Technology': Colors.indigo,
      'Sports': Colors.red,
      'Art': Colors.pink,
    };
    return colors[subject] ?? Colors.grey;
  }

  IconData _getPerformanceIcon(int accuracy) {
    if (accuracy >= 80) return Icons.star;
    if (accuracy >= 60) return Icons.thumb_up;
    if (accuracy >= 40) return Icons.trending_up;
    return Icons.trending_down;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
