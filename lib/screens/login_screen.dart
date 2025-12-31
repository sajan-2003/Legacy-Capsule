import 'package:flutter/material.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  String _loginMethod = 'password'; // 'password' or 'pin'
  String _errorMessage = '';

  // Mock credentials for demo
  final String _mockUsername = 'sarah';
  final String _mockPassword = 'legacy123';
  final String _mockPin = '1234';

  void _handleLogin() {
    setState(() {
      _errorMessage = '';
    });

    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _errorMessage = 'Please enter your username');
      return;
    }

    if (_loginMethod == 'password') {
      final password = _passwordController.text.trim();
      if (password.isEmpty) {
        setState(() => _errorMessage = 'Please enter your password');
        return;
      }

      if (username == _mockUsername && password == _mockPassword) {
        _navigateToHome();
      } else {
        setState(() => _errorMessage = 'Invalid username or password');
      }
    } else {
      final pin = _pinController.text;
      if (pin.length != 4) {
        setState(() => _errorMessage = 'Please enter a 4-digit PIN');
        return;
      }

      if (username == _mockUsername && pin == _mockPin) {
        _navigateToHome();
      } else {
        setState(() => _errorMessage = 'Invalid username or PIN');
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F9FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Lock Icon
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 32,
                      color: Color(0xFF0369A1),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  "Welcome Back",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Access your private diary",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 40),

                // Username Input
                const Text(
                  "Username",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: "Enter your username",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login Method Toggle
                const Text(
                  "Login Method",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _loginMethod = 'password'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _loginMethod == 'password' ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _loginMethod == 'password'
                                  ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                                  : [],
                            ),
                            child: Text(
                              "Password",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _loginMethod == 'password' ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _loginMethod = 'pin'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _loginMethod == 'pin' ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _loginMethod == 'pin'
                                  ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                                  : [],
                            ),
                            child: Text(
                              "PIN",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _loginMethod == 'pin' ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Password or PIN Input
                Text(
                  _loginMethod == 'password' ? "Password" : "4-Digit PIN",
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _loginMethod == 'password' ? _passwordController : _pinController,
                  obscureText: true,
                  keyboardType: _loginMethod == 'pin' ? TextInputType.number : TextInputType.text,
                  maxLength: _loginMethod == 'pin' ? 4 : null,
                  textAlign: _loginMethod == 'pin' ? TextAlign.center : TextAlign.start,
                  style: _loginMethod == 'pin'
                      ? const TextStyle(fontSize: 24, letterSpacing: 8)
                      : null,
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: _loginMethod == 'password' ? "••••••••" : "••••",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),

                // Error Message
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFFECACA)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 14),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Demo Credentials Helper
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Demo credentials:",
                        style: TextStyle(color: Color(0xFF0369A1), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text("Username: $_mockUsername", style: const TextStyle(color: Color(0xFF0369A1), fontSize: 13)),
                      Text("Password: $_mockPassword", style: const TextStyle(color: Color(0xFF0369A1), fontSize: 13)),
                      Text("PIN: $_mockPin", style: const TextStyle(color: Color(0xFF0369A1), fontSize: 13)),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Login Button
                ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Log In",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Create new account",
                    style: TextStyle(color: Color(0xFF0369A1), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
