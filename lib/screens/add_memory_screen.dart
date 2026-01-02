import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/memory.dart';
import '../services/storage_service.dart';

class AddMemoryScreen extends StatefulWidget {
  final Function(Memory) onSave;
  final Memory? initialMemory;

  const AddMemoryScreen({super.key, required this.onSave, this.initialMemory});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  late MemoryType _selectedType;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = StorageService();

  bool _isTimeLocked = false;
  bool _shareToCommunity = false;

  List<File> _selectedFiles = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialMemory?.type ?? MemoryType.text;
    _titleController =
        TextEditingController(text: widget.initialMemory?.title ?? "");
    _contentController =
        TextEditingController(text: widget.initialMemory?.content ?? "");
    if (widget.initialMemory != null &&
        widget.initialMemory!.imageUrls.isNotEmpty) {
      _selectedFiles =
          widget.initialMemory!.imageUrls.map((path) => File(path)).toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      if (_selectedType == MemoryType.photo) {
        final List<XFile> images = await _imagePicker.pickMultiImage(
          limit: 5,
        );
        if (images.isNotEmpty) {
          setState(() {
            _selectedFiles =
                images.take(5).map((image) => File(image.path)).toList();
          });
        }
      } else if (_selectedType == MemoryType.video) {
        final XFile? video =
            await _imagePicker.pickVideo(source: ImageSource.gallery);
        if (video != null) {
          setState(() {
            _selectedFiles = [File(video.path)];
          });
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type:
              _selectedType == MemoryType.audio ? FileType.audio : FileType.any,
          allowMultiple: false,
        );

        if (result != null) {
          setState(() {
            _selectedFiles = [File(result.files.single.path!)];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }
  }

  void _handleSave() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please enter a title")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final newMemory = Memory(
        id: widget.initialMemory?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        title: title,
        preview: content.isNotEmpty
            ? (content.length > 100
                ? '${content.substring(0, 100)}...'
                : content)
            : (_selectedFiles.isNotEmpty
                ? "${_selectedFiles.length} files attached"
                : "Text entry"),
        type: _selectedType,
        content: content,
        imageUrls: _selectedFiles.map((f) => f.path).toList(),
        isLocked: _isTimeLocked,
      );

      widget.onSave(newMemory);

      if (_shareToCommunity) {
        await _storageService.shareToCommunity(
            newMemory, _selectedFiles.isNotEmpty ? _selectedFiles.first : null);
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
          SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.redAccent),
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
        title: Text("New Memory",
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
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
                        _buildSectionTitle("Memory Type", theme),
                        Row(
                          children: [
                            _buildTypeButton(MemoryType.text,
                                Icons.description_outlined, "Text", theme),
                            const SizedBox(width: 12),
                            _buildTypeButton(MemoryType.photo,
                                Icons.image_outlined, "Photo", theme),
                            const SizedBox(width: 12),
                            _buildTypeButton(MemoryType.video,
                                Icons.videocam_outlined, "Video", theme),
                            const SizedBox(width: 12),
                            _buildTypeButton(MemoryType.audio,
                                Icons.mic_none_outlined, "Audio", theme),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle("Title", theme),
                        _buildTextField(_titleController,
                            "Give your memory a title...", theme),
                        const SizedBox(height: 24),
                        if (_selectedType != MemoryType.text) ...[
                          _buildSectionTitle(
                              "Attach ${_capitalize(_selectedType.name)} (Max 5 photos)",
                              theme),
                          _buildFilePicker(theme, isDark),
                          const SizedBox(height: 24),
                        ],
                        _buildSectionTitle(
                            _selectedType == MemoryType.text
                                ? "Your Memory"
                                : "Description",
                            theme),
                        _buildTextField(_contentController,
                            "Write about this moment...", theme,
                            maxLines: 5),
                        const SizedBox(height: 32),
                        _buildOptionTile(
                          title: "Share to Community",
                          subtitle: "Make this visible to others (Max 50MB)",
                          icon: Icons.public,
                          value: _shareToCommunity,
                          onChanged: (val) =>
                              setState(() => _shareToCommunity = val),
                          theme: theme,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildOptionTile(
                          title: "Time-Lock Memory",
                          subtitle: "Seal this until a future date",
                          icon: Icons.lock_clock,
                          value: _isTimeLocked,
                          onChanged: (val) =>
                              setState(() => _isTimeLocked = val),
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

  String _capitalize(String s) =>
      s.isEmpty ? s : "${s[0].toUpperCase()}${s.substring(1)}";

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
    );
  }

  Widget _buildOptionTile(
      {required String title,
      required String subtitle,
      required IconData icon,
      required bool value,
      required Function(bool) onChanged,
      required ThemeData theme,
      required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: value
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: value
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ]),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildFilePicker(ThemeData theme, bool isDark) {
    return InkWell(
      onTap: _pickFiles,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: theme.dividerColor, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            if (_selectedFiles.isEmpty) ...[
              Icon(Icons.cloud_upload_outlined,
                  size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text("Tap to select ${_selectedType.name} file(s)",
                  style: TextStyle(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: _selectedType == MemoryType.photo
                              ? DecorationImage(
                                  image: FileImage(file), fit: BoxFit.cover)
                              : null,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                        ),
                        child: _selectedType != MemoryType.photo
                            ? const Icon(Icons.insert_drive_file)
                            : null,
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFiles.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      if (_selectedType == MemoryType.photo)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: GestureDetector(
                            onTap: () => _editPhoto(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text("${_selectedFiles.length} file(s) selected",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editPhoto(int index) async {
    // This is a placeholder for actual photo editing logic.
    // In a real app, you might use a package like 'pro_image_editor' or 'image_editor_plus'.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              "Photo editing coming soon! Integrate an editor package for full functionality.")),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor)),
          color: theme.colorScheme.surface),
      child: ElevatedButton(
        onPressed: _handleSave,
        style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56)),
        child: const Text("Create Memory",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildTypeButton(
      MemoryType type, IconData icon, String label, ThemeData theme) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedType = type;
          _selectedFiles = [];
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    isSelected ? theme.colorScheme.primary : theme.dividerColor,
                width: 2),
          ),
          child: Column(children: [
            Icon(icon,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ]),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, ThemeData theme,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.dividerColor)),
      ),
    );
  }
}
