import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mode_selection_screen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  Map<String, dynamic>? _cachedStats;
  String? _cachedUid;

  // List of subjects with corresponding icons
  static const List<Map<String, dynamic>> subjects = [
    {"name": "History", "icon": Icons.library_books},
    {"name": "Science", "icon": Icons.science},
    {"name": "Geography", "icon": Icons.travel_explore},
    {"name": "Literature", "icon": Icons.book},
    {"name": "Artificial Intelligence", "icon": Icons.computer},
    {"name": "Python", "icon": Icons.code},
    {"name": "Cross Platform", "icon": Icons.cast_for_education},
    {"name": "Mathematical", "icon": Icons.calculate},
  ];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final user = _auth.currentUser;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome back 👋",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Quick Stats Cards
              if (user != null) _buildQuickStatsCards(user.uid),
              const SizedBox(height: 20),

              // Quick start quiz button (random subject)
              ElevatedButton(
                onPressed: () {
                  var randomSubject = subjects[random.nextInt(subjects.length)];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ModeSelectionScreen(subject: randomSubject['name']),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Start Random Quiz", style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Recently Accessed Courses",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.0,
                children: subjects
                    .map((subject) => _buildCategoryCard(
                    context, subject['icon'], subject['name']))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build Quick Stats Cards
  Widget _buildQuickStatsCards(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Use cached stats if available for same user, otherwise fetch
        if (_cachedStats == null || _cachedUid != uid) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _getQuizStats(uid),
            builder: (context, statsSnapshot) {
              if (statsSnapshot.hasData) {
                _cachedStats = statsSnapshot.data;
                _cachedUid = uid;
              }
              
              final todayQuizzes = statsSnapshot.data?['today'] ?? 0;
              final weekQuizzes = statsSnapshot.data?['week'] ?? 0;
              final accuracy = statsSnapshot.data?['accuracy'] ?? 0;

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.today,
                    label: "Today",
                    value: "$todayQuizzes",
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.calendar_today,
                    label: "This Week",
                    value: "$weekQuizzes",
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.show_chart,
                    label: "Accuracy",
                    value: "$accuracy%",
                    color: Colors.green,
                  ),
                ),
              ],
            );
            },
          );
        }
        
        // Use cached stats
        final todayQuizzes = _cachedStats!['today'] ?? 0;
        final weekQuizzes = _cachedStats!['week'] ?? 0;
        final accuracy = _cachedStats!['accuracy'] ?? 0;
        
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.today,
                label: "Today",
                value: "$todayQuizzes",
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_today,
                label: "This Week",
                value: "$weekQuizzes",
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.show_chart,
                label: "Accuracy",
                value: "$accuracy%",
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  // Get quiz statistics for today and this week
  Future<Map<String, dynamic>> _getQuizStats(String uid) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final quizAttempts = await _firestore
          .collection('quizAttempts')
          .where('uid', isEqualTo: uid)
          .get();

      int todayCount = 0;
      int weekCount = 0;
      int totalCorrect = 0;
      int totalQuestions = 0;

      for (var doc in quizAttempts.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final correctAnswers = (data['correctAnswers'] ?? 0) as int;
        final totalQs = (data['totalQuestions'] ?? 0) as int;
        
        // Calculate overall accuracy
        totalCorrect += correctAnswers;
        totalQuestions += totalQs;
        
        if (createdAt != null) {
          if (createdAt.isAfter(todayStart)) {
            todayCount++;
          }
          if (createdAt.isAfter(weekStartDate)) {
            weekCount++;
          }
        }
      }

      // Calculate accuracy percentage
      final accuracy = totalQuestions > 0 
          ? ((totalCorrect / totalQuestions) * 100).round() 
          : 0;

      return {
        'today': todayCount, 
        'week': weekCount,
        'accuracy': accuracy,
      };
    } catch (e) {
      print('Error getting quiz stats: $e');
      return {'today': 0, 'week': 0, 'accuracy': 0};
    }
  }

  // Build individual stat card
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, IconData icon, String title) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.teal[100],
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ModeSelectionScreen(subject: title),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 45, color: Colors.teal[700]),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
