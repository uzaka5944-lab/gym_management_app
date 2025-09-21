import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_page.dart'; // This will show an error until we create it next
import 'theme.dart';

Future<void> main() async {
  // This ensures that all Flutter components are ready before running the app.
  WidgetsFlutterBinding.ensureInitialized();

  // IMPORTANT: Connect your app to your Supabase project.
  await Supabase.initialize(
    url: 'https://impfxrdzojtvhdzorjfi.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImltcGZ4cmR6b2p0dmhkem9yamZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzNTYyNTYsImV4cCI6MjA3MzkzMjI1Nn0.sp4fHw2vkGKtAdFX0_HpER0QFX5ECec7vcz63kxl3XQ',
  );
  runApp(const MyApp());
}

// A global helper to easily access the Supabase client anywhere in the app
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymPro Fitness',
      theme: appTheme, // Applying our new dark theme
      debugShowCheckedModeBanner: false,
      home: const SplashPage(), // The first screen to be shown
    );
  }
}
