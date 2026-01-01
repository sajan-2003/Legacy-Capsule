import 'package:flutter/material.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

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
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                
                // Title
                const Text(
                  "Create Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Choose how you want to secure your capsule",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 32),

                // Username & Email
                _buildLabel("Username"),
                _buildTextField(_usernameController, "Enter your username"),
                const SizedBox(height: 16),
                _buildLabel("Email"),
                _buildTextField(_emailController, "Enter your email", keyboardType: TextInputType.emailAddress),
                
                const SizedBox(height: 24),

                // Method Toggle
                _buildLabel("Security Method"),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildToggleItem("Password", 'password'),
                      _buildToggleItem("PIN", 'pin'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dynamic Inputs based on Method
                if (_authMethod == 'password') ...[
                  _buildLabel("Password"),
                  _buildTextField(_passwordController, "••••••••", obscureText: true),
                  const SizedBox(height: 16),
                  _buildLabel("Confirm Password"),
                  _buildTextField(_confirmController, "••••••••", obscureText: true),
                ] else ...[
                  _buildLabel("4-Digit PIN"),
                  _buildTextField(
                    _pinController, 
                    "••••", 
                    obscureText: true, 
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel("Confirm PIN"),
                  _buildTextField(
                    _confirmController, 
                    "••••", 
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

                const SizedBox(height: 32),

                // Signup Button
                ElevatedButton(
                  onPressed: _handleSignup,
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
                    "Create Account",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? ", style: TextStyle(color: Color(0xFF64748B))),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Log In",
                        style: TextStyle(color: Color(0xFF0369A1), fontWeight: FontWeight.bold),
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

  Widget _buildToggleItem(String label, String method) {
    bool isSelected = _authMethod == method;
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
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String hint, 
    {bool obscureText = false, 
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    TextAlign textAlign = TextAlign.start}
  ) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      textAlign: textAlign,
      decoration: InputDecoration(
        counterText: "",
        hintText: hint,
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
    );
  }
}
