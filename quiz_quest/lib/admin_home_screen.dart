import 'package:flutter/material.dart';
import 'admin_bottom_navigation_bar.dart';

class AdminHomeScreen extends StatelessWidget {
  final String adminName;

  const AdminHomeScreen({super.key, required this.adminName});

  @override
  Widget build(BuildContext context) {
    return AdminBottomNavigationBar(adminName: adminName);
  }
}
