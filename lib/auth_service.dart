import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'dart:io';
import 'models/user_model.dart';
import 'services/activity_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password (no email verification required)
  Future<AuthResult> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      if (result.user != null) {
        // Update last login time
        await _updateLastLoginTime(result.user!.uid);
        
        // Track login activity
        try {
          final userModel = await getUserModel();
          if (userModel != null) {
            await ActivityService.trackUserLogin(userModel);
          }
        } catch (e) {
          print('Error tracking login activity: $e');
        }
        
        return AuthResult(success: true, user: result.user, message: 'Sign in successful');
      }
      
      return AuthResult(success: false, message: 'Sign in failed');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult(success: false, message: 'An unexpected error occurred');
    }
  }

  // Sign up with email and password (no email verification required)
  Future<AuthResult> signUpWithEmailAndPassword(String email, String password, String name) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user != null) {
        // Create user document directly to avoid model mismatches
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'emailLower': email.toLowerCase(),
          'name': name,
          'role': 'user',
          'isAdmin': false,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'quizzesCompleted': 0,
          'totalScore': 0,
          // WARNING: storing raw password is insecure; kept to match existing behavior
          'password': password,
        }, SetOptions(merge: true));

        // Track user registration activity
        try {
          final userModel = UserModel(
            uid: user.uid,
            email: email,
            name: name,
            createdAt: DateTime.now(),
            isEmailVerified: user.emailVerified,
          );
          await ActivityService.trackUserRegistration(userModel);
        } catch (e) {
          print('Error tracking registration activity: $e');
        }

        return AuthResult(
          success: true,
          user: user,
          message: 'Account created successfully!',
          requiresEmailVerification: false,
        );
      }

      return AuthResult(success: false, message: 'Account creation failed');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult(success: false, message: 'An unexpected error occurred');
    }
  }

  // Send email verification
  Future<AuthResult> sendEmailVerification() async {
    try {
      if (currentUser != null) {
        await currentUser!.sendEmailVerification();
        return AuthResult(success: true, message: 'Verification email sent');
      }
      return AuthResult(success: false, message: 'No user signed in');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to send verification email');
    }
  }

  // Check email verification status
  Future<bool> checkEmailVerification() async {
    if (currentUser != null) {
      await currentUser!.reload();
      return currentUser!.emailVerified;
    }
    return false;
  }

  // Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(success: true, message: 'Password reset email sent');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to send password reset email');
    }
  }

  // Update password
  Future<AuthResult> updatePassword(String currentPassword, String newPassword) async {
    try {
      if (currentUser == null) {
        return AuthResult(success: false, message: 'No user signed in');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: currentPassword,
      );
      
      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.updatePassword(newPassword);
      
      // Track password change activity
      try {
        final userModel = await getUserModel();
        if (userModel != null) {
          await ActivityService.trackPasswordChange(userModel);
        }
      } catch (e) {
        print('Error tracking password change activity: $e');
      }
      
      return AuthResult(success: true, message: 'Password updated successfully');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to update password');
    }
  }

  // Get user model
  Future<UserModel?> getUserModel() async {
    if (currentUser == null) return null;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }

  // Update user profile
  Future<AuthResult> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? bio,
    DateTime? dateOfBirth,
    String? location,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      if (currentUser == null) {
        return AuthResult(success: false, message: 'No user signed in');
      }

      Map<String, dynamic> updates = {};
      
      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (bio != null) updates['bio'] = bio;
      if (dateOfBirth != null) updates['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
      if (location != null) updates['location'] = location;
      if (preferences != null) updates['preferences'] = preferences;

      await _firestore.collection('users').doc(currentUser!.uid).update(updates);
      
      // Track profile update activity
      try {
        final userModel = await getUserModel();
        if (userModel != null) {
          await ActivityService.trackProfileUpdate(userModel);
        }
      } catch (e) {
        print('Error tracking profile update activity: $e');
      }
      
      return AuthResult(success: true, message: 'Profile updated successfully');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to update profile');
    }
  }

  // Upload profile image
  Future<AuthResult> uploadProfileImage(File imageFile) async {
    try {
      if (currentUser == null) {
        return AuthResult(success: false, message: 'No user signed in');
      }

      final ref = _storage.ref().child('profile_images/${currentUser!.uid}');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(currentUser!.uid).update({
        'profileImageUrl': downloadUrl,
      });

      return AuthResult(success: true, message: 'Profile image updated successfully');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to upload profile image');
    }
  }

  // Upload profile image from XFile (Web/Mobile friendly)
  Future<AuthResult> uploadProfileImageXFile(XFile xfile) async {
    try {
      if (currentUser == null) {
        return AuthResult(success: false, message: 'No user signed in');
      }

      final bytes = await xfile.readAsBytes();
      final ref = _storage.ref().child('profile_images/${currentUser!.uid}');
      final metadata = SettableMetadata(
        contentType: lookupMimeType(xfile.name) ?? 'application/octet-stream',
      );
      final snapshot = await ref.putData(bytes, metadata);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(currentUser!.uid).update({
        'profileImageUrl': downloadUrl,
      });

      return AuthResult(success: true, message: 'Profile image updated successfully');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to upload profile image');
    }
  }

  // Delete user account
  Future<AuthResult> deleteAccount(String password) async {
    try {
      if (currentUser == null) {
        return AuthResult(success: false, message: 'No user signed in');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );
      
      await currentUser!.reauthenticateWithCredential(credential);

      // Delete user data from Firestore
      await _firestore.collection('users').doc(currentUser!.uid).delete();

      // Delete profile image if exists
      try {
        await _storage.ref().child('profile_images/${currentUser!.uid}').delete();
      } catch (e) {
        // Profile image might not exist, continue with account deletion
      }

      // Delete user account
      await currentUser!.delete();
      
      return AuthResult(success: true, message: 'Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e));
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to delete account');
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    final userModel = await getUserModel();
    return userModel?.hasAdminRights ?? false;
  }

  // ===== Admin utilities =====
  // Real-time stream of users (with optional search and role filter applied client-side)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUsers({int limit = 1000}) {
    // No ordering to ensure we don't exclude docs missing specific fields
    return _firestore.collection('users').limit(limit).snapshots();
  }

  // Stream users filtered by exact email
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUsersByEmail(String email, {int limit = 100}) {
    return _firestore
        .collection('users')
        .where('emailLower', isEqualTo: email.toLowerCase())
        .limit(limit)
        .snapshots();
  }

  // Stream users filtered by exact UID (document id)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUsersByUid(String uid) {
    return _firestore
        .collection('users')
        .where(FieldPath.documentId, isEqualTo: uid)
        .limit(1)
        .snapshots();
  }

  // Update a user's role: only 'user' or 'admin'
  Future<AuthResult> updateUserRole({required String uid, required String role}) async {
    try {
      // Guard: only allow 'user' or 'admin'
      if (role != 'user' && role != 'admin') {
        return AuthResult(success: false, message: 'Invalid role. Allowed roles: user, admin');
      }
      await _firestore.collection('users').doc(uid).update({
        'role': role,
        // keep legacy isAdmin in sync for old checks
        'isAdmin': role == 'admin',
      });
      return AuthResult(success: true, message: 'Role updated to $role');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to update role');
    }
  }

  // Explicitly set legacy isAdmin flag
  Future<AuthResult> setAdmin({required String uid, required bool isAdmin}) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isAdmin': isAdmin,
        if (isAdmin) 'role': 'admin',
      });
      return AuthResult(success: true, message: 'Admin flag updated');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to update admin flag');
    }
  }

  // Activate/Deactivate user
  Future<AuthResult> setActive({required String uid, required bool isActive}) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isActive': isActive,
      });
      return AuthResult(success: true, message: isActive ? 'User activated' : 'User deactivated');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to update status');
    }
  }

  // Delete user data only (admin action) - does not delete auth user
  Future<AuthResult> deleteUserData({required String uid}) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      try {
        await _storage.ref().child('profile_images/$uid').delete();
      } catch (_) {}
      return AuthResult(success: true, message: 'User data deleted');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to delete user data');
    }
  }

  // Update last login time
  Future<void> _updateLastLoginTime(String uid) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      final snap = await docRef.get();
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>?;
        final updates = <String, dynamic>{
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
        };
        if (data == null || !data.containsKey('createdAt') || data['createdAt'] == null) {
          updates['createdAt'] = FieldValue.serverTimestamp();
        }
        // Backfill email/name if missing to make admin filtering reliable
        final user = _auth.currentUser;
        if (data == null || (data['email'] == null || (data['email'] as String).isEmpty)) {
          updates['email'] = user?.email;
        }
        if (data == null || (data['name'] == null || (data['name'] as String).isEmpty)) {
          updates['name'] = user?.displayName ?? 'User';
        }
        if (data == null || (data['emailLower'] == null || (data['emailLower'] as String).isEmpty)) {
          updates['emailLower'] = (user?.email ?? '').toLowerCase();
        }
        await docRef.update(updates);
      } else {
        final user = _auth.currentUser;
        await docRef.set({
          'email': user?.email,
          'emailLower': (user?.email ?? '').toLowerCase(),
          'name': user?.displayName ?? 'User',
          'role': 'user',
          'isAdmin': false,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'quizzesCompleted': 0,
          'totalScore': 0,
          'password': null,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error updating last login time: $e');
    }
  }

  // Record a quiz attempt and atomically update aggregate stats
  Future<AuthResult> recordQuizAttempt({
    required String quizId,
    required int score,
    required int maxScore,
    String? subject,
    String? difficulty,
    Duration? duration,
    Map<String, dynamic>? extra,
  }) async {
    try {
      if (currentUser == null) {
        return AuthResult(success: false, message: 'No user signed in');
      }

      final uid = currentUser!.uid;
      final userRef = _firestore.collection('users').doc(uid);
      final attemptsRef = userRef.collection('quizAttempts').doc();

      final now = FieldValue.serverTimestamp();

      final batch = _firestore.batch();

      // Attempt detail document (for history/analytics)
      final attemptData = <String, dynamic>{
        'uid': uid,
        'quizId': quizId,
        'score': score,
        'maxScore': maxScore,
        'percentage': maxScore > 0 ? (score / maxScore) : null,
        'subject': subject,
        'difficulty': difficulty,
        'durationMs': duration?.inMilliseconds,
        'createdAt': now,
        if (extra != null) ...extra,
      };
      batch.set(attemptsRef, attemptData, SetOptions(merge: true));

      // Aggregate fields on user doc
      batch.set(
        userRef,
        {
          'quizzesCompleted': FieldValue.increment(1),
          'totalScore': FieldValue.increment(score),
          'lastQuizAt': now,
          'lastQuizId': quizId,
          if (subject != null) 'lastSubject': subject,
          if (difficulty != null) 'lastDifficulty': difficulty,
          'lastScore': score,
          'lastMaxScore': maxScore,
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      
      // Track quiz completion activity
      try {
        final userModel = await getUserModel();
        if (userModel != null) {
          await ActivityService.trackQuizCompletion(
            userModel,
            subject ?? 'Quiz',
            score,
            quizId,
          );
          
          // Check if this is a high score (above 80% or above user's average)
          if (maxScore > 0 && (score / maxScore) >= 0.8) {
            await ActivityService.trackHighScore(
              userModel,
              score,
              subject ?? 'Quiz',
            );
          }
        }
      } catch (e) {
        print('Error tracking quiz activity: $e');
      }
      
      return AuthResult(success: true, message: 'Quiz attempt recorded');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to record attempt');
    }
  }

  // Optional: fetch recent quiz attempts for current user
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMyQuizAttempts({int limit = 20}) {
    if (currentUser == null) {
      // Return an empty stream if no user
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('quizAttempts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Mark user as inactive before signing out so dashboards reflect presence
      final user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'isActive': false,
            'lastActive': FieldValue.serverTimestamp(),
          });
        } catch (_) {
          // Ignore Firestore update errors during sign-out flow
        }
      }
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // ===== Presence helpers =====
  // Call this on app start/resume to ensure the user shows as Active
  Future<void> setPresenceActive() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      await docRef.set({
        'isActive': true,
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error setting presence active: $e');
    }
  }

  // Call this on app pause/background if you want to reflect inactivity (optional)
  Future<void> setPresenceInactive() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      await docRef.set({
        'isActive': false,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error setting presence inactive: $e');
    }
  }

  // Get user-friendly error messages
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        // Web often returns this generic message for wrong email/password
        return 'Invalid email or password.';
      case 'invalid-login-credentials':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      default:
        return e.message ?? 'An error occurred during authentication.';
    }
  }
}

// Auth result class for better error handling
class AuthResult {
  final bool success;
  final User? user;
  final String message;
  final bool requiresEmailVerification;

  AuthResult({
    required this.success,
    this.user,
    required this.message,
    this.requiresEmailVerification = false,
  });
}
