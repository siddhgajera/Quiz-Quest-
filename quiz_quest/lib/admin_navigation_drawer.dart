import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_settings_screen.dart';
import 'login.dart';

class AdminNavigationDrawer extends StatelessWidget {
  final Function(int) onItemTapped;
  final String adminName;

  AdminNavigationDrawer({
    super.key,
    required this.onItemTapped,
    required this.adminName,
  });

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Container(
          color: Colors.blue[50],
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.blue[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _auth.currentUser != null 
                      ? _firestore
                          .collection('users')
                          .doc(_auth.currentUser!.uid)
                          .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    // Use real-time data if available, fallback to passed adminName
                    final displayName = snapshot.hasData && snapshot.data!.exists 
                        ? (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? adminName
                        : adminName;
                    
                    // Debug logging
                    if (snapshot.hasData && snapshot.data!.exists) {
                      print('Admin Drawer: StreamBuilder received real-time data: name="$displayName"');
                    } else {
                      print('Admin Drawer: StreamBuilder using fallback data: name="$displayName"');
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: 35,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Administrator',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    );
                  },
                ),
              ),

              ListTile(
                leading: const Icon(Icons.dashboard, color: Colors.blue),
                title: const Text('Dashboard'),
                onTap: () => onItemTapped(0),
              ),
              ListTile(
                leading: const Icon(Icons.quiz, color: Colors.blue),
                title: const Text('Manage Questions'),
                onTap: () => onItemTapped(1),
              ),
              ListTile(
                leading: const Icon(Icons.people, color: Colors.blue),
                title: const Text('Manage Users'),
                onTap: () => onItemTapped(2),
              ),
              ListTile(
                leading: const Icon(Icons.timeline, color: Colors.blue),
                title: const Text('Activity'),
                onTap: () => onItemTapped(3),
              ),
              ListTile(
                leading: const Icon(Icons.account_circle, color: Colors.blue),
                title: const Text('Profile'),
                onTap: () => onItemTapped(4),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.settings, color: Colors.blue),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.blue),
                title: const Text('Logout'),
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
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: const Text('Logout'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    (route) => false,
                              );
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
      ),
    );
  }
}
