import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'role_selection_screen.dart';
import 'admin_home_screen.dart';
import 'member_home_screen.dart';
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

    if (session == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        (route) => false,
      );
    } else {
      try {
        final userId = session.user.id;
        final response = await supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .maybeSingle();

        if (response == null || response['role'] == null) {
          await supabase.auth.signOut();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => const RoleSelectionScreen()),
            (route) => false,
          );
          return;
        }

        final role = response['role'];
        final destination = role == 'admin'
            ? const AdminHomeScreen()
            : const MemberHomeScreen();

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => destination),
          (route) => false,
        );
      } catch (e) {
        await supabase.auth.signOut();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme to decide which logo to show
    final theme = Provider.of<ThemeNotifier>(context);
    final logoAsset =
        theme.isDarkMode ? 'assets/logo.png' : 'assets/logo_blue.png';

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              logoAsset, // Use the dynamic logo asset
              height: 120,
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
