// lib/splash_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'admin_home_screen.dart';
import 'main.dart';
import 'theme_notifier.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final session = supabase.auth.currentSession;
    final user = session?.user;

    if (user == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => const LoginScreen(role: 'admin')),
        (route) => false,
      );
    } else {
      try {
        final response = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();

        final role = response['role'];

        if (role == 'admin') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
            (route) => false,
          );
        } else {
          await supabase.auth.signOut();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => const LoginScreen(role: 'admin')),
            (route) => false,
          );
        }
      } catch (e) {
        await supabase.auth.signOut();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => const LoginScreen(role: 'admin')),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final bool isCurrentlyDarkMode =
        themeNotifier.currentTheme.brightness == Brightness.dark;
    final logoAsset =
        isCurrentlyDarkMode ? 'assets/logo.png' : 'assets/logo_blue.png';

    return Scaffold(
      body: Stack(
        children: [
          Center(
            // MODIFIED: Wrapped the Image in a Column to add text below it.
            child: Column(
              mainAxisSize: MainAxisSize.min, // Keeps the content centered
              children: [
                Image.asset(
                  logoAsset,
                  height: 120,
                ),
                const SizedBox(height: 24), // Spacing between logo and text
                Text(
                  'Luxury Gym',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
