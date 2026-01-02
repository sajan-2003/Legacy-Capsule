import 'package:flutter/foundation.dart';

class AuthService {
  // Mocked login: Always succeeds
  Future<bool> signInWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true; 
  }

  // Mocked signup: Always succeeds
  Future<bool> signUpWithEmail(String email, String password, String name) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // Social Login Placeholders (No longer require Firebase)
  Future<void> signInWithGoogle() async {}
  Future<void> signInWithGitHub() async {}

  Future<void> signOut() async {
    debugPrint("User signed out locally");
  }
}
