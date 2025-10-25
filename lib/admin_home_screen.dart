// lib/admin_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ADDED: To allow exiting the app
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

  // ADDED: Function to show the exit confirmation dialog
  Future<bool> _showExitPopup() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text('Exit App',
                style: Theme.of(context).textTheme.headlineSmall),
            content: Text('Are you sure you want to exit the app?',
                style: Theme.of(context).textTheme.bodyLarge),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // UPDATED: Wrapped the Scaffold with PopScope
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        _showExitPopup();
      },
      child: Scaffold(
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
      ),
    );
  }
}
