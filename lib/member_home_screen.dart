// lib/member_home_screen.dart
import 'package:flutter/material.dart';

class MemberHomeScreen extends StatelessWidget {
  const MemberHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Dashboard'),
        automaticallyImplyLeading: false, // Removes the back arrow
      ),
      body: const Center(
        child: Text('Welcome, Member! Your dashboard is coming soon.'),
      ),
    );
  }
}