// lib/admin_home_screen.dart

import 'package:flutter/material.dart';
import 'admin_dashboard_summary_screen.dart';
import 'admin_member_management_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_workout_management_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  // List of the main pages for the admin
  static const List<Widget> _pages = <Widget>[
    AdminDashboardSummaryScreen(),
    AdminMemberManagementScreen(),
    AdminWorkoutManagementScreen(),
    AdminSettingsScreen(),
  ];

  // List of titles for the AppBar
  static const List<String> _appBarTitles = [
    'Dashboard',
    'Manage Members',
    'Manage Workouts',
    'Settings'
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]),
        automaticallyImplyLeading: false, // This removes the back arrow
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Members',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_rounded),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}