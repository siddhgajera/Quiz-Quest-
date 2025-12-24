import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../models/activity_model.dart';

class ActivityStatsWidget extends StatelessWidget {
  const ActivityStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        if (activityProvider.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final stats = activityProvider.getActivityStats();
        final timePeriodStats = activityProvider.getActivityCountsByPeriod();
        final mostActiveUsers = activityProvider.getMostActiveUsers(limit: 3);

        return Column(
          children: [
            // Activity Type Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Activity Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (stats.isEmpty)
                      const Text('No activity data available')
                    else
                      _buildActivityChart(stats),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Time Period Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Activity Timeline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTimelineChart(timePeriodStats),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Most Active Users
            if (mostActiveUsers.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.purple[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Most Active Users',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildUserRankingChart(mostActiveUsers),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTimePeriodStat(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getActivityTypeDisplayName(ActivityType type) {
    switch (type) {
      case ActivityType.userRegistered:
        return 'New Registrations';
      case ActivityType.userLogin:
        return 'User Logins';
      case ActivityType.quizCompleted:
        return 'Quiz Completions';
      case ActivityType.questionAdded:
        return 'Questions Added';
      case ActivityType.userPromoted:
        return 'User Promotions';
      case ActivityType.userDemoted:
        return 'User Demotions';
      case ActivityType.userActivated:
        return 'User Activations';
      case ActivityType.userDeactivated:
        return 'User Deactivations';
      case ActivityType.highScore:
        return 'High Scores';
      case ActivityType.profileUpdated:
        return 'Profile Updates';
      case ActivityType.passwordChanged:
        return 'Password Changes';
      case ActivityType.emailVerified:
        return 'Email Verifications';
    }
  }

  Color _getActivityTypeColor(ActivityType type) {
    switch (type) {
      case ActivityType.userRegistered:
        return Colors.green;
      case ActivityType.userLogin:
        return Colors.blue;
      case ActivityType.quizCompleted:
        return Colors.green;
      case ActivityType.questionAdded:
        return Colors.blue;
      case ActivityType.userPromoted:
        return Colors.orange;
      case ActivityType.userDemoted:
        return Colors.red;
      case ActivityType.userActivated:
        return Colors.green;
      case ActivityType.userDeactivated:
        return Colors.red;
      case ActivityType.highScore:
        return Colors.amber;
      case ActivityType.profileUpdated:
        return Colors.purple;
      case ActivityType.passwordChanged:
        return Colors.orange;
      case ActivityType.emailVerified:
        return Colors.green;
    }
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Gold
      case 1:
        return Colors.grey; // Silver
      case 2:
        return Colors.brown; // Bronze
      default:
        return Colors.blue;
    }
  }

  Widget _buildActivityChart(Map<ActivityType, int> stats) {
    final maxValue = stats.values.isEmpty ? 1 : stats.values.reduce((a, b) => a > b ? a : b);
    
    return Column(
      children: [
        // Horizontal bar chart
        ...stats.entries.map((entry) {
          final percentage = maxValue > 0 ? (entry.value / maxValue) : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getActivityTypeDisplayName(entry.key),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getActivityTypeColor(entry.key),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getActivityTypeColor(entry.key),
                            _getActivityTypeColor(entry.key).withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        
        const SizedBox(height: 16),
        
        // Pie chart representation
        _buildPieChart(stats),
      ],
    );
  }

  Widget _buildPieChart(Map<ActivityType, int> stats) {
    final total = stats.values.fold(0, (sum, value) => sum + value);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Circular progress indicators as pie chart
          Expanded(
            flex: 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 80,
                  width: 80,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(Colors.grey[300]),
                  ),
                ),
                ...stats.entries.map((entry) {
                  final percentage = entry.value / total;
                  return SizedBox(
                    height: 80,
                    width: 80,
                    child: CircularProgressIndicator(
                      value: percentage,
                      strokeWidth: 6,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(_getActivityTypeColor(entry.key)),
                    ),
                  );
                }).toList(),
                Text(
                  '$total\nTotal',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Legend
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: stats.entries.map((entry) {
                final percentage = ((entry.value / total) * 100).round();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getActivityTypeColor(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_getActivityTypeDisplayName(entry.key)} ($percentage%)',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineChart(Map<String, int> timePeriodStats) {
    final maxValue = timePeriodStats.values.isEmpty ? 1 : timePeriodStats.values.reduce((a, b) => a > b ? a : b);
    
    return Column(
      children: [
        // Bar chart
        Container(
          height: 120,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeBar('Today', timePeriodStats['today'] ?? 0, maxValue, Colors.blue),
              _buildTimeBar('This Week', timePeriodStats['thisWeek'] ?? 0, maxValue, Colors.green),
              _buildTimeBar('This Month', timePeriodStats['thisMonth'] ?? 0, maxValue, Colors.orange),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Stats summary
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTimePeriodStat('Today', timePeriodStats['today'] ?? 0, Colors.blue),
            _buildTimePeriodStat('This Week', timePeriodStats['thisWeek'] ?? 0, Colors.green),
            _buildTimePeriodStat('This Month', timePeriodStats['thisMonth'] ?? 0, Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeBar(String label, int value, int maxValue, Color color) {
    final height = maxValue > 0 ? (value / maxValue) * 80 : 0.0;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 40,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                color,
                color.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUserRankingChart(List<Map<String, dynamic>> mostActiveUsers) {
    if (mostActiveUsers.isEmpty) return const SizedBox.shrink();
    
    final maxCount = mostActiveUsers.first['count'] as int;
    
    return Column(
      children: mostActiveUsers.asMap().entries.map((entry) {
        final index = entry.key;
        final user = entry.value;
        final count = user['count'] as int;
        final percentage = maxCount > 0 ? (count / maxCount) : 0.0;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              // User info row
              Row(
                children: [
                  // Rank badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getRankColor(index),
                          _getRankColor(index).withValues(alpha: 0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getRankColor(index).withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // User avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: user['userProfileImage'] != null
                        ? NetworkImage(user['userProfileImage'])
                        : null,
                    child: user['userProfileImage'] == null
                        ? Text(
                            user['userName']?.isNotEmpty == true
                                ? user['userName'][0].toUpperCase()
                                : user['userEmail'][0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  
                  // User details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['userName']?.isNotEmpty == true
                              ? user['userName']
                              : user['userEmail'].split('@').first,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user['userEmail'],
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Activity count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple[400]!,
                          Colors.purple[600]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Progress bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getRankColor(index),
                          _getRankColor(index).withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
