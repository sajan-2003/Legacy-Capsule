import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
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
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late MemoryType _selectedType;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  List<File> _selectedFiles = [];
  bool _isTimeLocked = false;
  DateTime? _lockDate;
  bool _shareToCommunity = false;
  bool _isSaving = false;

  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialMemory?.type ?? MemoryType.text;
    _titleController.text = widget.initialMemory?.title ?? "";
    _contentController.text = widget.initialMemory?.content ?? "";
    _isTimeLocked = widget.initialMemory?.isLocked ?? false;
    if (widget.initialMemory != null && widget.initialMemory!.imageUrls.isNotEmpty) {
      _selectedFiles = widget.initialMemory!.imageUrls.map((path) => File(path)).toList();
    }
    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _isNextEnabled {
    if (_currentPage == 0) return true;
    if (_currentPage == 1) {
      if (_titleController.text.trim().isEmpty) return false;
      if (_selectedType != MemoryType.text && _selectedFiles.isEmpty) return false;
      if (_selectedType == MemoryType.text && _contentController.text.trim().isEmpty) return false;
      return true;
    }
    if (_currentPage == 2) {
      if (_isTimeLocked && _lockDate == null) return false;
      return true;
    }
    return true;
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _pickMedia() async {
    try {
      if (_selectedType == MemoryType.photo) {
        final List<XFile> images = await _imagePicker.pickMultiImage(limit: 5);
        if (images.isNotEmpty) {
          setState(() {
            _selectedFiles = images.take(5).map((image) => File(image.path)).toList();
          });
        }
      } else if (_selectedType == MemoryType.video) {
        final XFile? video = await _imagePicker.pickVideo(source: ImageSource.gallery);
        if (video != null) setState(() => _selectedFiles = [File(video.path)]);
      } else if (_selectedType == MemoryType.audio) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
        if (result != null) setState(() => _selectedFiles = [File(result.files.single.path!)]);
      }
    } catch (e) {
      _showError("Error picking media: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message), 
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _handleSave() async {
    if (!_isNextEnabled) return;
    
    setState(() => _isSaving = true);
    
    // Aesthetic delay for vault feeling
    await Future.delayed(const Duration(seconds: 2));

    try {
      final newMemory = Memory(
        id: widget.initialMemory?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date: _lockDate ?? DateTime.now(),
        title: _titleController.text.trim(),
        preview: _contentController.text.isNotEmpty 
            ? (_contentController.text.length > 50 ? "${_contentController.text.substring(0, 50)}..." : _contentController.text)
            : (_selectedFiles.isNotEmpty ? "Media attached" : "New memory"),
        type: _selectedType,
        content: _contentController.text.trim(),
        imageUrls: _selectedFiles.map((f) => f.path).toList(),
        isLocked: _isTimeLocked,
      );

      widget.onSave(newMemory);

      if (_shareToCommunity) {
        await _storageService.shareToCommunity(newMemory, _selectedFiles.isNotEmpty ? _selectedFiles.first : null);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError(e.toString());
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildProgressIndicator(),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentPage < 2)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _isNextEnabled ? _nextPage : null,
                child: Text("Next", style: TextStyle(fontWeight: FontWeight.bold, color: _isNextEnabled ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withOpacity(0.5))),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (int page) => setState(() => _currentPage = page),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildTypeAndContentPage(theme),
              _buildPrivacyPage(theme),
              _buildReviewPage(theme),
            ],
          ),
          if (_isSaving) _buildSavingOverlay(theme),
        ],
      ),
      bottomNavigationBar: _isSaving ? null : _buildBottomNav(theme),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        bool isActive = index == _currentPage;
        bool isCompleted = index < _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 4,
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isCompleted 
                ? Theme.of(context).colorScheme.primary 
                : (isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildTypeAndContentPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What are you saving today?", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Choose a format and tell your story.", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          
          // Format selection
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _typeIconCard(MemoryType.text, Icons.edit_note_rounded, "Journal", theme),
                _typeIconCard(MemoryType.photo, Icons.collections_rounded, "Photos", theme),
                _typeIconCard(MemoryType.video, Icons.videocam_rounded, "Video", theme),
                _typeIconCard(MemoryType.audio, Icons.mic_external_on_rounded, "Audio", theme),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          TextField(
            controller: _titleController,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: "Memory Title",
              hintText: "E.g., Grandfather's Wisdom",
              floatingLabelBehavior: FloatingLabelBehavior.always,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: _buildTypeSpecificInput(theme),
          ),
          
          const SizedBox(height: 40),
          // Tip section to fill space
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Storytelling Tip", style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      Text("Try to include how you felt at that moment. Your emotions are what make this legacy truly yours.", style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeIconCard(MemoryType type, IconData icon, String label, ThemeData theme) {
    bool isSelected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: () => setState(() {
          _selectedType = type;
          _selectedFiles = [];
        }),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 80,
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              width: 2.0,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 10, color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSpecificInput(ThemeData theme) {
    switch (_selectedType) {
      case MemoryType.text:
        return TextField(
          controller: _contentController,
          maxLines: 8,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: "What do you want the future to know?",
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(20),
          ),
        );
      case MemoryType.photo:
        return Column(
          key: const ValueKey('photo_input'),
          children: [
            if (_selectedFiles.isNotEmpty)
              Container(
                height: 180,
                margin: const EdgeInsets.only(bottom: 20),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) => _buildImagePreview(index, theme),
                ),
              ),
            if (_selectedFiles.length < 5)
              _buildMediaPlaceholder(Icons.add_photo_alternate_rounded, "Add Photos (${_selectedFiles.length}/5)", "Show the beauty of this moment", theme),
          ],
        );
      case MemoryType.video:
      case MemoryType.audio:
        return _selectedFiles.isEmpty 
          ? _buildMediaPlaceholder(
              _selectedType == MemoryType.video ? Icons.video_call_rounded : Icons.audiotrack_rounded, 
              "Select ${_selectedType.name}", 
              _selectedType == MemoryType.video ? "Capture a living legacy" : "Record or upload a voice",
              theme)
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                    child: Icon(_selectedType == MemoryType.video ? Icons.movie_rounded : Icons.audiotrack_rounded, size: 20, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedFiles.first.path.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text("${(_selectedFiles.first.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB", style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                    ],
                  )),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20), 
                    onPressed: _pickMedia,
                    tooltip: "Replace",
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, size: 20, color: theme.colorScheme.error), 
                    onPressed: () => setState(() => _selectedFiles = []),
                    tooltip: "Remove",
                  ),
                ],
              ),
            );
    }
  }

  Widget _buildImagePreview(int index, ThemeData theme) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          Hero(
            tag: 'image_$index',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(_selectedFiles[index], width: 130, height: 180, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _selectedFiles.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 8, right: 8,
            child: GestureDetector(
              onTap: () => _openImageEditor(index),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                child: const Icon(Icons.auto_fix_high_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openImageEditor(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImageEditSheet(
        image: _selectedFiles[index],
        onSave: (editedFile) => setState(() => _selectedFiles[index] = editedFile),
      ),
    );
  }

  Widget _buildMediaPlaceholder(IconData icon, String label, String subtitle, ThemeData theme) {
    return InkWell(
      onTap: _pickMedia,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3), style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Vault Security", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Decide how this memory will be protected and shared.", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          _buildSettingsTile(
            title: "Time-Lock Memory",
            subtitle: "Seal this memory until a future date",
            icon: Icons.lock_person_rounded,
            value: _isTimeLocked,
            onChanged: (val) => setState(() {
              _isTimeLocked = val;
              if (val && _lockDate == null) _selectDate(theme);
            }),
            theme: theme,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _isTimeLocked 
              ? Padding(
                  padding: const EdgeInsets.only(left: 64, top: 12),
                  child: InkWell(
                    onTap: () => _selectDate(theme),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.4), 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_available_rounded, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Release Date", style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: theme.colorScheme.primary)),
                              Text(_lockDate == null ? "Select date" : DateFormat('MMM d, yyyy').format(_lockDate!), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          _buildSettingsTile(
            title: "Community Sharing",
            subtitle: "Share this wisdom with the world",
            icon: Icons.public_rounded,
            value: _shareToCommunity,
            onChanged: (val) => setState(() => _shareToCommunity = val),
            theme: theme,
          ),
          
          const SizedBox(height: 40),
          // Security info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow, 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.security_rounded, color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text("Digital Vault Shield", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Your memories are encrypted with 256-bit AES protection before being stored. Even we cannot see what's inside your vault.",
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow, 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.verified_user_rounded, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Vault Protection Active", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text("End-to-end encryption ensures your memories are secure.", style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({required String title, required String subtitle, required IconData icon, required bool value, required ValueChanged<bool> onChanged, required ThemeData theme}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value ? theme.colorScheme.primary.withOpacity(0.1) : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: value ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _selectDate(ThemeData theme) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: theme.colorScheme.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _lockDate = picked);
  }

  Widget _buildReviewPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Final Review", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Ensure everything is perfect for your legacy.", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          _reviewCard(theme),
          const SizedBox(height: 24),
          // Quotes or Inspiring text to fill space
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "\"Your story is the greatest gift you can give to the future.\"",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _handleSave,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 64),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 20),
                SizedBox(width: 12),
                Text("Secure in Vault", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _reviewItem("Title", _titleController.text, Icons.title_rounded, theme),
          const Divider(height: 24),
          _reviewItem("Format", _selectedType.name.toUpperCase(), Icons.category_rounded, theme),
          if (_selectedType != MemoryType.text) ...[
            const Divider(height: 24),
            _reviewItem("Media", "${_selectedFiles.length} file(s)", Icons.attachment_rounded, theme),
          ],
          const Divider(height: 24),
          _reviewItem("Security", _isTimeLocked ? "Locked until ${DateFormat('MMM d, yyyy').format(_lockDate!)}" : "Permanent Archive", Icons.shield_rounded, theme),
          const Divider(height: 24),
          _reviewItem("Sharing", _shareToCommunity ? "Public Legacy" : "Private Vault", Icons.visibility_rounded, theme),
        ],
      ),
    );
  }

  Widget _reviewItem(String label, String value, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
              Text(value, style: theme.textTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            IconButton.filledTonal(
              onPressed: _prevPage, 
              icon: const Icon(Icons.arrow_back_rounded, size: 24),
              style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
            )
          else
            const SizedBox(width: 56),
          if (_currentPage < 2)
            ElevatedButton(
              onPressed: _isNextEnabled ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(160, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Row(
                children: [
                  Text("Continue", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSavingOverlay(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface.withOpacity(0.95),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60, height: 60,
              child: CircularProgressIndicator(strokeWidth: 4, strokeCap: StrokeCap.round),
            ),
            const SizedBox(height: 32),
            Text("Securing your memory...", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Encrypting and sealing in the digital vault", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 32),
            Icon(Icons.lock_outline_rounded, size: 48, color: theme.colorScheme.primary.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}

class _ImageEditSheet extends StatefulWidget {
  final File image;
  final Function(File) onSave;

  const _ImageEditSheet({required this.image, required this.onSave});

  @override
  State<_ImageEditSheet> createState() => _ImageEditSheetState();
}

class _ImageEditSheetState extends State<_ImageEditSheet> {
  double _rotation = 0;
  double _brightness = 0;
  double _contrast = 1;
  bool _isGrayscale = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(width: 32, height: 4, decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Enhance Photo", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              IconButton.filled(
                icon: const Icon(Icons.check_rounded, size: 20), 
                onPressed: () {
                  widget.onSave(widget.image);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Hero(
                tag: 'image_edit',
                child: Transform.rotate(
                  angle: _rotation,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.matrix([
                      _contrast * (_isGrayscale ? 0.2126 : 1), _isGrayscale ? 0.7152 : 0, _isGrayscale ? 0.0722 : 0, 0, _brightness * 255,
                      _isGrayscale ? 0.2126 : 0, _contrast * (_isGrayscale ? 0.7152 : 1), _isGrayscale ? 0.0722 : 0, 0, _brightness * 255,
                      _isGrayscale ? 0.2126 : 0, _isGrayscale ? 0.7152 : 0, _contrast * (_isGrayscale ? 0.0722 : 1), 0, _brightness * 255,
                      0, 0, 0, 1, 0,
                    ]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(widget.image),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _editToolbox(theme),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _editToolbox(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          _editSlider("Brightness", _brightness, -0.5, 0.5, (val) => setState(() => _brightness = val), theme),
          const SizedBox(height: 8),
          _editSlider("Contrast", _contrast, 0.5, 1.5, (val) => setState(() => _contrast = val), theme),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionIcon(Icons.rotate_left_rounded, "Rotate L", () => setState(() => _rotation -= 1.5708), theme),
              _actionIcon(_isGrayscale ? Icons.color_lens : Icons.color_lens_outlined, "B&W", () => setState(() => _isGrayscale = !_isGrayscale), theme),
              _actionIcon(Icons.refresh_rounded, "Reset", () => setState(() { _rotation = 0; _brightness = 0; _contrast = 1; _isGrayscale = false; }), theme),
              _actionIcon(Icons.rotate_right_rounded, "Rotate R", () => setState(() => _rotation += 1.5708), theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editSlider(String label, double value, double min, double max, ValueChanged<double> onChanged, ThemeData theme) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 11))),
        Expanded(
          child: Slider(
            value: value, 
            min: min, 
            max: max, 
            onChanged: onChanged,
            activeColor: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _actionIcon(IconData icon, String label, VoidCallback onTap, ThemeData theme) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurface),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
