// lib/admin_home_screen.dart
import 'package:flutter/material.dart';
import 'admin_dashboard_summary_screen.dart';
import 'admin_member_management_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_analytics_screen.dart'; // IMPORT THE NEW SCREEN

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  // UPDATED: Replaced the workout screen with the new analytics screen
  static const List<Widget> _pages = <Widget>[
    AdminDashboardSummaryScreen(),
    AdminMemberManagementScreen(),
    AdminAnalyticsScreen(), // The new analytics screen is now the third tab
    AdminSettingsScreen(),
  ];

  // UPDATED: Changed the title for the third tab
  static const List<String> _appBarTitles = [
    'Dashboard',
    'Manage Members',
    'Analytics', // New title
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
        automaticallyImplyLeading: false,
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
          // UPDATED: Changed the icon and label for the new screen
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Analytics',
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