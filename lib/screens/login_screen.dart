import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _authMethod = 'password'; 

  late AnimationController _entranceController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _floatingAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatingController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      setState(() => _isLoading = false);
      _navigateToHome();
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
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            if (!isDark)
              Positioned(
                top: -80,
                right: -40,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.03),
                  ),
                ),
              ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(flex: 2),
                      
                      Center(
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _floatingAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatingAnimation.value),
                                  child: child,
                                );
                              },
                              child: Hero(
                                tag: 'app_logo',
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary.withValues(alpha: 0.8),
                                        theme.colorScheme.primary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.auto_awesome, size: 32, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Hello! Great to see you.",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Step into your private sanctuary ✨",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(flex: 2),

                      _buildTextField(
                        controller: _usernameController,
                        label: "Username",
                        icon: Icons.alternate_email_rounded,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _authMethod == 'password'
                            ? _buildTextField(
                                key: const ValueKey('password_field'),
                                controller: _passwordController,
                                label: "Password",
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                theme: theme,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 18,
                                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              )
                            : _buildTextField(
                                key: const ValueKey('pin_field'),
                                controller: _pinController,
                                label: "4-Digit PIN",
                                icon: Icons.dialpad_rounded,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                maxLength: 4,
                                textAlign: TextAlign.start,
                                theme: theme,
                              ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 38,
                            width: 170, 
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: isDark ? theme.colorScheme.surface : Colors.grey[100],
                              borderRadius: BorderRadius.circular(19),
                            ),
                            child: Row(
                              children: [
                                _buildMethodTab("Password", 'password', theme),
                                _buildMethodTab("PIN", 'pin', theme),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary.withValues(alpha: 0.7),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                            ),
                            child: const Text("Forgot?"),
                          ),
                        ],
                      ),
                      const Spacer(flex: 1),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            backgroundColor: theme.colorScheme.primary,
                          ),
                          child: _isLoading 
                              ? const SizedBox(
                                  width: 20, 
                                  height: 20, 
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  "Enter Vault", 
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),

                      const Spacer(flex: 2),
                      
                      Row(
                        children: [
                          Expanded(child: Divider(color: theme.dividerColor.withValues(alpha: 0.1))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "QUICK ACCESS", 
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.3), 
                                fontSize: 9, 
                                fontWeight: FontWeight.w900, 
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: theme.dividerColor.withValues(alpha: 0.1))),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialCard(FontAwesomeIcons.google, const Color(0xFFDB4437), theme),
                          const SizedBox(width: 20),
                          _buildSocialCard(FontAwesomeIcons.apple, isDark ? Colors.white : Colors.black, theme),
                        ],
                      ),

                      const Spacer(flex: 2),

                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "New here? ", 
                              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (_) => SignupScreen(
                                    onThemeChanged: widget.onThemeChanged, 
                                    currentThemeMode: widget.currentThemeMode,
                                  ),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: theme.colorScheme.primary,
                              ),
                              child: const Text(
                                "Create Account", 
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTab(String label, String method, ThemeData theme) {
    bool isSelected = _authMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_authMethod != method) {
            FocusScope.of(context).unfocus();
            setState(() => _authMethod = method);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isSelected 
              ? (theme.brightness == Brightness.dark ? theme.colorScheme.primary : Colors.white) 
              : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 11, 
                color: isSelected 
                  ? (theme.brightness == Brightness.dark ? Colors.white : theme.colorScheme.primary) 
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    Key? key,
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
      key: key,
      controller: controller, 
      obscureText: obscureText, 
      keyboardType: keyboardType, 
      maxLength: maxLength, 
      textAlign: textAlign,
      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: theme.colorScheme.primary.withValues(alpha: 0.5)), 
        suffixIcon: suffix, 
        counterText: "", 
        filled: true,
        fillColor: isDark ? theme.colorScheme.surface.withValues(alpha: 0.5) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20), 
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20), 
          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20), 
          borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSocialCard(IconData icon, Color color, ThemeData theme) {
    bool isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleLogin, 
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 56, 
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : Colors.white, 
            shape: BoxShape.circle,
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: Center(child: FaIcon(icon, size: 22, color: color)),
        ),
      ),
    );
  }
}
