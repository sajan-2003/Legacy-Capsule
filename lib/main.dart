import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/front_page.dart';
import 'themes/app_theme.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Local Database (Hive)
    await Hive.initFlutter();
    await Hive.openBox('memories');
    await Hive.openBox('community_cache');
    await Hive.openBox('user_profile');
    await Hive.openBox('future_plans');
    await Hive.openBox('calendar_colors');
    await Hive.openBox('achievements'); // New box for achievements

    final storageService = StorageService();
    
    // Clear previous test data to ensure a clean start
    // await storageService.clearAllData();

    // Initialize Demo Data
    await storageService.initializeDemoData();
    
  } catch (e) {
    debugPrint("Local Database Error: $e");
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
