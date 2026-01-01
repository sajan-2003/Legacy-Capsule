import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../models/memory.dart';
import '../services/storage_service.dart';

class MemoryDetailScreen extends StatefulWidget {
  final Memory memory;
  final Function(String)? onDelete;
  final Function(String)? onToggleLock;
  final bool isCommunityPost;

  const MemoryDetailScreen({
    super.key,
    required this.memory,
    this.onDelete,
    this.onToggleLock,
    this.isCommunityPost = false,
  });

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final StorageService _storageService = StorageService();
  VideoPlayerController? _videoController;
  late bool _isReacted;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _isReacted = widget.memory.reactionCount > 0;
    if (widget.memory.type == MemoryType.video && widget.memory.imageUrl != null && widget.memory.imageUrl!.isNotEmpty) {
      _initVideo();
    }
  }

  void _initVideo() {
    try {
      _videoController = widget.memory.imageUrl!.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(widget.memory.imageUrl!))
          : VideoPlayerController.file(File(widget.memory.imageUrl!));

      _videoController!.initialize().then((_) {
        if (mounted) setState(() {});
      }).catchError((e) {
        debugPrint("Video init error: $e");
      });
    } catch (e) {
      debugPrint("Video controller setup error: $e");
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(date);
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    final newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: "You",
      text: _commentController.text,
      date: DateTime.now(),
    );

    setState(() {
      widget.memory.comments.insert(0, newComment);
      _commentController.clear();
    });

    if (widget.isCommunityPost) {
      await _storageService.addCommunityComment(widget.memory.id, newComment);
    }
    
    FocusScope.of(context).unfocus();
  }

  void _toggleReaction() async {
    setState(() {
      _isReacted = !_isReacted;
      if (_isReacted) {
        widget.memory.reactionCount++;
      } else {
        widget.memory.reactionCount--;
      }
    });

    if (widget.isCommunityPost) {
      await _storageService.updateReaction(widget.memory.id, widget.memory.reactionCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final memory = widget.memory;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isCommunityPost ? "Community Post" : "Memory", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        actions: [
          if (!widget.isCommunityPost) ...[
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () {
                  if (widget.onToggleLock != null) widget.onToggleLock!(memory.id);
                },
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: memory.isLocked ? const Color(0xFFB45309).withOpacity(0.1) : theme.colorScheme.onSurface.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(memory.isLocked ? Icons.lock : Icons.lock_open, size: 20, color: memory.isLocked ? const Color(0xFFB45309) : theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
              ),
            ),
          ],
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: theme.dividerColor, height: 1)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isCommunityPost)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20, 
                          child: Text(
                            (memory.authorName != null && memory.authorName!.isNotEmpty) 
                              ? memory.authorName![0].toUpperCase() 
                              : "U"
                          )
                        ),
                        const SizedBox(width: 12),
                        Text(memory.authorName ?? "Legacy User", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Text(_formatDate(memory.date), style: TextStyle(color: theme.colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  if (memory.imageUrl != null && memory.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildMediaContent(memory, theme),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(memory.title, style: theme.textTheme.displaySmall?.copyWith(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  Text(memory.content, style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.8), height: 1.6)),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 16, color: _isReacted ? Colors.red : theme.colorScheme.onSurface.withOpacity(0.3)),
                      const SizedBox(width: 4),
                      Text("${memory.reactionCount}", style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                      const SizedBox(width: 16),
                      Icon(Icons.comment_outlined, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                      const SizedBox(width: 4),
                      Text("${memory.comments.length}", style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                    ],
                  ),
                  Divider(height: 48, color: theme.dividerColor),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        icon: _isReacted ? Icons.favorite : Icons.favorite_border,
                        label: "Love",
                        color: _isReacted ? Colors.red : theme.colorScheme.onSurface.withOpacity(0.6),
                        onTap: _toggleReaction,
                      ),
                      _buildActionButton(
                        icon: Icons.comment_outlined,
                        label: "Comment",
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                      ),
                    ],
                  ),
                  Divider(height: 48, color: theme.dividerColor),

                  Text("Comments", style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
                  const SizedBox(height: 16),
                  ...memory.comments.map((c) => _buildCommentTile(c, theme)),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          Container(
            padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 12),
            decoration: BoxDecoration(color: theme.colorScheme.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10)], border: Border(top: BorderSide(color: theme.dividerColor))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      filled: true,
                      fillColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: _addComment, icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(Memory memory, ThemeData theme) {
    if (memory.type == MemoryType.video) {
      if (_videoController != null && _videoController!.value.isInitialized) {
        return Column(
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            VideoProgressIndicator(_videoController!, allowScrubbing: true),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    setState(() {
                      _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                    });
                  },
                ),
              ],
            ),
          ],
        );
      } else {
        return Container(height: 250, width: double.infinity, color: Colors.black12, child: const Center(child: CircularProgressIndicator()));
      }
    } else if (memory.type == MemoryType.photo) {
      return memory.imageUrl!.startsWith('http')
          ? Image.network(memory.imageUrl!, width: double.infinity, height: 250, fit: BoxFit.cover)
          : Image.file(File(memory.imageUrl!), width: double.infinity, height: 250, fit: BoxFit.cover);
    }
    return const SizedBox.shrink();
  }

  Widget _buildActionButton({required IconData icon, required String label, Color? color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Column(children: [Icon(icon, color: color), const SizedBox(height: 4), Text(label, style: TextStyle(color: color, fontSize: 12))])),
    );
  }

  Widget _buildCommentTile(Comment comment, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 16, backgroundColor: theme.colorScheme.primary.withOpacity(0.1), child: Icon(Icons.person, size: 16, color: theme.colorScheme.primary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Text(comment.userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface)), const SizedBox(width: 8), Text(DateFormat('MMM d').format(comment.date), style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 11))]),
                const SizedBox(height: 4),
                Text(comment.text, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
