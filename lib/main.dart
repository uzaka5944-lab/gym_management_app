// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_page.dart';
import 'theme_notifier.dart';

// Import the new secrets file
import 'supabase_secrets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // For release builds, read the keys from the --dart-define command.
  // For debug builds, use the keys from the git-ignored secrets file.
  String supabaseUrl = const String.fromEnvironment('SUPABASE_URL',
      defaultValue: kDebugMode ? supabaseUrlDev : '');
  String supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue: kDebugMode ? supabaseAnonKeyDev : '');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
        'Supabase secrets are not configured. Pass them using --dart-define for release builds.');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

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
          title: 'Luxury Gym', // Changed title to match your app name
          theme: themeNotifier.currentTheme,
          debugShowCheckedModeBanner: false,
          home: const SplashPage(),
        );
      },
    );
  }
}
