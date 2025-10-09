// lib/admin_home_screen.dart

import 'package:flutter/material.dart';
import 'admin_dashboard_summary_screen.dart';
import 'admin_member_management_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_analytics_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  // FIXED: Move the list of pages inside the State class
  // and remove 'static const'.
  final List<Widget> _pages = <Widget>[
    const AdminDashboardSummaryScreen(),
    const AdminMemberManagementScreen(),
    const AdminAnalyticsScreen(),
    const AdminSettingsScreen(),
  ];

  static const List<String> _appBarTitles = [
    'Dashboard',
    'Manage Members',
    'Analytics',
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
        children: _pages, // Use the instance variable here
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
