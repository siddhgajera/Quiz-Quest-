import 'package:flutter/material.dart';
import 'Quiz_Categories_Screen.dart';
import 'User_Profile_Screen.dart';
import 'navigationdrawer.dart';
import 'home_content.dart';
import 'settings_screen.dart'; // ✅ Import the Settings screen

class MainBottomNavigationBar extends StatefulWidget {
  const MainBottomNavigationBar({super.key});

  @override
  _MainBottomNavigationBarState createState() =>
      _MainBottomNavigationBarState();
}

class _MainBottomNavigationBarState extends State<MainBottomNavigationBar> {
  int _currentIndex = 0;
  final GlobalKey<QuizCategoriesScreenState> _quizCategoriesKey = GlobalKey<QuizCategoriesScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeContent(),
      QuizCategoriesScreen(key: _quizCategoriesKey),
      UserProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Refresh Quiz Categories when switching to that tab
    if (index == 1) {
      _quizCategoriesKey.currentState?.refreshCategories();
    }

    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.isDrawerOpen) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Quiz Quest",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () {
              // ✅ Navigate to Settings page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: MainDrawer(onItemTapped: _onTabTapped),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onTabTapped,
        currentIndex: _currentIndex,
        backgroundColor: Colors.teal[900],
        selectedItemColor: Colors.cyan[300],
        unselectedItemColor: Colors.teal[300],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quizzes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
