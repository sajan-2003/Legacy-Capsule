import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final ThemeMode currentThemeMode;

  const SplashScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              onThemeChanged: widget.onThemeChanged,
              currentThemeMode: widget.currentThemeMode,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const imageUrl = "https://images.unsplash.com/photo-1514185542902-bbfeac2fa9a4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080";

    return Scaffold(
      body: Stack(
        children: [
          // Background Image with Caching
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: const Color(0xFF0C4A6E)),
              errorWidget: (context, url, error) => Container(color: const Color(0xFF0C4A6E)),
              fadeOutDuration: const Duration(milliseconds: 500),
              fadeInDuration: const Duration(milliseconds: 700),
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0C4A6E).withValues(alpha: 0.4),
                    const Color(0xFF075985).withValues(alpha: 0.5),
                    const Color(0xFF082F49).withValues(alpha: 0.6),
                    const Color(0xFF082F49).withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Legacy Capsule",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "A private space for your life's memories",
                  style: TextStyle(
                    color: Color(0xFFE0F2FE),
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 64),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Loading...",
                  style: TextStyle(
                    color: Color(0xFFE0F2FE),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
