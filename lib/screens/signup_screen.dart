import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final ThemeMode currentThemeMode;

  const SignupScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final AuthService _authService = AuthService();

  String _authMethod = 'password'; 
  String _errorMessage = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleSignup() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    String password = '';

    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Please choose a username';
        _isLoading = false;
      });
      return;
    }

    if (_authMethod == 'password') {
      if (_passwordController.text.length < 6) {
        setState(() {
          _errorMessage = 'Password must be at least 6 characters';
          _isLoading = false;
        });
        return;
      }
      if (_confirmController.text != _passwordController.text) {
        setState(() {
          _errorMessage = 'Passwords do not match';
          _isLoading = false;
        });
        return;
      }
      password = _passwordController.text;
    } else {
      if (_pinController.text.length != 4) {
        setState(() {
          _errorMessage = 'PIN must be 4 digits';
          _isLoading = false;
        });
        return;
      }
      if (_confirmController.text != _pinController.text) {
        setState(() {
          _errorMessage = 'PINs do not match';
          _isLoading = false;
        });
        return;
      }
      password = "pin_${_pinController.text}";
    }

    // Convert username to email format
    final emailFormat = username.contains('@') ? username : "$username@legacycapsule.com";

    try {
      final success = await _authService.signUpWithEmail(emailFormat, password, username);
      if (success && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              onThemeChanged: widget.onThemeChanged,
              currentThemeMode: widget.currentThemeMode,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('Exception', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [theme.colorScheme.surface, theme.scaffoldBackgroundColor]
              : [const Color(0xFFF8FAFC), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Create Account",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Join Legacy Capsule with a unique username",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? theme.colorScheme.surface : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildMethodTab("Password", 'password', theme),
                        _buildMethodTab("PIN", 'pin', theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildTextField(
                    controller: _usernameController,
                    label: "Choose Username",
                    icon: Icons.person_outline_rounded,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),

                  if (_authMethod == 'password') ...[
                    _buildTextField(
                      controller: _passwordController,
                      label: "Password (Min 6 chars)",
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      theme: theme,
                      suffix: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _confirmController,
                      label: "Confirm Password",
                      icon: Icons.lock_reset_rounded,
                      obscureText: _obscurePassword,
                      theme: theme,
                    ),
                  ] else ...[
                    _buildTextField(
                      controller: _pinController,
                      label: "4-Digit Secure PIN",
                      icon: Icons.dialpad_rounded,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _confirmController,
                      label: "Confirm PIN",
                      icon: Icons.dialpad_rounded,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      theme: theme,
                    ),
                  ],

                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildErrorBox(_errorMessage),
                  ],

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Create Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account? ", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text("Log In", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodTab(String label, String method, ThemeData theme) {
    bool isSelected = _authMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _authMethod = method;
          _confirmController.clear();
          _errorMessage = '';
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? (theme.brightness == Brightness.dark ? theme.colorScheme.primary.withValues(alpha: 0.2) : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    TextAlign textAlign = TextAlign.start,
    Widget? suffix,
  }) {
    bool isDark = theme.brightness == Brightness.dark;
    return TextField(
      controller: controller, obscureText: obscureText, keyboardType: keyboardType, maxLength: maxLength, textAlign: textAlign,
      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, size: 20), suffixIcon: suffix, counterText: "", filled: true,
        fillColor: isDark ? theme.colorScheme.surface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withValues(alpha: 0.1))),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
