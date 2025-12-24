import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'login.dart';
import 'home_screen.dart';
import 'admin_home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<bool>(
            future: AuthService().isAdmin(),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // Navigate based on admin status
              if (adminSnapshot.data == true) {
                return FutureBuilder<String>(
                  future: _getAdminName(),
                  builder: (context, nameSnapshot) {
                    String adminName = nameSnapshot.data ?? 'Admin';
                    return AdminHomeScreen(adminName: adminName);
                  },
                );
              } else {
                return const HomeScreen();
              }
            },
          );
        }
        
        // User not logged in
        return const LoginScreen();
      },
    );
  }
  
  Future<String> _getAdminName() async {
    final userModel = await AuthService().getUserModel();
    return userModel?.name ?? 'Admin';
  }
}
