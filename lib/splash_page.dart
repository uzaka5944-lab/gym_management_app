import 'package:flutter/material.dart';
import 'role_selection_screen.dart';
import 'admin_home_screen.dart';
import 'member_home_screen.dart';
import 'main.dart';
import 'theme.dart';

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
    await Future.delayed(const Duration(seconds: 1));

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
            .single();

        final role = response['role'];

        if (role == 'admin') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MemberHomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        await supabase.auth.signOut();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, color: primaryColor, size: 60),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
