import 'package:flutter/material.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometricsEnabled = true;
  bool _twoFactorEnabled = false;
  bool _stealthModeEnabled = false;
  bool _hideSensitivePreviews = true;
  bool _privateMode = false;
  String _lockTimeout = '5 minutes';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Privacy & Security",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.dividerColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("ENHANCED SECURITY", theme),
            _buildSettingCard([
              _buildSettingTile(
                theme: theme,
                icon: Icons.fingerprint,
                label: "Biometric Unlock",
                subtitle: "Face ID / Fingerprint with PIN fallback",
                trailing: Switch(
                  value: _biometricsEnabled,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (val) => setState(() => _biometricsEnabled = val),
                ),
              ),
              _buildDivider(theme),
              _buildSettingTile(
                theme: theme,
                icon: Icons.vibration_outlined,
                label: "Two-Factor Auth",
                subtitle: "Manage 2FA setup and codes",
                trailing: Switch(
                  value: _twoFactorEnabled,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (val) => setState(() => _twoFactorEnabled = val),
                ),
              ),
              _buildDivider(theme),
              _buildSettingTile(
                theme: theme,
                icon: Icons.timer_outlined,
                label: "App Lock Timeout",
                subtitle: "Auto-lock after $_lockTimeout",
                onTap: _showTimeoutPicker,
              ),
              _buildDivider(theme),
              _buildSettingTile(
                theme: theme,
                icon: Icons.enhanced_encryption_outlined,
                label: "Data Encryption",
                subtitle: "All data is end-to-end encrypted",
                trailing: Icon(Icons.check_circle, color: Colors.green, size: 20),
              ),
            ], theme),

            _buildSectionHeader("PRIVACY & PERMISSIONS", theme),
            _buildSettingCard([
              _buildSettingTile(
                theme: theme,
                icon: Icons.visibility_off_outlined,
                label: "Private Mode",
                subtitle: "Hide content across the whole app",
                trailing: Switch(
                  value: _privateMode,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (val) => setState(() => _privateMode = val),
                ),
              ),
              _buildDivider(theme),
              _buildSettingTile(
                theme: theme,
                icon: Icons.blur_on_outlined,
                label: "Hide Previews",
                subtitle: "Blur sensitive items in list views",
                trailing: Switch(
                  value: _hideSensitivePreviews,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (val) => setState(() => _hideSensitivePreviews = val),
                ),
              ),
              _buildDivider(theme),
              _buildSettingTile(
                theme: theme,
                icon: Icons.settings_applications_outlined,
                label: "App Permissions",
                subtitle: "Camera, Photos, Notifications",
                onTap: () {},
              ),
            ], theme),

            _buildSectionHeader("DATA MANAGEMENT", theme),
            _buildSettingCard([
              _buildSettingTile(
                theme: theme,
                icon: Icons.cloud_upload_outlined,
                label: "Backup & Restore",
                subtitle: "Secure cloud or local storage",
                onTap: () {},
              ),
              _buildDivider(theme),
              _buildSettingTile(
                theme: theme,
                icon: Icons.password_outlined,
                label: "Change Password",
                subtitle: "Update your login credentials",
                onTap: () {},
              ),
            ], theme),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Tip: Enabling Biometric Unlock keeps your capsule private even if your phone is unlocked.",
                        style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            Center(
              child: Text(
                "Legacy Capsule v1.0.5 • Privacy First",
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 12),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showTimeoutPicker() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Auto-Lock Timeout", style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            _buildTimeoutOption('Immediately'),
            _buildTimeoutOption('1 minute'),
            _buildTimeoutOption('5 minutes'),
            _buildTimeoutOption('15 minutes'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeoutOption(String value) {
    final theme = Theme.of(context);
    bool isSelected = _lockTimeout == value;
    return ListTile(
      title: Text(value, style: TextStyle(color: theme.colorScheme.onSurface)),
      trailing: isSelected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
      onTap: () {
        setState(() => _lockTimeout = value);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: theme.dividerColor) : Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSettingTile({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? theme.colorScheme.primary, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color ?? theme.colorScheme.onSurface,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.2), size: 20),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: theme.dividerColor),
    );
  }
}
