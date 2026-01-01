import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final ThemeMode currentThemeMode;

  const LoginScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

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
  final String _mockUsername = 'admin';
  final String _mockPassword = 'admin123';
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
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          onThemeChanged: widget.onThemeChanged,
          currentThemeMode: widget.currentThemeMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [theme.colorScheme.surface, theme.scaffoldBackgroundColor]
              : [const Color(0xFFF0F9FF), Colors.white],
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
                      color: isDark ? theme.colorScheme.primary.withOpacity(0.1) : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  "Welcome Back",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 30),
                ),
                const SizedBox(height: 8),
                Text(
                  "Access your private diary",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 40),

                // Username Input
                Text(
                  "Username",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _usernameController,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: "Enter your username",
                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    filled: true,
                    fillColor: isDark ? theme.colorScheme.surface : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? theme.dividerColor : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? theme.dividerColor : const Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login Method Toggle
                Text(
                  "Login Method",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surface : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: isDark ? Border.all(color: theme.dividerColor) : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _loginMethod = 'password'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _loginMethod == 'password'
                                  ? (isDark ? theme.colorScheme.primary.withOpacity(0.2) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Password",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _loginMethod == 'password'
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface.withOpacity(0.5),
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
                              color: _loginMethod == 'pin'
                                  ? (isDark ? theme.colorScheme.primary.withOpacity(0.2) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "PIN",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _loginMethod == 'pin'
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface.withOpacity(0.5),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _loginMethod == 'password' ? _passwordController : _pinController,
                  obscureText: true,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: _loginMethod == 'pin' ? 24 : 16,
                    letterSpacing: _loginMethod == 'pin' ? 8 : 1,
                  ),
                  keyboardType: _loginMethod == 'pin' ? TextInputType.number : TextInputType.text,
                  maxLength: _loginMethod == 'pin' ? 4 : null,
                  textAlign: _loginMethod == 'pin' ? TextAlign.center : TextAlign.start,
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: _loginMethod == 'password' ? "••••••••" : "••••",
                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    filled: true,
                    fillColor: isDark ? theme.colorScheme.surface : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? theme.dividerColor : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? theme.dividerColor : const Color(0xFFE2E8F0)),
                    ),
                  ),
                ),

                // Error Message
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.red.withOpacity(0.1) : const Color(0xFFFEF2F2),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Login Button
                ElevatedButton(
                  onPressed: _handleLogin,
                  child: const Text(
                    "Log In",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 24),

                // OR Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.dividerColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "OR CONTINUE WITH",
                        style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.dividerColor)),
                  ],
                ),

                const SizedBox(height: 24),

                // Social Login Icons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialIcon(
                      icon: Icons.g_mobiledata,
                      color: isDark ? theme.colorScheme.surface : Colors.white,
                      iconColor: theme.colorScheme.onSurface,
                      borderColor: theme.dividerColor,
                    ),
                    const SizedBox(width: 20),
                    _buildSocialIcon(
                      icon: Icons.facebook,
                      color: const Color(0xFF1877F2),
                      iconColor: Colors.white,
                    ),
                    const SizedBox(width: 20),
                    _buildSocialIcon(
                      icon: Icons.apple,
                      color: isDark ? Colors.white : Colors.black,
                      iconColor: isDark ? Colors.black : Colors.white,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("New to Capsule? ", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SignupScreen(
                              onThemeChanged: widget.onThemeChanged,
                              currentThemeMode: widget.currentThemeMode,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        "Create account",
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon({
    required IconData icon,
    required Color color,
    required Color iconColor,
    Color? borderColor,
  }) {
    return InkWell(
      onTap: _navigateToHome,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Icon(icon, size: 32, color: iconColor),
      ),
    );
  }
}
