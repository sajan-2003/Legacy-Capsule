import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../services/storage_service.dart';

class UpdateProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;

  const UpdateProfileScreen({
    super.key,
    required this.currentName,
    required this.currentEmail,
  });

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  
  final StorageService _storageService = StorageService();
  DateTime? _selectedDate;
  int? _age;
  String _gender = 'Rather not say';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _loadProfile();
  }

  void _loadProfile() {
    final profile = _storageService.getUserProfile();
    if (profile != null) {
      setState(() {
        _nameController.text = profile.displayName ?? widget.currentName;
        _emailController.text = profile.email;
        if (profile.dateOfBirth != null) {
          _selectedDate = profile.dateOfBirth;
          _calculateAge(profile.dateOfBirth!);
        }
      });
    }
  }

  void _calculateAge(DateTime birthDate) {
    int age = DateTime.now().year - birthDate.year;
    if (DateTime.now().month < birthDate.month ||
        (DateTime.now().month == birthDate.month &&
            DateTime.now().day < birthDate.day)) {
      age--;
    }
    _age = age;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onSurface: theme.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _calculateAge(picked);
      });
    }
  }

  Future<void> _handleUpdate() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Email are required')));
      return;
    }

    final profile = UserProfile(
      uid: 'demo_user',
      email: _emailController.text.trim(),
      displayName: _nameController.text.trim(),
      dateOfBirth: _selectedDate,
      createdAt: DateTime.now(),
    );

    await _storageService.saveUserProfile(profile);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Create Your Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
                  ),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(Icons.auto_awesome, size: 150, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 110, height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.surface,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 4),
                          ),
                          child: Icon(Icons.person_rounded, size: 60, color: theme.colorScheme.primary.withOpacity(0.5)),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary,
                            radius: 18,
                            child: const Icon(Icons.add_a_photo_rounded, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  _buildSectionTitle("PERSONAL INFO", theme),
                  _buildInputField(controller: _nameController, label: "Full Name", icon: Icons.person_outline, theme: theme),
                  const SizedBox(height: 20),
                  _buildInputField(controller: _emailController, label: "Email Address", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, theme: theme),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => _selectDate(context),
                          child: _buildStaticField(
                            label: "Birthday", 
                            value: _selectedDate == null ? "Select Date" : DateFormat('MMM d, yyyy').format(_selectedDate!), 
                            icon: Icons.cake_outlined, 
                            theme: theme
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStaticField(label: "Age", value: _age?.toString() ?? "--", icon: Icons.bolt, theme: theme, centered: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildSectionTitle("PREFERENCES", theme),
                  _buildGenderSelector(theme),
                  const SizedBox(height: 20),
                  _buildInputField(controller: _locationController, label: "Location", icon: Icons.location_on_outlined, theme: theme),
                  const SizedBox(height: 20),
                  _buildInputField(controller: _bioController, label: "Short Bio", icon: Icons.edit_note_rounded, maxLines: 3, theme: theme),
                  
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                      shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                    ),
                    child: const Text("Complete Profile ✨", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 1.5)),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon, required ThemeData theme, TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary.withOpacity(0.6)),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
      ),
    );
  }

  Widget _buildStaticField({required String label, required String value, required IconData icon, required ThemeData theme, bool centered = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary.withOpacity(0.6)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: theme.dividerColor.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: ['Male', 'Female', 'Other'].map((g) {
          bool isSel = _gender == g;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _gender = g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: isSel ? theme.colorScheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                child: Text(g, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.5))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
