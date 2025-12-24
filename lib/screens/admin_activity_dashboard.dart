import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../widgets/activity_widgets.dart';
import '../widgets/activity_stats_widget.dart';
import '../models/activity_model.dart';

class AdminActivityDashboard extends StatefulWidget {
  const AdminActivityDashboard({super.key});

  @override
  State<AdminActivityDashboard> createState() => _AdminActivityDashboardState();
}

class _AdminActivityDashboardState extends State<AdminActivityDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showingStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Dashboard'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showingStats ? Icons.list : Icons.analytics),
            onPressed: () {
              setState(() {
                _showingStats = !_showingStats;
              });
            },
            tooltip: _showingStats ? 'Show Activities' : 'Show Analytics Dashboard',
          ),
          // REMOVED: The PopupMenuButton (3-dot menu) and its functionality have been removed.
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.blue[200],
          tabs: const [
            Tab(icon: Icon(Icons.timeline), text: 'Recent'),
            Tab(icon: Icon(Icons.people), text: 'By User'),
          ],
        ),
      ),
      body: _showingStats
          ? const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: ActivityStatsWidget(),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildRecentActivitiesTab(),
          _buildActivitiesByUserTab(),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesTab() {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        if (activityProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (activityProvider.error != null) {
          return _buildErrorWidget(activityProvider.error!);
        }

        final activities = activityProvider.activities;

        if (activities.isEmpty) {
          return _buildEmptyWidget();
        }

        return RefreshIndicator(
          onRefresh: () => activityProvider.refreshActivities(),
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ActivityCard(
                activity: activity,
                onTap: () => _showActivityDetail(activity),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActivitiesByUserTab() {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        if (activityProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final mostActiveUsers = activityProvider.getMostActiveUsers(limit: 20);

        if (mostActiveUsers.isEmpty) {
          return _buildEmptyWidget();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mostActiveUsers.length,
          itemBuilder: (context, index) {
            final user = mostActiveUsers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  backgroundImage: user['userProfileImage'] != null
                      ? NetworkImage(user['userProfileImage'])
                      : null,
                  child: user['userProfileImage'] == null
                      ? Text(
                    user['userName']?.isNotEmpty == true
                        ? user['userName'][0].toUpperCase()
                        : user['userEmail'][0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  )
                      : null,
                ),
                title: Text(
                  user['userName']?.isNotEmpty == true
                      ? user['userName']
                      : user['userEmail'].split('@').first,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(user['userEmail']),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${user['count']} activities',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                children: [
                  StreamBuilder<List<ActivityModel>>(
                    stream: activityProvider.getUserActivities(user['userId']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final userActivities = snapshot.data ?? [];

                      if (userActivities.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No activities found for this user'),
                        );
                      }

                      return Column(
                        children: userActivities.take(5).map((activity) {
                          return ActivityTile(
                            activity: activity,
                            showUserInfo: false,
                            onTap: () => _showActivityDetail(activity),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.blue[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading activities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<ActivityProvider>().refreshActivities(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No activities found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'User activities will appear here as they happen',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<ActivityProvider>().refreshActivities(),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Activities'),
          ),
        ],
      ),
    );
  }

  void _showActivityDetail(ActivityModel activity) {
    showDialog(
      context: context,
      builder: (context) => ActivityDetailDialog(activity: activity),
    );
  }

// REMOVED: The dialog methods are no longer needed.
}