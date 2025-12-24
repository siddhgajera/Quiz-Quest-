import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_question_management_screen.dart';
import 'admin_navigation_drawer.dart';
import 'admin_settings_screen.dart';
import 'admin_profile_screen.dart';
import 'providers/admin_user_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/admin_stats_provider.dart';
import 'screens/admin_user_management_screen.dart';
import 'screens/admin_activity_dashboard.dart';

class AdminBottomNavigationBar extends StatefulWidget {
  final String adminName;

  const AdminBottomNavigationBar({super.key, required this.adminName});

  @override
  _AdminBottomNavigationBarState createState() =>
      _AdminBottomNavigationBarState();
}

class _AdminBottomNavigationBarState extends State<AdminBottomNavigationBar> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      // Dashboard wrapped with multiple providers for real-time data
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ActivityProvider()),
          ChangeNotifierProvider(create: (_) => AdminStatsProvider()),
        ],
        child: AdminDashboardScreen(
          adminName: widget.adminName,
          onTabChange: _onTabTapped,
        ),
      ),
      const AdminQuestionManagementScreen(),
      // Users management (admin only) wrapped with provider
      ChangeNotifierProvider(
        create: (_) => AdminUserProvider(),
        child: const AdminUserManagementScreen(),
      ),
      // Activity dashboard wrapped with ActivityProvider
      ChangeNotifierProvider(
        create: (_) => ActivityProvider(),
        child: const AdminActivityDashboard(),
      ),
      // Admin Profile
      AdminProfileScreen(adminName: widget.adminName),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.isDrawerOpen) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel - Quiz Quest"),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: AdminNavigationDrawer(
        onItemTapped: _onTabTapped,
        adminName: widget.adminName,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onTabTapped,
        currentIndex: _currentIndex,
        backgroundColor: Colors.blue[800],
        selectedItemColor: Colors.lightBlue[100],
        unselectedItemColor: Colors.blue[300],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Questions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
