import 'package:flutter/material.dart';
import 'login.dart';
import 'settings_screen.dart'; // Import the Settings screen
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainDrawer extends StatelessWidget {
  final Function(int) onItemTapped; // callback from parent

  const MainDrawer({super.key, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Container(
          color: Colors.teal[50],
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.teal[600],
                  image: const DecorationImage(
                    image: AssetImage('assets/map_texture.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: _UserHeader(),
              ),

              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () => onItemTapped(0),
              ),
              ListTile(
                leading: const Icon(Icons.quiz),
                title: const Text('Quizzes'),
                onTap: () => onItemTapped(1),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () => onItemTapped(2),
              ),

              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  // Navigate to Settings page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
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

class _UserHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Fallback static header if no user is signed in
    if (user == null) {
      const displayName = 'Guest';
      const displayEmail = 'guest@example.com';
      final initial = displayName.isNotEmpty
          ? displayName[0].toUpperCase()
          : (displayEmail.isNotEmpty ? displayEmail[0].toUpperCase() : 'U');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.teal[400],
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            displayName,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const Text(
            displayEmail,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = (data?['name'] as String?)?.trim();
        final email = (data?['email'] as String?)?.trim();
        final displayName = (name != null && name.isNotEmpty)
            ? name
            : (user.displayName ?? 'User');
        final displayEmail = (email != null && email.isNotEmpty)
            ? email
            : (user.email ?? '');
        final initial = displayName.isNotEmpty
            ? displayName[0].toUpperCase()
            : (displayEmail.isNotEmpty ? displayEmail[0].toUpperCase() : 'U');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.teal[400],
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayName,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              displayEmail,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        );
      },
    );
  }
}
