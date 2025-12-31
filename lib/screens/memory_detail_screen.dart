import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/memory.dart';

class MemoryDetailScreen extends StatefulWidget {
  final Memory memory;
  final Function(String) onDelete;
  final Function(String) onToggleLock;

  const MemoryDetailScreen({
    super.key,
    required this.memory,
    required this.onDelete,
    required this.onToggleLock,
  });

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  bool _showDeleteConfirm = false;

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;

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
          "Memory",
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  widget.onToggleLock(memory.id);
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: memory.isLocked ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  memory.isLocked ? Icons.lock : Icons.lock_open,
                  size: 20,
                  color: memory.isLocked ? const Color(0xFFB45309) : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
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
                  // Date
                  Text(
                    _formatDate(memory.date),
                    style: const TextStyle(
                      color: Color(0xFF0369A1),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lock Status Banner
                  if (memory.isLocked) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock, size: 20, color: Color(0xFFB45309)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "This memory is locked",
                                  style: TextStyle(
                                    color: Color(0xFF78350F),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "You can set a time-lock to preserve this memory for the future.",
                                  style: TextStyle(
                                    color: Color(0xFFB45309),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Image
                  if (memory.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        memory.imageUrl!,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 250,
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Title
                  Text(
                    memory.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content
                  Text(
                    memory.content,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF334155),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              color: Colors.white,
            ),
            child: !_showDeleteConfirm
                ? Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text("Edit Memory"),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _showDeleteConfirm = true),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text("Delete Memory"),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Are you sure you want to delete this memory? This cannot be undone.",
                          style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _showDeleteConfirm = false),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                  foregroundColor: const Color(0xFF334155),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("Cancel"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  widget.onDelete(memory.id);
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("Delete"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
