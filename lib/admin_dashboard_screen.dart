import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin_question_management_screen.dart';
import 'screens/admin_user_management_screen.dart';
import 'screens/admin_activity_dashboard.dart';
import 'providers/activity_provider.dart';
import 'providers/admin_stats_provider.dart';
import 'widgets/activity_widgets.dart';
import 'models/activity_model.dart';

class AdminDashboardScreen extends StatelessWidget {
  final String adminName;
  final Function(int)? onTabChange;

  const AdminDashboardScreen({super.key, required this.adminName, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[25],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<AdminStatsProvider>().refreshStats();
            await context.read<ActivityProvider>().refreshActivities();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Message
              Text(
                "Welcome back, $adminName! 👋",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Admin Dashboard",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blue[600],
                ),
              ),
              const SizedBox(height: 30),

              // Statistics Cards (responsive to avoid overflow)
              Consumer<AdminStatsProvider>(
                builder: (context, statsProvider, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Compute a safer aspect ratio based on width.
                      // On narrow screens, make cards shorter to avoid vertical overflow.
                      final isNarrow = constraints.maxWidth < 380;
                      final aspect = isNarrow ? 0.9 : 1.15;
                      return GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: aspect,
                        children: [
                          _buildStatsCard(
                            title: "Total Questions",
                            value: statsProvider.isLoading ? "..." : "${statsProvider.totalQuestions}",
                            icon: Icons.quiz,
                            color: Colors.blue,
                            isLoading: statsProvider.isLoading,
                          ),
                          _buildStatsCard(
                            title: "Active Users",
                            value: statsProvider.isLoading ? "..." : "${statsProvider.activeUsers}",
                            icon: Icons.people,
                            color: Colors.green,
                            isLoading: statsProvider.isLoading,
                          ),
                          _buildStatsCard(
                            title: "Quiz Categories",
                            value: statsProvider.isLoading ? "..." : "${statsProvider.quizCategories}",
                            icon: Icons.category,
                            color: Colors.orange,
                            isLoading: statsProvider.isLoading,
                          ),
                          _buildStatsCard(
                            title: "Total Quizzes",
                            value: statsProvider.isLoading ? "..." : "${statsProvider.totalQuizzes}",
                            icon: Icons.assessment,
                            color: Colors.purple,
                            isLoading: statsProvider.isLoading,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 30),

              // Quick Actions
              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Column(
                children: [
                  _buildQuickActionTile(
                    context,
                    title: "Manage Questions",
                    subtitle: "Add, edit, or delete quiz questions",
                    icon: Icons.quiz,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminQuestionManagementScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActionTile(
                    context,
                    title: "User Management",
                    subtitle: "View and manage registered users",
                    icon: Icons.people,
                    color: Colors.green,
                    onTap: () {
                      // Navigate to Users tab (index 2) if callback is available
                      if (onTabChange != null) {
                        onTabChange!(2);
                      } else {
                        // Fallback to pushing new screen if no callback
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminUserManagementScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActionTile(
                    context,
                    title: "Activity Dashboard",
                    subtitle: "View detailed user activity analytics",
                    icon: Icons.timeline,
                    color: Colors.purple,
                    onTap: () {
                      // Navigate to Activity tab (index 3) if callback is available
                      if (onTabChange != null) {
                        onTabChange!(3);
                      } else {
                        // Fallback to pushing new screen if no callback
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider(
                              create: (_) => ActivityProvider(),
                              child: const AdminActivityDashboard(),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),

              const SizedBox(height: 30),

              // Recent Activity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Activity",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to Activity tab (index 3) if callback is available
                      if (onTabChange != null) {
                        onTabChange!(3);
                      } else {
                        // Fallback to pushing new screen if no callback
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider(
                              create: (_) => ActivityProvider(),
                              child: const AdminActivityDashboard(),
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildRecentActivitySection(),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isLoading = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue[50],
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue[100]!.withOpacity(0.3), Colors.blue[50]!.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : Text(
                      value,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        if (activityProvider.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (activityProvider.error != null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading activities',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activityProvider.error!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => activityProvider.refreshActivities(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final activities = activityProvider.activities.take(4).toList();

        if (activities.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.library_books,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No recent activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'User activities will appear here',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Column(
            children: [
              ...activities.asMap().entries.map((entry) {
                final index = entry.key;
                final activity = entry.value;
                return Column(
                  children: [
                    ActivityTile(
                      activity: activity,
                      onTap: () => _showActivityDetail(context, activity),
                    ),
                    if (index < activities.length - 1)
                      const Divider(height: 1),
                  ],
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showActivityDetail(BuildContext context, ActivityModel activity) {
    showDialog(
      context: context,
      builder: (context) => ActivityDetailDialog(activity: activity),
    );
  }

}
