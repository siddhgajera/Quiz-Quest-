import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/activity_service.dart';
import 'admin_change_password_screen.dart';
import 'admin_edit_profile_screen.dart';
import 'login.dart';
import 'auth_wrapper.dart';

class AdminProfileScreen extends StatefulWidget {
  final String adminName;

  const AdminProfileScreen({super.key, required this.adminName});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ActivityService _activityService = ActivityService();

  Map<String, dynamic>? adminData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            adminData = doc.data();
            isLoading = false;
          });
        } else {
          setState(() {
            error = 'Admin profile not found';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

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
              const Text('Unable to load admin profile'),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAdminData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Admin Profile Header
              _buildProfileHeader(),
              const SizedBox(height: 24),
              
              // Admin Information Cards
              _buildAdminInfoSection(),
              const SizedBox(height: 24),
              
              // Admin Statistics
              _buildAdminStatsSection(),
              const SizedBox(height: 24),
              
              // Admin Actions
              _buildAdminActionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Use real-time data if available, fallback to cached data
        final realTimeData = snapshot.hasData && snapshot.data!.exists 
            ? snapshot.data!.data() as Map<String, dynamic>
            : adminData;
        
        final displayName = realTimeData?['name'] ?? widget.adminName ?? 'Admin User';
        final displayEmail = realTimeData?['email'] ?? adminData?['email'] ?? 'No email available';
        
        // Debug logging
        if (snapshot.hasData && snapshot.data!.exists) {
          print('Admin Profile Header: StreamBuilder received real-time data: name="$displayName"');
        } else {
          print('Admin Profile Header: StreamBuilder using cached data: name="$displayName"');
        }
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 60,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Administrator',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                displayEmail,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            // Use real-time data if available, fallback to cached data
            final realTimeData = snapshot.hasData && snapshot.data!.exists 
                ? snapshot.data!.data() as Map<String, dynamic>
                : adminData;
            
            final displayName = realTimeData?['name'] ?? widget.adminName ?? 'Admin User';
            final displayEmail = realTimeData?['email'] ?? 'Not available';
            
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.person, 'Name', displayName),
                    const Divider(),
                    _buildInfoRow(Icons.email, 'Email', displayEmail),
                    const Divider(),
                    _buildInfoRow(Icons.verified_user, 'Role', 'Administrator'),
                    const Divider(),
                    _buildInfoRow(Icons.calendar_today, 'Member Since', 
                      _formatDate(realTimeData?['createdAt'] ?? adminData?['createdAt'])),
                    const Divider(),
                    _buildInfoRow(Icons.access_time, 'Last Login', 
                      _formatDate(realTimeData?['lastLoginAt'] ?? adminData?['lastLoginAt'])),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdminStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('activities').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final activities = snapshot.data!.docs;
            final totalActivities = activities.length;
            final todayActivities = activities.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp?;
              if (timestamp == null) return false;
              final activityDate = timestamp.toDate();
              final today = DateTime.now();
              return activityDate.year == today.year &&
                     activityDate.month == today.month &&
                     activityDate.day == today.day;
            }).length;

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Activities',
                    totalActivities.toString(),
                    Icons.timeline,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Today\'s Activities',
                    todayActivities.toString(),
                    Icons.today,
                    Colors.green,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox();
            }

            final users = snapshot.data!.docs;
            final totalUsers = users.length;
            final activeUsers = users.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['isActive'] == true;
            }).length;

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Users',
                    totalUsers.toString(),
                    Icons.people,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Active Users',
                    activeUsers.toString(),
                    Icons.people_outline,
                    Colors.orange,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdminActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue[600]),
                title: const Text('Edit Profile'),
                subtitle: const Text('Update your admin information'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminEditProfileScreen(),
                    ),
                  );
                  
                  // Show success confirmation if changes were made
                  if (result == true) {
                    print('Admin Profile: Edit completed successfully - StreamBuilder will auto-update');
                    
                    // Show success confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Admin profile updated successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    print('Admin Profile: Edit was cancelled or failed');
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.security, color: Colors.green[600]),
                title: const Text('Change Password'),
                subtitle: const Text('Update your admin password'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminChangePasswordScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.blue[600]),
                title: const Text('Logout'),
                subtitle: const Text('Sign out of admin panel'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: const Text('Logout'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _logout();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Not available';
    
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Invalid date';
      }
      
      // Format: DD/MM/YYYY HH:MM AM/PM
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');
      
      return '${date.day}/${date.month}/${date.year} $hour:$minute $period';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
