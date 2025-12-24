import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';

class ActivityProvider with ChangeNotifier {
  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  String? _error;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;

  List<ActivityModel> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreData => _hasMoreData;

  // Stream subscription for real-time updates
  StreamSubscription<List<ActivityModel>>? _activitySubscription;

  ActivityProvider() {
    _initializeActivities();
  }

  void _initializeActivities() {
    _activitySubscription = ActivityService.getRecentActivities(limit: 20)
        .listen(
      (activities) {
        _activities = activities;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Load more activities for pagination
  Future<void> loadMoreActivities() async {
    if (_isLoading || !_hasMoreData) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newActivities = await ActivityService.getRecentActivities(
        limit: 10,
        lastDocument: _lastDocument,
      ).first;

      if (newActivities.isEmpty) {
        _hasMoreData = false;
      } else {
        _activities.addAll(newActivities);
        // Note: In a real implementation, you'd need to get the last document
        // from the query result for proper pagination
      }

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh activities
  Future<void> refreshActivities() async {
    _isLoading = true;
    _error = null;
    _hasMoreData = true;
    _lastDocument = null;
    notifyListeners();

    // Cancel existing subscription and reinitialize
    await _activitySubscription?.cancel();
    _initializeActivities();
  }

  // Get activities by type
  Stream<List<ActivityModel>> getActivitiesByType(ActivityType type) {
    return ActivityService.getActivitiesByType(type);
  }

  // Get user activities
  Stream<List<ActivityModel>> getUserActivities(String userId) {
    return ActivityService.getUserActivities(userId);
  }

  // Get activity statistics (excluding sample data)
  Map<ActivityType, int> getActivityStats() {
    final stats = <ActivityType, int>{};
    
    // Filter out sample activities
    final realActivities = _activities.where((activity) => !activity.userId.startsWith('sample_'));
    
    for (final activity in realActivities) {
      stats[activity.type] = (stats[activity.type] ?? 0) + 1;
    }
    
    return stats;
  }

  // Get recent activities count by time period (excluding sample data)
  Map<String, int> getActivityCountsByPeriod() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeek = today.subtract(Duration(days: now.weekday - 1));
    final thisMonth = DateTime(now.year, now.month, 1);

    int todayCount = 0;
    int yesterdayCount = 0;
    int thisWeekCount = 0;
    int thisMonthCount = 0;

    // Filter out sample activities
    final realActivities = _activities.where((activity) => !activity.userId.startsWith('sample_'));

    for (final activity in realActivities) {
      if (activity.timestamp.isAfter(today)) {
        todayCount++;
      } else if (activity.timestamp.isAfter(yesterday)) {
        yesterdayCount++;
      }
      
      if (activity.timestamp.isAfter(thisWeek)) {
        thisWeekCount++;
      }
      
      if (activity.timestamp.isAfter(thisMonth)) {
        thisMonthCount++;
      }
    }

    return {
      'today': todayCount,
      'yesterday': yesterdayCount,
      'thisWeek': thisWeekCount,
      'thisMonth': thisMonthCount,
    };
  }

  // Get most active users (excluding sample data)
  List<Map<String, dynamic>> getMostActiveUsers({int limit = 5}) {
    final userActivityCount = <String, Map<String, dynamic>>{};

    // Filter out sample activities
    final realActivities = _activities.where((activity) => !activity.userId.startsWith('sample_'));

    for (final activity in realActivities) {
      if (userActivityCount.containsKey(activity.userId)) {
        userActivityCount[activity.userId]!['count']++;
      } else {
        userActivityCount[activity.userId] = {
          'userId': activity.userId,
          'userName': activity.userName,
          'userEmail': activity.userEmail,
          'userProfileImage': activity.userProfileImage,
          'count': 1,
        };
      }
    }

    final sortedUsers = userActivityCount.values.toList()
      ..sort((a, b) => b['count'].compareTo(a['count']));

    return sortedUsers.take(limit).toList();
  }


  // Clear all activities (use with caution)
  Future<void> clearAllActivities() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ActivityService.clearAllActivities();
      // Refresh activities after clearing
      await refreshActivities();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    super.dispose();
  }
}
