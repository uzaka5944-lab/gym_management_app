// lib/role_selection_screen.dart

import 'package:flutter/material.dart';
// REMOVED: import 'package:supabase_flutter/supabase_flutter.dart'; // This import is no longer needed here

import 'login_screen.dart';
import 'theme.dart';
import 'main.dart'; // This provides the 'supabase' client instance
import 'admin_signup_screen.dart'; // Import the new admin signup screen

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  // Function to check if an admin user exists by querying the profiles table
  Future<bool> _isAdminRegistered() async {
    try {
      // Access the supabase client provided by main.dart
      final response = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'admin')
          .limit(1)
          .maybeSingle(); // Use maybeSingle to handle cases with no rows
      return response != null; // If a response exists, an admin is registered
    } catch (e) {
      debugPrint('Error checking for admin: $e');
      // In case of an error (e.g., network issue, table not found),
      // it's safer to assume no admin is registered for the first-time setup flow.
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.fitness_center,
                  size: 80,
                  color: primaryColor,
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to GymPro',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Please select your role to continue',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: () async {
                    final isAdmin = await _isAdminRegistered();
                    if (isAdmin) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(role: 'admin'),
                        ),
                      );
                    } else {
                      // If no admin is registered, navigate to the AdminSignUpScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminSignUpScreen(),
                        ),
                      );
                    }
                  },
                  child: const Text('Admin'),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(role: 'member'),
                      ),
                    );
                  },
                  child: const Text('Member'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}