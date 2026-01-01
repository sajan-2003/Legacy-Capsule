import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/memory.dart';
import '../services/storage_service.dart';

class AddMemoryScreen extends StatefulWidget {
  final Function(Memory) onSave;

  const AddMemoryScreen({super.key, required this.onSave});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  MemoryType _selectedType = MemoryType.text;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = StorageService();

  bool _isTimeLocked = false;
  bool _shareToCommunity = false;
  DateTime? _unlockDate;
  String _lockType = 'date'; 
  final TextEditingController _ageController = TextEditingController();
  
  File? _selectedFile;
  String? _selectedFileName;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    try {
      if (_selectedType == MemoryType.photo) {
        final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() {
            _selectedFile = File(image.path);
            _selectedFileName = image.name;
          });
        }
      } else if (_selectedType == MemoryType.video) {
        final XFile? video = await _imagePicker.pickVideo(source: ImageSource.gallery);
        if (video != null) {
          setState(() {
            _selectedFile = File(video.path);
            _selectedFileName = video.name;
          });
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: _selectedType == MemoryType.audio ? FileType.audio : FileType.any,
        );

        if (result != null) {
          setState(() {
            _selectedFile = File(result.files.single.path!);
            _selectedFileName = result.files.single.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  void _handleSave() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a title")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final newMemory = Memory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        title: title,
        preview: content.isNotEmpty 
            ? (content.length > 100 ? '${content.substring(0, 100)}...' : content)
            : (_selectedFileName ?? "File attachment"),
        type: _selectedType,
        content: content,
        imageUrl: _selectedFile?.path,
        isLocked: _isTimeLocked,
      );

      // 1. Always save to Local Journal (No size limit)
      widget.onSave(newMemory);

      // 2. If shared, send to Firebase (50MB limit check)
      if (_shareToCommunity) {
        await _storageService.shareToCommunity(newMemory, _selectedFile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Shared to community!")),
          );
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text("New Memory", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
      ),
      body: _isUploading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Memory Type Selection
                      _buildSectionTitle("Memory Type", theme),
                      Row(
                        children: [
                          _buildTypeButton(MemoryType.text, Icons.description_outlined, "Text", theme),
                          const SizedBox(width: 12),
                          _buildTypeButton(MemoryType.photo, Icons.image_outlined, "Photo", theme),
                          const SizedBox(width: 12),
                          _buildTypeButton(MemoryType.video, Icons.videocam_outlined, "Video", theme),
                          const SizedBox(width: 12),
                          _buildTypeButton(MemoryType.audio, Icons.mic_none_outlined, "Audio", theme),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Title & Content
                      _buildSectionTitle("Title", theme),
                      _buildTextField(_titleController, "Give your memory a title...", theme),
                      const SizedBox(height: 24),

                      if (_selectedType != MemoryType.text) ...[
                        _buildSectionTitle("Attach ${_selectedType.name.capitalize()}", theme),
                        _buildFilePicker(theme, isDark),
                        const SizedBox(height: 24),
                      ],

                      _buildSectionTitle(_selectedType == MemoryType.text ? "Your Memory" : "Description", theme),
                      _buildTextField(_contentController, "Write about this moment...", theme, maxLines: 5),
                      const SizedBox(height: 32),

                      // SHARING & LOCKING OPTIONS
                      _buildOptionTile(
                        title: "Share to Community",
                        subtitle: "Make this visible to others (Max 50MB)",
                        icon: Icons.public,
                        value: _shareToCommunity,
                        onChanged: (val) => setState(() => _shareToCommunity = val),
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildOptionTile(
                        title: "Time-Lock Memory",
                        subtitle: "Seal this until a future date",
                        icon: Icons.lock_clock,
                        value: _isTimeLocked,
                        onChanged: (val) => setState(() => _isTimeLocked = val),
                        theme: theme,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
              _buildSaveButton(theme),
            ],
          ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
    );
  }

  Widget _buildOptionTile({required String title, required String subtitle, required IconData icon, required bool value, required Function(bool) onChanged, required ThemeData theme, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: value ? theme.colorScheme.primary.withValues(alpha: 0.4) : theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ]),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildFilePicker(ThemeData theme, bool isDark) {
    return InkWell(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            if (_selectedFile == null) ...[
              Icon(Icons.cloud_upload_outlined, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text("Tap to select a ${_selectedType.name} file", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ] else ...[
              const Icon(Icons.check_circle, size: 32, color: Colors.green),
              const SizedBox(height: 12),
              Text(_selectedFileName ?? "File selected", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.dividerColor)), color: theme.colorScheme.surface),
      child: ElevatedButton(
        onPressed: _handleSave,
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
        child: const Text("Create Memory", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildTypeButton(MemoryType type, IconData icon, String label, ThemeData theme) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _selectedType = type; _selectedFile = null; }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor, width: 2),
          ),
          child: Column(children: [
            Icon(icon, size: 20, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ]),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, ThemeData theme, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? theme.colorScheme.surface : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}
