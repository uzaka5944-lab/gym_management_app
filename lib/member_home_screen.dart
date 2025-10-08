// lib/member_home_screen.dart
import 'package:flutter/material.dart';
import 'member_profile_screen.dart'; // IMPORT THE NEW SCREEN

// TODO: Create these screens for the member's view
// import 'member_dashboard_screen.dart';
// import 'member_workout_plan_screen.dart';

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  int _selectedIndex = 0;

  // UPDATED: Replaced the profile screen placeholder with the actual screen
  static const List<Widget> _pages = <Widget>[
    // Placeholder for MemberDashboardScreen
    Center(
      child: Text(
        'Member Dashboard Screen',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    ),
    // Placeholder for MemberWorkoutPlanScreen
    Center(
      child: Text(
        'Member Workout Plan Screen',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    ),
    // The new profile screen with a logout button
    MemberProfileScreen(),
  ];

  static const List<String> _appBarTitles = [
    'Dashboard',
    'Workout Plan',
    'My Profile'
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
            icon: Icon(Icons.fitness_center_rounded),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
