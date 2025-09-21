import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Imports the package to read .env
import 'splash_page.dart';
import 'theme.dart';

Future<void> main() async {
  // Loads the variables from your .env file
  await dotenv.load(fileName: ".env");

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // Reads the secure keys from the environment
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MyApp());
}

// The rest of the file stays the same
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymPro Fitness',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
    );
  }
}
