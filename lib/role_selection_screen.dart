// lib/role_selection_screen.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main.dart'; 
import 'admin_signup_screen.dart'; 

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<bool> _isAdminRegistered() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'admin')
          .limit(1)
          .maybeSingle(); 
      return response != null; 
    } catch (e) {
      debugPrint('Error checking for admin: $e');
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
                // Displaying your logo, clean and slightly larger.
                Image.asset(
                  'assets/logo.png',
                  height: 160, // Increased height for a bigger logo
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to Luxury Gym',
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
                    if (!context.mounted) return;
                    if (isAdmin) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(role: 'admin'),
                        ),
                      );
                    } else {
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