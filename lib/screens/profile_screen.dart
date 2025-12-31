import 'package:flutter/material.dart';
import 'front_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final List<Map<String, dynamic>> settingsItems = const [
    {
      'icon': Icons.shield_outlined,
      'label': 'Security Settings',
      'description': 'Password, biometrics, encryption',
      'color': Color(0xFF0284C7),
      'bgColor': Color(0xFFE0F2FE),
    },
    {
      'icon': Icons.history_toggle_off_outlined,
      'label': 'Time-Lock Settings',
      'description': 'Set future unlock dates for memories',
      'color': Color(0xFFB45309),
      'bgColor': Color(0xFFFEF3C7),
    },
    {
      'icon': Icons.people_outline,
      'label': 'Trusted Contacts',
      'description': 'Emergency access and legacy planning',
      'color': Color(0xFF7C3AED),
      'bgColor': Color(0xFFF3E8FF),
    },
    {
      'icon': Icons.description_outlined,
      'label': 'Privacy Policy',
      'description': 'How we protect your data',
      'color': Color(0xFF475569),
      'bgColor': Color(0xFFF1F5F9),
    }
  ];

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
          "Profile",
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Info
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Sarah Johnson",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Text(
                    "sarah.johnson@email.com",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Member since Dec 2024",
                      style: TextStyle(color: Color(0xFF0369A1), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // Settings List
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: settingsItems.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final item = settingsItems[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: item['bgColor'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item['icon'], color: item['color']),
                      ),
                      title: Text(
                        item['label'],
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      ),
                      subtitle: Text(
                        item['description'],
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                      onTap: () {},
                    );
                  },
                ),
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text("Log Out"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
