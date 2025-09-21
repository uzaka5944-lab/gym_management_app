import 'package:flutter/material.dart';
import 'login_screen.dart'; // This will error until we create it next
import 'theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(role: 'admin'),
                      ),
                    );
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
