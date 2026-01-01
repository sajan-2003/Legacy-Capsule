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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Security Settings",
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("AUTHENTICATION"),
            _buildSettingCard([
              _buildSettingTile(
                icon: Icons.fingerprint,
                label: "Biometric Unlock",
                subtitle: "Use FaceID or Fingerprint to unlock",
                trailing: Switch(
                  value: _biometricsEnabled,
                  activeColor: const Color(0xFF0284C7),
                  onChanged: (val) => setState(() => _biometricsEnabled = val),
                ),
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.pin_outlined,
                label: "Change PIN",
                subtitle: "Update your 4-digit access code",
                onTap: () {},
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.password_outlined,
                label: "Change Password",
                subtitle: "Last changed 3 months ago",
                onTap: () {},
              ),
            ]),

            _buildSectionHeader("ADVANCED PROTECTION"),
            _buildSettingCard([
              _buildSettingTile(
                icon: Icons.vibration_outlined,
                label: "Two-Factor Auth",
                subtitle: "Verify login via email or SMS",
                trailing: Switch(
                  value: _twoFactorEnabled,
                  activeColor: const Color(0xFF0284C7),
                  onChanged: (val) => setState(() => _twoFactorEnabled = val),
                ),
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.visibility_off_outlined,
                label: "Stealth Mode",
                subtitle: "Hide app content in app switcher",
                trailing: Switch(
                  value: _stealthModeEnabled,
                  activeColor: const Color(0xFF0284C7),
                  onChanged: (val) => setState(() => _stealthModeEnabled = val),
                ),
              ),
            ]),

            _buildSectionHeader("DATA ENCRYPTION"),
            _buildSettingCard([
              _buildSettingTile(
                icon: Icons.key_outlined,
                label: "Master Key",
                subtitle: "View or backup your recovery key",
                onTap: () {},
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.delete_forever_outlined,
                label: "Self-Destruct Timer",
                subtitle: "Wipe data after 10 failed attempts",
                color: Colors.red,
                onTap: () {},
              ),
            ]),
            
            const SizedBox(height: 40),
            Center(
              child: Text(
                "App Version 1.0.4",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSettingTile({
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
          color: (color ?? const Color(0xFF0284C7)).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? const Color(0xFF0284C7), size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color ?? const Color(0xFF0F172A),
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
    );
  }
}
