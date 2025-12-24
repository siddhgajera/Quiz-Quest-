import 'package:flutter/material.dart';
import 'services/score_service.dart';
import 'services/question_service.dart';

class AdminLeaderboardManagementScreen extends StatefulWidget {
  const AdminLeaderboardManagementScreen({super.key});

  @override
  State<AdminLeaderboardManagementScreen> createState() =>
      _AdminLeaderboardManagementScreenState();
}

class _AdminLeaderboardManagementScreenState extends State<AdminLeaderboardManagementScreen> {
  final _scoreService = ScoreService();
  final _questionService = QuestionService();
  String _subject = 'All';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leaderboard'),
          backgroundColor: Colors.red[800],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.public), text: 'Global'),
              Tab(icon: Icon(Icons.category), text: 'By Category'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGlobalTab(),
            _buildCategoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[700]!;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Colors.blue;
    }
  }

  Color _getTrophyColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[700]!;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Colors.grey;
    }
  }

  Widget _buildGlobalTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _scoreService.streamGlobalLeaderboard(limit: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final u = items[index];
            final rank = index + 1;
            final name = (u['name'] ?? u['email'] ?? 'User').toString();
            final score = (u['totalScore'] ?? 0) as int;
            final quizzes = (u['quizzesCompleted'] ?? 0) as int;
            final avatar = (u['profileImageUrl'] ?? '').toString();
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: rank <= 3 ? 6 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: rank <= 3 ? const BorderSide(color: Colors.amber, width: 2) : BorderSide.none,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRankColor(rank),
                  child: Text('#$rank', style: const TextStyle(color: Colors.white)),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Score: $score · Quizzes: $quizzes'),
                trailing: rank <= 3 ? Icon(Icons.emoji_events, color: _getTrophyColor(rank)) : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryTab() {
    return Column(
      children: [
        StreamBuilder<List<String>>(
          stream: _questionService.streamCategories(),
          builder: (context, snapshot) {
            final cats = snapshot.data ?? const <String>[];
            final items = ['All', ...cats];
            if (!items.contains(_subject)) _subject = 'All';
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Text('Subject: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _subject,
                    items: items
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _subject = v ?? 'All'),
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: _subject == 'All'
              ? const Center(child: Text('Select a subject to view category leaderboard.'))
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _scoreService.streamCategoryLeaderboard(_subject, limit: 100),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const Center(child: Text('No entries yet for this subject.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final row = items[index];
                        final rank = index + 1;
                        final score = (row['score'] ?? 0) as int;
                        final subject = (row['subject'] ?? '').toString();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getRankColor(rank),
                              child: Text('#$rank', style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(subject),
                            subtitle: Text('Score: $score'),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
