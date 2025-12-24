import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'splash.dart';
import 'auth_wrapper.dart';
import 'auth_service.dart';

void main() async {
  // ✅ Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // If user is already signed in (cold start), mark presence active
  final auth = AuthService();
  if (auth.currentUser != null) {
    await auth.setPresenceActive();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightPrimary = Colors.teal.shade400; // Modern teal for buttons
    final lightOnPrimary = Colors.white;

    return MaterialApp(
      title: 'Quiz Quest',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.teal, // Updated to teal theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightPrimary,
            foregroundColor: lightOnPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.teal.shade700,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.teal.shade700,
            side: BorderSide(color: Colors.teal.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: lightPrimary,
          foregroundColor: lightOnPrimary,
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
