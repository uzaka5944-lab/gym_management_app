import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_page.dart';
import 'theme_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Reads the secure keys passed in from the --dart-define build command
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

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
          title: 'Luxury Gym',
          theme: themeNotifier.currentTheme,
          debugShowCheckedModeBanner: false,
          home: const SplashPage(),
        );
      },
    );
  }
}
