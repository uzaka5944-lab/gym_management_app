// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_page.dart';
import 'theme_notifier.dart';
import 'package:flutter/foundation.dart'; // Import kReleaseMode

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- REVERTED TO ENVIRONMENT VARIABLES ---
  // Reads the secure keys passed in from the build command using --dart-define
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  // --- END REVERT ---

  // Check for keys in release mode if using environment variables
  if (kReleaseMode && (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty)) {
    // You should replace this with more robust error handling or logging
    // For example, you might want to show an error screen or log to a monitoring service.
    print('*****************************************************************');
    print('ERROR: Supabase secrets are not configured for release build!');
    print(
      'Pass them using --dart-define SUPABASE_URL=YOUR_URL --dart-define SUPABASE_ANON_KEY=YOUR_KEY',
    );
    print('*****************************************************************');
    // Optionally, throw an exception to halt the app in release if keys are missing
    throw Exception('Supabase secrets are not configured for release build.');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(
    ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Luxury Gym',
          theme: themeNotifier.currentTheme,
          debugShowCheckedModeBanner: false,
          home: const SplashPage(),
        );
      },
    );
  }
}
