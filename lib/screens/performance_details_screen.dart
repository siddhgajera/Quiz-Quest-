import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PerformanceDetailsScreen extends StatelessWidget {
  const PerformanceDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Performance Details'),
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view performance details'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('Quiz Performance Details'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('categoryStats')
            .orderBy('score', descending: true)
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
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Summary Card
                _buildSummaryCard(categoryStats),
                
                const SizedBox(height: 24),
                
                // Performance by Subject Header
                Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.teal[700], size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Performance by Subject',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Subject Performance List
                ...categoryStats.map((doc) => _buildDetailedSubjectCard(doc.data() as Map<String, dynamic>)),
                
                const SizedBox(height: 24),
                
                // Performance Insights
                _buildInsightsCard(categoryStats),
              ],
            ),
          );
        },
      ),
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
        ? ((totalCorrect / (totalAttempts * 10)) * 100).round()
        : 0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.teal[600]!, Colors.teal[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Overall Performance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Subjects',
                    '${categoryStats.length}',
                    Icons.category,
                    Colors.white,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Attempts',
                    '$totalAttempts',
                    Icons.quiz,
                    Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Overall Accuracy',
                    '$overallAccuracy%',
                    Icons.track_changes,
                    Colors.white,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Points',
                    '$totalScore',
                    Icons.stars,
                    Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.8), size: 24),
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
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailedSubjectCard(Map<String, dynamic> data) {
    final subject = data['subject'] ?? 'Unknown';
    final attempts = data['attempts'] ?? 0;
    final score = data['score'] ?? 0;
    final accuracy = data['accuracy'] ?? 0;
    final averageScore = data['averageScore'] ?? 0;
    final lastDifficulty = data['lastDifficulty'] ?? 'Unknown';
    final correct = data['correct'] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subject,
                    style: TextStyle(
                      color: Colors.teal[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  _getPerformanceIcon(accuracy),
                  color: _getPerformanceColor(accuracy),
                  size: 24,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Performance Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Attempts',
                    '$attempts',
                    Icons.replay,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Accuracy',
                    '$accuracy%',
                    Icons.track_changes,
                    _getPerformanceColor(accuracy),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Avg Score',
                    '$averageScore',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Total Points',
                    '$score',
                    Icons.stars,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Additional Details
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Correct Answers',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '$correct',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(lastDifficulty).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Last Difficulty',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          lastDifficulty.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getDifficultyColor(lastDifficulty),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(List<QueryDocumentSnapshot> categoryStats) {
    if (categoryStats.isEmpty) return const SizedBox.shrink();
    
    // Find best and worst performing subjects
    final sortedByAccuracy = categoryStats.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'subject': data['subject'] ?? 'Unknown',
        'accuracy': data['accuracy'] ?? 0,
        'score': data['score'] ?? 0,
      };
    }).toList()..sort((a, b) => (b['accuracy'] as int).compareTo(a['accuracy'] as int));
    
    final bestSubject = sortedByAccuracy.first;
    final worstSubject = sortedByAccuracy.last;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber[700], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Performance Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Best Subject
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Strongest Subject: ${bestSubject['subject']} (${bestSubject['accuracy']}% accuracy)',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Improvement Area
            if (sortedByAccuracy.length > 1)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Focus Area: ${worstSubject['subject']} (${worstSubject['accuracy']}% accuracy)',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 64),
            const SizedBox(height: 16),
            const Text(
              'Error loading performance data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, color: Colors.teal[300], size: 64),
            const SizedBox(height: 16),
            const Text(
              'No performance data yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete some quizzes to see detailed performance analytics!',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPerformanceIcon(int accuracy) {
    if (accuracy >= 80) return Icons.star;
    if (accuracy >= 60) return Icons.thumb_up;
    if (accuracy >= 40) return Icons.trending_up;
    return Icons.trending_down;
  }

  Color _getPerformanceColor(int accuracy) {
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.blue;
    if (accuracy >= 40) return Colors.orange;
    return Colors.red;
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
