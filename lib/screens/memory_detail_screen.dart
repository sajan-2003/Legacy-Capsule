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
  final TextEditingController _commentController = TextEditingController();
  bool _isReacted = false;

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(date);
  }

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() {
      widget.memory.comments.insert(0, Comment(
        id: DateTime.now().toString(),
        userName: "You",
        text: _commentController.text,
        date: DateTime.now(),
      ));
      _commentController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void _toggleReaction() {
    setState(() {
      _isReacted = !_isReacted;
      if (_isReacted) {
        widget.memory.reactionCount++;
      } else {
        widget.memory.reactionCount--;
      }
    });
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
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF64748B)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing memory...')),
              );
            },
          ),
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
                  Text(
                    _formatDate(memory.date),
                    style: const TextStyle(color: Color(0xFF0369A1), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  if (memory.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        memory.imageUrl!,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    memory.title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    memory.content,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF334155), height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  
                  // Interaction Stats
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 16, color: _isReacted ? Colors.red : Colors.grey),
                      const SizedBox(width: 4),
                      Text("${memory.reactionCount}", style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      const SizedBox(width: 16),
                      const Icon(Icons.comment_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("${memory.comments.length}", style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    ],
                  ),
                  const Divider(height: 48),
                  
                  // Interaction Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        icon: _isReacted ? Icons.favorite : Icons.favorite_border,
                        label: "Love",
                        color: _isReacted ? Colors.red : const Color(0xFF64748B),
                        onTap: _toggleReaction,
                      ),
                      _buildActionButton(
                        icon: Icons.comment_outlined,
                        label: "Comment",
                        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                      ),
                      _buildActionButton(
                        icon: Icons.ios_share_outlined,
                        label: "Share",
                        onTap: () {},
                      ),
                    ],
                  ),
                  const Divider(height: 48),

                  // Comments Section
                  const Text("Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...memory.comments.map((c) => _buildCommentTile(c)),
                  const SizedBox(height: 100), // Space for keyboard
                ],
              ),
            ),
          ),
          
          // Comment Input
          Container(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 12, 
              bottom: MediaQuery.of(context).viewInsets.bottom + 12
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF0284C7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, Color? color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color ?? const Color(0xFF64748B)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color ?? const Color(0xFF64748B), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Comment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE0F2FE),
            child: Icon(Icons.person, size: 16, color: Color(0xFF0284C7)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(DateFormat('MMM d').format(comment.date), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.text, style: const TextStyle(color: Color(0xFF475569), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
