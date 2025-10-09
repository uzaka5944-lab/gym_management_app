import 'package:flutter/material.dart';
import 'member_profile_screen.dart';
import 'member_workout_screen.dart'; // Import the new screen

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  int _selectedIndex = 0;

  // The list of pages for the bottom navigation bar
  static const List<Widget> _pages = <Widget>[
    // Placeholder for MemberDashboardScreen (we can build this next)
    Center(
      child: Text('Member Dashboard Screen'),
    ),
    // The new, live workout screen with the sync button
    MemberWorkoutScreen(),
    // The profile screen with the theme toggle and logout button
    MemberProfileScreen(),
  ];

  // The titles for the app bar corresponding to each page
  static const List<String> _appBarTitles = [
    'Dashboard',
    'Exercise Library', // Updated title
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
