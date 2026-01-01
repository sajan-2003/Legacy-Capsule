import 'package:flutter/material.dart';
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  String _authMethod = 'password'; // 'password' or 'pin'
  String _errorMessage = '';

  void _handleSignup() {
    setState(() {
      _errorMessage = '';
    });

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    
    if (username.isEmpty || email.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    if (_authMethod == 'password') {
      if (_passwordController.text.isEmpty || _confirmController.text.isEmpty) {
        setState(() => _errorMessage = 'Please set your password');
        return;
      }
      if (_passwordController.text != _confirmController.text) {
        setState(() => _errorMessage = 'Passwords do not match');
        return;
      }
    } else {
      if (_pinController.text.length != 4 || _confirmController.text.length != 4) {
        setState(() => _errorMessage = 'PIN must be 4 digits');
        return;
      }
      if (_pinController.text != _confirmController.text) {
        setState(() => _errorMessage = 'PINs do not match');
        return;
      }
    }

    // Mock signup: just navigate to home
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                
                // Title
                Text(
                  "Create Account",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 30),
                ),
                const SizedBox(height: 8),
                Text(
                  "Choose how you want to secure your capsule",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 32),

                // Username & Email
                _buildLabel("Username", theme),
                _buildTextField(_usernameController, "Enter your username", theme),
                const SizedBox(height: 16),
                _buildLabel("Email", theme),
                _buildTextField(_emailController, "Enter your email", theme, keyboardType: TextInputType.emailAddress),
                
                const SizedBox(height: 24),

                // Method Toggle
                _buildLabel("Security Method", theme),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surface : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: isDark ? Border.all(color: theme.dividerColor) : null,
                  ),
                  child: Row(
                    children: [
                      _buildToggleItem("Password", 'password', theme),
                      _buildToggleItem("PIN", 'pin', theme),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dynamic Inputs based on Method
                if (_authMethod == 'password') ...[
                  _buildLabel("Password", theme),
                  _buildTextField(_passwordController, "••••••••", theme, obscureText: true),
                  const SizedBox(height: 16),
                  _buildLabel("Confirm Password", theme),
                  _buildTextField(_confirmController, "••••••••", theme, obscureText: true),
                ] else ...[
                  _buildLabel("4-Digit PIN", theme),
                  _buildTextField(
                    _pinController, 
                    "••••", 
                    theme,
                    obscureText: true, 
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel("Confirm PIN", theme),
                  _buildTextField(
                    _confirmController, 
                    "••••", 
                    theme,
                    obscureText: true, 
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                  ),
                ],

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

                // Signup Button
                ElevatedButton(
                  onPressed: _handleSignup,
                  child: const Text(
                    "Create Account",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "Log In",
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

  Widget _buildToggleItem(String label, String method, ThemeData theme) {
    bool isSelected = _authMethod == method;
    bool isDark = theme.brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _authMethod = method;
          _confirmController.clear();
          _errorMessage = '';
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected 
              ? (isDark ? theme.colorScheme.primary.withOpacity(0.2) : Colors.white)
              : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String hint, 
    ThemeData theme,
    {bool obscureText = false, 
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    TextAlign textAlign = TextAlign.start}
  ) {
    bool isDark = theme.brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      textAlign: textAlign,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        counterText: "",
        hintText: hint,
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
    );
  }
}
