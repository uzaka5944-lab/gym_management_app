import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_page.dart';
import 'theme.dart';
import 'light_theme.dart';
import 'theme_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Reads secure keys from build environment variables.
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // This check ensures the app will fail loudly if keys are missing.
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
        'Supabase secrets are not configured. Pass them using --dart-define in your build command.');
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
      builder: (context, theme, _) => MaterialApp(
        title: 'GymPro Fitness',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: const SplashPage(),
      ),
    );
  }
}
