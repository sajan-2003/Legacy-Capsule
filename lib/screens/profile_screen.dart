import 'package:flutter/material.dart';
import 'front_page.dart';
import 'security_settings_screen.dart';
import 'time_lock_screen.dart';
import 'update_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Function(bool) onThemeChanged;
  final ThemeMode currentThemeMode;

  const ProfileScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

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
          icon: Icon(Icons.arrow_back,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Profile",
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.dividerColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. TOP CONTAINER (Profile Info - Editable)
            Container(
              margin: const EdgeInsets.only(
                  left: 24, right: 24, top: 24, bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: isDark ? Border.all(color: theme.dividerColor) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UpdateProfileScreen(
                        currentName: "Sarah Johnson",
                        currentEmail: "sarah.johnson@email.com",
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.primary
                                            .withValues(alpha: 0.7)
                                      ]
                                    : [
                                        const Color(0xFF38BDF8),
                                        const Color(0xFF0284C7)
                                      ],
                              ),
                            ),
                            child: const Icon(Icons.person,
                                size: 35, color: Colors.white),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: theme.colorScheme.surface, width: 2),
                            ),
                            child: const Icon(Icons.edit,
                                size: 10, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sarah Johnson",
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontSize: 18),
                            ),
                            Text(
                              "sarah.johnson@email.com",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3)),
                    ],
                  ),
                ),
              ),
            ),

            // 2. LOWER SUB-CONTAINER (Authentication, Time-Lock, Logout)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: isDark ? Border.all(color: theme.dividerColor) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _buildListTile(
                      context: context,
                      icon: Icons.shield_outlined,
                      label: "Authentication",
                      color: theme.colorScheme.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SecuritySettingsScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 60, color: theme.dividerColor),
                    _buildListTile(
                      context: context,
                      icon: Icons.history_toggle_off_outlined,
                      label: "Time-Lock Settings",
                      color: const Color(0xFFB45309),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TimeLockScreen(
                              isSearching: false,
                              searchController: TextEditingController(),
                              onThemeChanged: onThemeChanged,
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 60, color: theme.dividerColor),
                    // Theme Switch ListTile
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.amber.withValues(alpha: 0.1)
                              : Colors.blueGrey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.wb_sunny_rounded
                              : Icons.nightlight_round,
                          color: isDark ? Colors.amber : Colors.blueGrey,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        "Dark Mode",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                          fontSize: 15,
                        ),
                      ),
                      trailing: Switch(
                        value: isDark,
                        activeTrackColor:
                            theme.colorScheme.primary.withValues(alpha: 0.5),
                        activeThumbColor: theme.colorScheme.primary,
                        onChanged: (val) => onThemeChanged(val),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                    ),
                    Divider(height: 1, indent: 60, color: theme.dividerColor),
                    _buildListTile(
                      context: context,
                      icon: Icons.logout_rounded,
                      label: "Logout",
                      color: const Color(0xFFDC2626),
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SplashScreen(
                              onThemeChanged: onThemeChanged,
                              currentThemeMode: currentThemeMode,
                            ),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // MORE TEXT
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "MORE",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // 3. SECOND MAIN CONTAINER (About Us, Support)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: isDark ? Border.all(color: theme.dividerColor) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  _buildListTile(
                    context: context,
                    icon: Icons.info_outline_rounded,
                    label: "About Us",
                    color: isDark
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                        : const Color(0xFF475569),
                    onTap: () {},
                  ),
                  Divider(height: 1, indent: 60, color: theme.dividerColor),
                  _buildListTile(
                    context: context,
                    icon: Icons.help_outline_rounded,
                    label: "Help & Support",
                    color: isDark
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                        : const Color(0xFF475569),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          fontSize: 15,
        ),
      ),
      trailing: Icon(Icons.chevron_right,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2), size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
