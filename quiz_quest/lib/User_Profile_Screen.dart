import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'auth_service.dart';
import 'edit_profile_screen.dart';
import 'login.dart'; // Import login screen for logout
import 'services/activity_service.dart';
import 'models/user_model.dart';
import 'widgets/profile_stats_cards.dart';
import 'widgets/quiz_performance_widget.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _appAuth = AuthService();

  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? error;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        // User not logged in, redirect to login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
        return;
      }

      // Try to load from Firestore first
      bool firestoreSuccess = false;
      try {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get(const GetOptions(source: Source.serverAndCache));

        if (doc.exists && doc.data() != null) {
          final firestoreData = doc.data() as Map<String, dynamic>;
          setState(() {
            userData = firestoreData;
            isLoading = false;
            error = null;
          });
          firestoreSuccess = true;
          print('Loaded Firestore data with name: ${firestoreData['name']}');
          
          // Track profile view activity (only if Firestore works)
          _trackProfileView();
        }
      } catch (firestoreError) {
        print('Firestore load failed: $firestoreError');
        // Continue to fallback method
      }

      // If Firestore failed, create minimal user document and try to initialize it
      if (!firestoreSuccess) {
        print('Firestore failed, creating minimal user document');
        try {
          // Create a minimal user document in Firestore
          await _firestore.collection('users').doc(currentUser.uid).set({
            'uid': currentUser.uid,
            'name': currentUser.displayName ?? 'Quiz Player',
            'email': currentUser.email ?? '',
            'isAdmin': false,
            'totalScore': 0,
            'quizzesCompleted': 0,
            'highestScore': 0,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'lastActive': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
          print('Created minimal user document, reloading...');
          // Try to load again after creating the document
          _loadUserData();
          return;
        } catch (createError) {
          print('Failed to create user document: $createError');
        }
        
        // Final fallback with minimal data
        Map<String, dynamic> fallbackUserData = {
          'uid': currentUser.uid,
          'name': currentUser.displayName ?? 'Quiz Player',
          'email': currentUser.email ?? '',
          'isAdmin': false,
          'totalScore': 0,
          'quizzesCompleted': 0,
          'highestScore': 0,
          'joinDate': currentUser.metadata.creationTime ?? DateTime.now(),
          'lastActive': DateTime.now(),
          'profilePicture': currentUser.photoURL ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(currentUser.displayName ?? 'User')}&background=random',
          'favoriteCategories': [],
          'categoryScores': {},
          'achievements': ['Welcome to Quiz Quest!'],
          'badges': ['New Player'],
          'rank': 0,
          'isActive': true,
          'isEmailVerified': currentUser.emailVerified,
        };

        setState(() {
          userData = fallbackUserData;
          isLoading = false;
          error = null;
        });
        print('Loaded user data with name: ${fallbackUserData['name']}');

        // Try to create/update Firestore document in background (don't wait)
        _tryCreateFirestoreDocument(currentUser, fallbackUserData);
      }
    } catch (e) {
      print('Critical error loading user data: $e');
      setState(() {
        error = 'Unable to load profile. Please check your connection and try again.';
        isLoading = false;
      });
    }
  }

  // Background method to try creating Firestore document
  Future<void> _tryCreateFirestoreDocument(User currentUser, Map<String, dynamic> userData) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(userData, SetOptions(merge: true));
      print('Successfully created/updated Firestore document');
    } catch (e) {
      print('Failed to create Firestore document: $e');
      // Don't show error to user, this is background operation
    }
  }

  Future<void> _refreshProfile() async {
    print('Profile: Manual refresh triggered');
    setState(() {
      isLoading = true;
      error = null;
    });
    await _loadUserData();
  }


  Future<void> _changePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;

      setState(() => _uploading = true);

      // Use web-friendly upload for all platforms; for mobile File API also exists
      final res = await _appAuth.uploadProfileImageXFile(picked);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.success ? Colors.green : Colors.red,
        ),
      );

      if (res.success) {
        await _refreshProfile();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change photo: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _trackProfileView() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && userData != null) {
        final user = UserModel(
          uid: currentUser.uid,
          name: userData!['name'] ?? 'Unknown User',
          email: userData!['email'] ?? '',
          isAdmin: userData!['isAdmin'] ?? false,
          profileImageUrl: userData!['profilePicture'],
          createdAt: userData!['joinDate']?.toDate() ?? DateTime.now(),
          isEmailVerified: currentUser.emailVerified,
        );
        await ActivityService.trackProfileUpdate(user);
      }
    } catch (e) {
      // Silently handle activity tracking errors
      print('Error tracking profile view: $e');
    }
  }

  // Removed logout popup from profile screen. Logout is now available in Settings.

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Unable to load profile'),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (userData == null) {
      return const Scaffold(
        body: Center(
          child: Text('No user data available'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.teal[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white70),
            onPressed: () async {
              // Get fresh user data before editing
              try {
                final currentUser = _auth.currentUser;
                if (currentUser == null) return;
                
                final doc = await _firestore
                    .collection('users')
                    .doc(currentUser.uid)
                    .get();
                
                final freshUserData = doc.exists 
                    ? doc.data() as Map<String, dynamic>
                    : userData ?? {};
                
                print('Opening EditProfileScreen with fresh data: name="${freshUserData['name']}"');
                
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(user: freshUserData),
                  ),
                );
                
                if (result == true) {
                  print('Profile was updated, refreshing...');
                  _refreshProfile(); // Refresh if profile was updated
                  
                  // Also show a confirmation message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  print('Profile edit cancelled or failed');
                }
              } catch (e) {
                print('Error getting fresh user data: $e');
                // Fallback to existing data
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(user: userData!),
                  ),
                );
                if (result == true) {
                  _refreshProfile();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header with real-time name updates
              Container(
                width: double.infinity,
                color: Colors.teal[700],
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _firestore
                      .collection('users')
                      .doc(_auth.currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    // Use real-time data if available, fallback to cached data
                    final realTimeData = snapshot.hasData && snapshot.data!.exists 
                        ? snapshot.data!.data() as Map<String, dynamic>
                        : userData;
                    
                    final displayName = realTimeData?['name'] ?? userData?['name'] ?? 'Unknown User';
                    final displayEmail = realTimeData?['email'] ?? userData?['email'] ?? '';
                    final isAdmin = realTimeData?['isAdmin'] ?? userData?['isAdmin'] ?? false;
                    
                    // Debug logging
                    if (snapshot.hasData && snapshot.data!.exists) {
                      print('Profile StreamBuilder received real-time data: name="${realTimeData?['name']}"');
                    } else {
                      print('Profile StreamBuilder using cached data: name="${userData?['name']}"');
                    }
                    
                    return Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.teal[400],
                          child: Text(
                            displayName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          displayEmail,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        if (isAdmin == true)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ADMINISTRATOR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              
              // Real-time Statistics Cards - Shows live quiz data
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: ProfileStatsCards(),
              ),

              const SizedBox(height: 24),

              // Quiz-wise Performance - Shows subject-specific stats
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: QuizPerformanceWidget(),
              ),

              const SizedBox(height: 24),

              // Achievement Badges section
              if (userData!['badges'] != null && (userData!['badges'] as List).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achievement Badges',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[700],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 50,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: (userData!['badges'] as List).length,
                          separatorBuilder: (context, index) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final badge = (userData!['badges'] as List)[index];
                            return Chip(
                              label: Text(badge.toString()),
                              avatar: const Icon(Icons.star, color: Colors.white, size: 20),
                              backgroundColor: Colors.teal[600],
                              labelStyle: const TextStyle(color: Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              // Account Information - Real-time data
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<DocumentSnapshot>(
                      stream: _firestore
                          .collection('users')
                          .doc(_auth.currentUser!.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          print('Account info stream error: ${snapshot.error}');
                          // Use local userData as fallback
                          final accountData = userData!;
                          return _buildAccountInfoCard(accountData, hasError: true);
                        }
                        
                        final data = snapshot.data?.data() as Map<String, dynamic>?;
                        final accountData = data ?? userData!;
                        
                        return _buildAccountInfoCard(accountData);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildAccountInfoCard(Map<String, dynamic> accountData, {bool hasError = false}) {
    return Column(
      children: [
        if (hasError)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[800], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Account info offline - showing cached data',
                    style: TextStyle(color: Colors.orange[800], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.calendar_today, color: Colors.teal[600]),
                title: const Text('Member Since'),
                subtitle: Text(_formatDate(accountData['joinDate'] ?? accountData['createdAt'])),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.access_time, color: Colors.teal[600]),
                title: const Text('Last Active'),
                subtitle: Text(_formatDate(accountData['lastActive'])),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  accountData['isActive'] == true ? Icons.check_circle : Icons.cancel,
                  color: accountData['isActive'] == true ? Colors.green : Colors.red,
                ),
                title: const Text('Account Status'),
                subtitle: Text(accountData['isActive'] == true ? 'Active' : 'Inactive'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  accountData['isAdmin'] == true ? Icons.admin_panel_settings : Icons.person,
                  color: accountData['isAdmin'] == true ? Colors.blue : Colors.teal,
                ),
                title: const Text('Account Type'),
                subtitle: Text(accountData['isAdmin'] == true ? 'Administrator' : 'Regular User'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.email, color: Colors.teal[600]),
                title: const Text('Email'),
                subtitle: Text(accountData['email'] ?? 'Not provided'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.verified_user, color: Colors.teal[600]),
                title: const Text('Email Verified'),
                subtitle: Text(_auth.currentUser?.emailVerified == true ? 'Verified' : 'Not Verified'),
                trailing: _auth.currentUser?.emailVerified != true && !hasError
                    ? TextButton(
                        onPressed: () async {
                          try {
                            await _auth.currentUser?.sendEmailVerification();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Verification email sent!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Verify'),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }


  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Unknown';
      }

      Duration difference = DateTime.now().difference(date);

      if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() != 1 ? 's' : ''} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
