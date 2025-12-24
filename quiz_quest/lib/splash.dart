import 'dart:async';
import 'package:flutter/material.dart';
import 'login.dart';
import 'home_screen.dart';
import 'admin_home_screen.dart';
import 'auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Show splash for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Check if user is already logged in
    if (_authService.currentUser != null) {
      // User is logged in, check if admin
      bool isAdmin = await _authService.isAdmin();
      
      if (isAdmin) {
        // Get admin name
        final userModel = await _authService.getUserModel();
        String adminName = userModel?.name ?? 'Admin';
        
        // Navigate to admin home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminHomeScreen(adminName: adminName),
          ),
        );
      } else {
        // Navigate to user home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      // User not logged in, go to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'images/logo1.jpg',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
