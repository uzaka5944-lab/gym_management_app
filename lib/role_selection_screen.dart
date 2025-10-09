import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'main.dart';
import 'admin_signup_screen.dart';
import 'theme_notifier.dart';

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
    // Get the current theme to decide which logo to show
    final theme = Provider.of<ThemeNotifier>(context);
    final logoAsset =
        theme.isDarkMode ? 'assets/logo.png' : 'assets/logo_blue.png';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  logoAsset, // Use the dynamic logo asset
                  height: 160,
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
                          builder: (context) =>
                              const LoginScreen(role: 'admin'),
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
