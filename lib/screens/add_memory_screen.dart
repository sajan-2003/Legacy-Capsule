import 'package:flutter/material.dart';
import '../models/memory.dart';

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

  void _handleSave() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) return;

    final newMemory = Memory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      title: title,
      preview: content.length > 100 ? '${content.substring(0, 100)}...' : content,
      type: _selectedType,
      content: content,
      isLocked: false,
    );

    widget.onSave(newMemory);
    Navigator.pop(context);
  }

  Widget _buildTypeButton(MemoryType type, IconData icon, String label) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF0369A1) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "New Memory",
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Memory Type",
                    style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTypeButton(MemoryType.text, Icons.description_outlined, "Text"),
                      const SizedBox(width: 12),
                      _buildTypeButton(MemoryType.photo, Icons.image_outlined, "Photo"),
                      const SizedBox(width: 12),
                      _buildTypeButton(MemoryType.video, Icons.videocam_outlined, "Video"),
                      const SizedBox(width: 12),
                      _buildTypeButton(MemoryType.audio, Icons.mic_none_outlined, "Audio"),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Title",
                    style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: "Give your memory a title...",
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _selectedType == MemoryType.text ? "Your Memory" : "Description",
                    style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedType == MemoryType.text)
                    TextField(
                      controller: _contentController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: "Write about this moment...",
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 2, style: BorderStyle.solid), // Ideally dashed
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(
                              _selectedType == MemoryType.photo
                                  ? Icons.image_outlined
                                  : _selectedType == MemoryType.video
                                      ? Icons.videocam_outlined
                                      : Icons.mic_none_outlined,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text("Tap to upload ${_selectedType.name}", style: const TextStyle(color: Color(0xFF475569))),
                          const Text("Or add a description below", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _contentController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: "Add a description...",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              color: Colors.white,
            ),
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Save Memory", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
