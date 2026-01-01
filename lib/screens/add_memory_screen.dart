import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  bool _isTimeLocked = false;
  DateTime? _unlockDate;
  String _lockType = 'date'; // 'date' or 'age'
  final TextEditingController _ageController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0284C7),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _unlockDate = picked);
    }
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) return;

    final newMemory = Memory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      title: title,
      preview:
          content.length > 100 ? '${content.substring(0, 100)}...' : content,
      type: _selectedType,
      content: content,
      isLocked: _isTimeLocked,
    );

    widget.onSave(newMemory);
    Navigator.pop(context);
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
          style:
              TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
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
                  // Memory Type
                  const Text("Memory Type",
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF334155))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTypeButton(
                          MemoryType.text, Icons.description_outlined, "Text"),
                      const SizedBox(width: 12),
                      _buildTypeButton(
                          MemoryType.photo, Icons.image_outlined, "Photo"),
                      const SizedBox(width: 12),
                      _buildTypeButton(
                          MemoryType.video, Icons.videocam_outlined, "Video"),
                      const SizedBox(width: 12),
                      _buildTypeButton(
                          MemoryType.audio, Icons.mic_none_outlined, "Audio"),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text("Title",
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  _buildTextField(
                      _titleController, "Give your memory a title..."),
                  const SizedBox(height: 24),

                  // Content
                  Text(
                      _selectedType == MemoryType.text
                          ? "Your Memory"
                          : "Description",
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  _buildTextField(
                      _contentController, "Write about this moment...",
                      maxLines: 5),

                  const SizedBox(height: 32),

                  // TIME LOCK SECTION
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _isTimeLocked
                              ? const Color(0xFFBAE6FD)
                              : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isTimeLocked
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFF94A3B8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.lock_clock,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Time-Lock Memory",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  "Seal this until a future date",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Switch(
                              value: _isTimeLocked,
                              activeTrackColor:
                                  const Color(0xFF0284C7).withValues(alpha: 0.5),
                              activeThumbColor: const Color(0xFF0284C7),
                              onChanged: (val) =>
                                  setState(() => _isTimeLocked = val),
                            ),
                          ],
                        ),
                        if (_isTimeLocked) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildLockOption("Specific Date", 'date'),
                              const SizedBox(width: 12),
                              _buildLockOption("Age Milestone", 'age'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_lockType == 'date')
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 18, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 12),
                                    Text(
                                      _unlockDate == null
                                          ? "Select Unlock Date"
                                          : DateFormat('MMMM d, yyyy')
                                              .format(_unlockDate!),
                                      style: TextStyle(
                                        color: _unlockDate == null
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF0F172A),
                                        fontWeight: _unlockDate == null
                                            ? FontWeight.normal
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            TextField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "Enter age (e.g. 18)",
                                prefixIcon: const Icon(Icons.cake,
                                    size: 18, color: Color(0xFF0284C7)),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0))),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Save Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                color: Colors.white),
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Create Memory",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(MemoryType type, IconData icon, String label) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected
                    ? const Color(0xFF0EA5E9)
                    : const Color(0xFFE2E8F0),
                width: 2),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected
                      ? const Color(0xFF0284C7)
                      : const Color(0xFF64748B)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF0369A1)
                          : const Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockOption(String label, String type) {
    bool isSelected = _lockType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _lockType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isSelected
                    ? const Color(0xFF0284C7)
                    : const Color(0xFFE2E8F0)),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF0284C7)
                      : const Color(0xFF64748B))),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      ),
    );
  }
}
