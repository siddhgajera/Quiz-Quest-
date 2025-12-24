import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileStatsCards extends StatelessWidget {
  const ProfileStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view stats'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorCards();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCards();
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        return _buildStatsCards(userData ?? {});
      },
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> userData) {
    final quizzesCompleted = userData['quizzesCompleted'] ?? 0;
    final totalScore = userData['totalScore'] ?? 0;
    final averageScore = userData['averageScore'] ?? 0;
    final highestScore = userData['highestScore'] ?? 0;

    return Column(
      children: [
        // First row - 2 cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Quizzes Done',
                value: '$quizzesCompleted',
                icon: Icons.quiz,
                color: Colors.blue,
                subtitle: quizzesCompleted > 0 ? 'Keep going!' : 'Start your first quiz',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Average Score',
                value: '$averageScore',
                icon: Icons.trending_up,
                color: Colors.green,
                subtitle: averageScore > 0 ? _getPerformanceLevel(averageScore) : 'No data yet',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row - 2 cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Points',
                value: '$totalScore',
                icon: Icons.stars,
                color: Colors.orange,
                subtitle: totalScore > 0 ? _getPointsLevel(totalScore) : 'Earn your first points',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Highest Score',
                value: '$highestScore',
                icon: Icons.emoji_events,
                color: Colors.amber,
                subtitle: highestScore > 0 ? 'Personal best!' : 'Set your record',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 140, // Further increased height to prevent overflow
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildLoadingCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildLoadingCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildLoadingCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildLoadingCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildErrorCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildErrorCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildErrorCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildErrorCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300]),
            const SizedBox(height: 8),
            Text(
              'Error loading data',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[300],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getPerformanceLevel(int averageScore) {
    if (averageScore >= 80) return 'Excellent!';
    if (averageScore >= 60) return 'Good job!';
    if (averageScore >= 40) return 'Keep improving!';
    return 'Practice more!';
  }

  String _getPointsLevel(int totalScore) {
    if (totalScore >= 1000) return 'Quiz Master!';
    if (totalScore >= 500) return 'Quiz Expert!';
    if (totalScore >= 200) return 'Quiz Enthusiast!';
    if (totalScore >= 50) return 'Getting started!';
    return 'Beginner';
  }
}
