import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../auth_service.dart';
import '../services/activity_service.dart';
import '../models/user_model.dart';

/// Provider for Admin User Management
/// - Streams user documents in real-time
/// - Wraps actions: promote/demote, activate/deactivate, remove user
class AdminUserProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirebaseFunctions _functions;

  AdminUserProvider({AuthService? authService, FirebaseFunctions? functions})
      : _authService = authService ?? AuthService(),
        _functions = functions ?? FirebaseFunctions.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllUsers({int limit = 1000}) {
    return _authService.streamUsers(limit: limit);
  }

  Future<void> toggleRole({required String uid, required String currentRole}) async {
    final String newRole = currentRole == 'admin' ? 'user' : 'admin';
    final res = await _authService.updateUserRole(uid: uid, role: newRole);
    if (!res.success) {
      throw Exception(res.message);
    }
    
    // Track role change activity
    try {
      final adminUser = await _authService.getUserModel();
      final targetUserDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      
      if (adminUser != null && targetUserDoc.exists) {
        final targetUser = UserModel.fromFirestore(targetUserDoc);
        
        if (newRole == 'admin') {
          await ActivityService.trackUserPromotion(targetUser, adminUser, newRole);
        } else {
          await ActivityService.trackUserDemotion(targetUser, adminUser, newRole);
        }
      }
    } catch (e) {
      print('Error tracking role change activity: $e');
    }
  }

  Future<void> toggleActive({required String uid, required bool isActive}) async {
    final res = await _authService.setActive(uid: uid, isActive: isActive);
    if (!res.success) {
      throw Exception(res.message);
    }
    
    // Track user status change activity
    try {
      final adminUser = await _authService.getUserModel();
      final targetUserDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      
      if (adminUser != null && targetUserDoc.exists) {
        final targetUser = UserModel.fromFirestore(targetUserDoc);
        await ActivityService.trackUserStatusChange(targetUser, adminUser, isActive);
      }
    } catch (e) {
      print('Error tracking status change activity: $e');
    }
  }

  /// Delete a user's auth account and Firestore data.
  /// Requires a callable Cloud Function deployed as `adminDeleteUser` with admin privileges.
  Future<void> removeUserCompletely({required String uid}) async {
    try {
      // 1) Delete Firestore user data and any storage assets (best-effort)
      await _authService.deleteUserData(uid: uid);

      // 2) Delete Auth user via Cloud Function (requires admin SDK)
      final HttpsCallable callable = _functions.httpsCallable('adminDeleteUser');
      await callable.call(<String, dynamic>{'uid': uid});
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Cloud Function failed');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Bulk update users to inactive based on last activity
  /// Sets users inactive if they haven't been active for more than specified hours
  Future<Map<String, dynamic>> bulkUpdateInactiveUsers({int inactiveHours = 24}) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      final now = DateTime.now();
      final cutoffTime = now.subtract(Duration(hours: inactiveHours));
      
      // Get all users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      int totalUsers = 0;
      int updatedUsers = 0;
      int skippedUsers = 0;
      
      final batch = FirebaseFirestore.instance.batch();
      
      for (final doc in usersSnapshot.docs) {
        totalUsers++;
        final data = doc.data();
        final uid = doc.id;
        
        // Skip current admin user
        if (uid == currentUser.uid) {
          skippedUsers++;
          continue;
        }
        
        // Check last activity
        final lastLoginAt = data['lastLoginAt'] as Timestamp?;
        final lastActive = data['lastActive'] as Timestamp?;
        
        // Use the most recent activity time
        DateTime? lastActivityTime;
        if (lastLoginAt != null && lastActive != null) {
          lastActivityTime = lastLoginAt.toDate().isAfter(lastActive.toDate()) 
              ? lastLoginAt.toDate() 
              : lastActive.toDate();
        } else if (lastLoginAt != null) {
          lastActivityTime = lastLoginAt.toDate();
        } else if (lastActive != null) {
          lastActivityTime = lastActive.toDate();
        }
        
        // If no activity time or activity is older than cutoff, set inactive
        final shouldBeInactive = lastActivityTime == null || lastActivityTime.isBefore(cutoffTime);
        final currentlyActive = data['isActive'] ?? false;
        
        if (shouldBeInactive && currentlyActive) {
          batch.update(doc.reference, {
            'isActive': false,
            'lastStatusUpdate': FieldValue.serverTimestamp(),
            'statusUpdatedBy': 'admin_bulk_update',
          });
          updatedUsers++;
        } else if (!shouldBeInactive && !currentlyActive) {
          // Optionally reactivate users who have been active recently
          batch.update(doc.reference, {
            'isActive': true,
            'lastStatusUpdate': FieldValue.serverTimestamp(),
            'statusUpdatedBy': 'admin_bulk_update',
          });
          updatedUsers++;
        }
      }
      
      // Commit the batch update
      if (updatedUsers > 0) {
        await batch.commit();
      }
      
      return {
        'success': true,
        'totalUsers': totalUsers,
        'updatedUsers': updatedUsers,
        'skippedUsers': skippedUsers,
        'cutoffTime': cutoffTime.toIso8601String(),
        'message': 'Updated $updatedUsers out of $totalUsers users (skipped $skippedUsers)',
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to bulk update users: $e',
      };
    }
  }

  /// Set all users except current admin to inactive (for testing/reset purposes)
  Future<Map<String, dynamic>> setAllUsersInactive({bool excludeCurrentUser = true}) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Get all users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      int totalUsers = 0;
      int updatedUsers = 0;
      int skippedUsers = 0;
      
      final batch = FirebaseFirestore.instance.batch();
      
      for (final doc in usersSnapshot.docs) {
        totalUsers++;
        final uid = doc.id;
        
        // Skip current user if requested
        if (excludeCurrentUser && uid == currentUser.uid) {
          skippedUsers++;
          continue;
        }
        
        batch.update(doc.reference, {
          'isActive': false,
          'lastStatusUpdate': FieldValue.serverTimestamp(),
          'statusUpdatedBy': 'admin_bulk_inactive',
        });
        updatedUsers++;
      }
      
      // Commit the batch update
      if (updatedUsers > 0) {
        await batch.commit();
      }
      
      return {
        'success': true,
        'totalUsers': totalUsers,
        'updatedUsers': updatedUsers,
        'skippedUsers': skippedUsers,
        'message': 'Set $updatedUsers users to inactive (skipped $skippedUsers)',
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to set users inactive: $e',
      };
    }
  }

  /// Guard that current user is admin
  Future<bool> currentUserIsAdmin() => _authService.isAdmin();

  User? get currentUser => _authService.currentUser;
}
