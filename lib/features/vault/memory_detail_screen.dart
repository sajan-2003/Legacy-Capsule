import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/memory.dart';
import '../../services/storage_service.dart';

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
  late bool _isReacted;

  @override
  void initState() {
    super.initState();
    _isReacted = widget.memory.reactionCount > 0;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(date);
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    final profile = _storageService.getUserProfile();
    final newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: profile?.displayName ?? "You",
      text: _commentController.text,
      date: DateTime.now(),
    );

    setState(() {
      widget.memory.comments.insert(0, newComment);
      _commentController.clear();
    });

    try {
      if (widget.isCommunityPost) {
        await _storageService.addCommunityComment(widget.memory.id, newComment);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cloud comment failed, saved locally.")),
        );
      }
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

  Future<void> _shareToCommunity() async {
    final profile = _storageService.getUserProfile();
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please update your profile details first.")),
      );
      return;
    }

    try {
      final sharedMemory = Memory(
        id: widget.memory.id,
        date: widget.memory.date,
        title: widget.memory.title,
        preview: widget.memory.preview,
        type: widget.memory.type,
        content: widget.memory.content,
        imageUrls: widget.memory.imageUrls,
        authorId: profile.uid,
        authorName: profile.displayName,
        reactionCount: widget.memory.reactionCount,
        comments: widget.memory.comments,
      );

      await _storageService.shareToCommunity(sharedMemory, null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Memory shared to community feed!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Share failed: $e")),
        );
      }
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
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface.withAlpha(153)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isCommunityPost ? "Community Post" : "Memory", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        actions: [
          if (!widget.isCommunityPost) ...[
            IconButton(
              icon: Icon(Icons.share_outlined, color: theme.colorScheme.onSurface.withAlpha(153)),
              onPressed: _shareToCommunity,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  if (widget.onToggleLock != null) widget.onToggleLock!(memory.id);
                },
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: memory.isLocked ? const Color(0xFFB45309).withAlpha(25) : theme.colorScheme.onSurface.withAlpha(13),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(memory.isLocked ? Icons.lock : Icons.lock_open, size: 20, color: memory.isLocked ? const Color(0xFFB45309) : theme.colorScheme.onSurface.withAlpha(153)),
                ),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isCommunityPost || memory.authorName != null)
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
                  if (memory.imageUrls.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildMediaContent(memory, theme, isDark),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(memory.title, style: theme.textTheme.displaySmall?.copyWith(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  Text(memory.content, style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withAlpha(204), height: 1.6)),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 16, color: _isReacted ? Colors.red : theme.colorScheme.onSurface.withAlpha(77)),
                      const SizedBox(width: 4),
                      Text("${memory.reactionCount}", style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withAlpha(127))),
                      const SizedBox(width: 16),
                      Icon(Icons.comment_outlined, size: 16, color: theme.colorScheme.onSurface.withAlpha(77)),
                      const SizedBox(width: 4),
                      Text("${memory.comments.length}", style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withAlpha(127))),
                    ],
                  ),
                  Divider(height: 48, color: theme.dividerColor),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        icon: _isReacted ? Icons.favorite : Icons.favorite_border,
                        label: "Love",
                        color: _isReacted ? Colors.red : theme.colorScheme.onSurface.withAlpha(153),
                        onTap: _toggleReaction,
                      ),
                      _buildActionButton(
                        icon: Icons.comment_outlined,
                        label: "Comment",
                        color: theme.colorScheme.onSurface.withAlpha(153),
                        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                      ),
                    ],
                  ),
                  Divider(height: 48, color: theme.dividerColor),

                  Text("Comments", style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
                  const SizedBox(height: 16),
                  ...memory.comments.map((c) => _buildCommentTile(c, theme)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 51 : 13), 
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  )
                ],
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: "Add a comment...",
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withAlpha(102)),
                        filled: true,
                        fillColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addComment, 
                    icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(Memory memory, ThemeData theme, bool isDark) {
    if (memory.type == MemoryType.video) {
      return _UnifiedFullControlVideoPlayer(
        videoPath: memory.imageUrls.first,
        height: 300,
      );
    } else if (memory.type == MemoryType.photo) {
      return SizedBox(
        height: 400,
        child: PageView.builder(
          itemCount: memory.imageUrls.length,
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: _buildImage(memory.imageUrls[index], theme, isDark),
            );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildImage(String url, ThemeData theme, bool isDark) {
    return url.startsWith('http')
        ? CachedNetworkImage(
            imageUrl: url, 
            width: double.infinity, 
            fit: BoxFit.contain,
            placeholder: (context, url) => Container(
              color: isDark ? theme.colorScheme.onSurface.withAlpha(13) : const Color(0xFFF1F5F9),
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image)),
          )
        : Image.file(File(url), width: double.infinity, fit: BoxFit.contain);
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
          CircleAvatar(radius: 16, backgroundColor: theme.colorScheme.primary.withAlpha(25), child: Icon(Icons.person, size: 16, color: theme.colorScheme.primary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Text(comment.userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface)), const SizedBox(width: 8), Text(DateFormat('MMM d').format(comment.date), style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(102), fontSize: 11))]),
                const SizedBox(height: 4),
                Text(comment.text, style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(178), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnifiedFullControlVideoPlayer extends StatefulWidget {
  final String videoPath;
  final double height;
  const _UnifiedFullControlVideoPlayer({required this.videoPath, this.height = 250});

  @override
  State<_UnifiedFullControlVideoPlayer> createState() => _UnifiedFullControlVideoPlayerState();
}

class _UnifiedFullControlVideoPlayerState extends State<_UnifiedFullControlVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    _controller = widget.videoPath.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoPath))
        : VideoPlayerController.file(File(widget.videoPath));

    try {
      await _controller.initialize();
      _controller.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startHideTimer();
      }
    } catch (e) {
      debugPrint("Video init error: $e");
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
          if (_showControls) _startHideTimer();
        });
      },
      child: Container(
        width: double.infinity,
        height: widget.height,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
            
            if (_showControls)
              Container(
                color: Colors.black26,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(
                          _controller.value.volume > 0 ? Icons.volume_up : Icons.volume_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _controller.setVolume(_controller.value.volume > 0 ? 0 : 1);
                          });
                          _startHideTimer();
                        },
                      ),
                    ),

                    IconButton(
                      iconSize: 48,
                      icon: Icon(
                        _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                        });
                        _startHideTimer();
                      },
                    ),

                    Column(
                      children: [
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.blueAccent,
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_controller.value.position),
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                              Text(
                                _formatDuration(_controller.value.duration),
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
