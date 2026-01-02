import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import 'update_profile_screen.dart';

class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({super.key});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  final StorageService _storageService = StorageService();
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _userProfile = _storageService.getUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final name = _userProfile?.displayName ?? "Aisha Khan";
    final email = _userProfile?.email ?? "aisha.legacy@gmail.com";
    final bio = _userProfile?.bio ?? "Exploring the intersection of technology and human emotion. Capturing life's most precious moments, one capsule at a time. ✨";
    
    // Consistent demo hacker photo
    const hackerPhoto = "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=400&q=80";
    final profilePic = _userProfile?.photoUrl ?? hackerPhoto;
    const demoBg = "https://images.unsplash.com/photo-1557683316-973673baf926?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080";
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.primary,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdateProfileScreen(
                            currentName: name,
                            currentEmail: email,
                          ),
                        ),
                      );
                      if (result == true) _loadProfile();
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(demoBg, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.1),
                          theme.colorScheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                        ),
                        child: Hero(
                          tag: 'profile_avatar',
                          child: CircleAvatar(
                            radius: 65,
                            backgroundColor: Colors.white,
                            backgroundImage: NetworkImage(profilePic),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 28, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: -0.5,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 4))],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          email,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -35, 0),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
                ],
              ),
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("MY LEGACY BIO", theme),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? theme.colorScheme.surface : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Text(
                      bio,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildSectionTitle("VITAL DETAILS", theme),
                  _buildDetailRow([
                    _buildFancyCard("Birthday", _userProfile?.dateOfBirth != null ? DateFormat('MMM d, yyyy').format(_userProfile!.dateOfBirth!) : "Dec 14, 1998", Icons.cake_rounded, Colors.pink, theme),
                    _buildFancyCard("Age", _calculateAge(_userProfile?.dateOfBirth) == "--" ? "25" : _calculateAge(_userProfile?.dateOfBirth), Icons.bolt_rounded, Colors.amber, theme),
                  ]),
                  const SizedBox(height: 16),
                  _buildDetailRow([
                    _buildFancyCard("Base", "London, UK", Icons.location_on_rounded, Colors.cyan, theme),
                    _buildFancyCard("Gender", "Female", Icons.face_rounded, Colors.deepPurpleAccent, theme),
                  ]),
                  const SizedBox(height: 40),

                  _buildSectionTitle("ACHIEVEMENTS", theme),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBadge("Journalist", "12", Icons.auto_stories, theme),
                        _buildStatBadge("Time Traveler", "3", Icons.lock_clock, theme),
                        _buildStatBadge("Connector", "48", Icons.people, theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return "--";
    int age = DateTime.now().year - birthDate.year;
    if (DateTime.now().month < birthDate.month ||
        (DateTime.now().month == birthDate.month &&
            DateTime.now().day < birthDate.day)) {
      age--;
    }
    return age.toString();
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 20),
      child: Text(
        title, 
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: theme.colorScheme.primary.withValues(alpha: 0.8), letterSpacing: 2)
      ),
    );
  }

  Widget _buildDetailRow(List<Widget> children) {
    return Row(children: children.expand((w) => [Expanded(child: w), const SizedBox(width: 16)]).toList()..removeLast());
  }

  Widget _buildFancyCard(String label, String value, IconData icon, Color accentColor, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(height: 16),
          Text(label, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle)),
            Icon(icon, color: theme.colorScheme.primary, size: 24),
          ],
        ),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
      ],
    );
  }
}
