import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/front_page.dart';
import 'theme.dart';

void main() async {
  // Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Initialize Local Database (Hive)
    await Hive.initFlutter();
    await Hive.openBox('memories');
    // Create another box specifically for community data/cache
    await Hive.openBox('community_cache');

    // 2. Initialize Cloud Database (Firebase)
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Setup Warning: $e");
    // We continue so the app still opens even if one service fails
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Legacy Capsule',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: SplashScreen(
        onThemeChanged: _toggleTheme,
        currentThemeMode: _themeMode,
      ),
    );
  }
}
