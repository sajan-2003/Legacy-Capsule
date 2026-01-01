import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../models/memory.dart';
import '../services/storage_service.dart';
import 'memory_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  final bool isSearching;
  final TextEditingController searchController;
  final Function(bool) onThemeChanged;

  const CommunityScreen({
    super.key,
    required this.isSearching,
    required this.searchController,
    required this.onThemeChanged,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  bool _headerSearching = false;
  final StorageService _storageService = StorageService();
  late Stream<List<Memory>> _postsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _postsStream = _storageService.getCommunityPosts();
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo captured: ${photo.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accessing camera: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: _headerSearching 
          ? TextField(
              controller: widget.searchController,
              autofocus: true,
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
              decoration: InputDecoration(
                hintText: "Search community...",
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                border: InputBorder.none,
              ),
              onChanged: (val) => setState(() {}),
            )
          : Text(
              "Community",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
        actions: [
          IconButton(
            icon: Icon(_headerSearching ? Icons.close : Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            onPressed: () => setState(() {
              _headerSearching = !_headerSearching;
              if (!_headerSearching) {
                widget.searchController.clear();
              }
            }),
          ),
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            onPressed: _openCamera,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: "Feed"),
            Tab(text: "Friends"),
            Tab(text: "Groups"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FeedTab(postsStream: _postsStream, storageService: _storageService, searchController: widget.searchController),
          const _FriendsTab(),
          const _GroupsTab(),
        ],
      ),
    );
  }
}

class _FeedTab extends StatefulWidget {
  final Stream<List<Memory>> postsStream;
  final StorageService storageService;
  final TextEditingController searchController;

  const _FeedTab({required this.postsStream, required this.storageService, required this.searchController});

  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return RepaintBoundary(
      child: StreamBuilder<List<Memory>>(
        stream: widget.postsStream,
        initialData: widget.storageService.getCachedCommunityPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Center(child: Text("No posts yet. Be the first to share!", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final memory = posts[index];
              final query = widget.searchController.text.toLowerCase();
              if (query.isNotEmpty && !memory.title.toLowerCase().contains(query)) {
                return const SizedBox.shrink();
              }
              return _PostCard(
                key: ValueKey(memory.id),
                memory: memory,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemoryDetailScreen(
                        memory: memory,
                        isCommunityPost: true,
                      ),
                    ),
                  );
                },
              );
            },
          );
        }
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final Memory memory;
  final VoidCallback onTap;
  const _PostCard({super.key, required this.memory, required this.onTap});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  final StorageService _storageService = StorageService();
  bool _showComments = false;

  void _toggleReaction() async {
    setState(() {
      if (widget.memory.reactionCount > 0) {
        widget.memory.reactionCount--;
      } else {
        widget.memory.reactionCount++;
      }
    });
    await _storageService.updateReaction(widget.memory.id, widget.memory.reactionCount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? theme.colorScheme.onSurface.withOpacity(0.1) : const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.person, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.memory.authorName ?? "Legacy User", style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        dateFormat.format(widget.memory.date),
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Description (Title + Content)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.memory.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (widget.memory.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.memory.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Media (Image/Video)
          if (widget.memory.imageUrls.isNotEmpty && (widget.memory.type == MemoryType.photo || widget.memory.type == MemoryType.video))
            GestureDetector(
              onTap: widget.onTap,
              child: ClipRRect(
                child: widget.memory.type == MemoryType.photo 
                  ? _PostImageGallery(imageUrls: widget.memory.imageUrls, onTap: widget.onTap)
                  : _CommunityVideoPreview(
                      videoPath: widget.memory.imageUrls.first,
                      onTap: widget.onTap,
                    ),
              ),
            ),

          // Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.favorite, size: 14, color: widget.memory.reactionCount > 0 ? Colors.red : theme.colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(width: 4),
                Text(widget.memory.reactionCount.toString(), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                const Spacer(),
                Text("${widget.memory.comments.length} comments", style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Action Buttons (React, Comment)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _toggleReaction,
                    icon: Icon(
                      widget.memory.reactionCount > 0 ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: widget.memory.reactionCount > 0 ? Colors.red : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    label: Text("Love", style: TextStyle(color: widget.memory.reactionCount > 0 ? Colors.red : theme.colorScheme.onSurface.withOpacity(0.6))),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showComments = !_showComments),
                    icon: Icon(Icons.chat_bubble_outline, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    label: Text("Comment", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  ),
                ),
              ],
            ),
          ),

          // Wrapped Comments Section
          if (_showComments) ...[
            const Divider(height: 1),
            Container(
              color: isDark ? Colors.black.withOpacity(0.05) : const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  if (widget.memory.comments.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: widget.memory.comments.length > 3 ? 3 : widget.memory.comments.length,
                      itemBuilder: (context, index) {
                        final comment = widget.memory.comments[index];
                        return _WrappedCommentTile(comment: comment);
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: InkWell(
                      onTap: widget.onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Text("Write a comment...", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 13)),
                            const Spacer(),
                            Icon(Icons.send_rounded, size: 18, color: theme.colorScheme.primary.withOpacity(0.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WrappedCommentTile extends StatelessWidget {
  final Comment comment;
  const _WrappedCommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(Icons.person, size: 14, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2, offset: const Offset(0, 1)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(comment.text, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.8))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final VoidCallback onTap;

  const _PostImageGallery({required this.imageUrls, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (imageUrls.length == 1) {
      return _galleryImage(imageUrls.first, theme, height: 250);
    }

    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              _galleryImage(imageUrls[index], theme, height: 250),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${index + 1}/${imageUrls.length}",
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _galleryImage(String url, ThemeData theme, {required double height}) {
    return url.startsWith('http')
        ? Image.network(
            url,
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _errorPlaceholder(theme, height),
          )
        : Image.file(
            File(url),
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _errorPlaceholder(theme, height),
          );
  }

  Widget _errorPlaceholder(ThemeData theme, double height) {
    return Container(
      height: height,
      color: theme.colorScheme.onSurface.withOpacity(0.05),
      child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurface.withOpacity(0.3)),
    );
  }
}

class _FriendsTab extends StatefulWidget {
  const _FriendsTab();

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? theme.colorScheme.onSurface.withOpacity(0.1) : const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Text("F${index + 1}", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text("Friend ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Online", style: TextStyle(color: Colors.green.shade400, fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_outline, size: 18, color: theme.colorScheme.primary),
            ),
          ),
        );
      },
    );
  }
}

class _GroupsTab extends StatefulWidget {
  const _GroupsTab();

  @override
  State<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<_GroupsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const Center(child: Text("Groups coming soon"));
  }
}

class _CommunityVideoPreview extends StatefulWidget {
  final String videoPath;
  final VoidCallback onTap;
  const _CommunityVideoPreview({required this.videoPath, required this.onTap});

  @override
  State<_CommunityVideoPreview> createState() => _CommunityVideoPreviewState();
}

class _CommunityVideoPreviewState extends State<_CommunityVideoPreview> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.videoPath.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoPath))
        : VideoPlayerController.file(File(widget.videoPath));

    _controller.initialize().then((_) {
      _controller.setLooping(true);
      _controller.setVolume(0); 
      _controller.play();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container(
        height: 250,
        width: double.infinity,
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Container(
      width: double.infinity,
      height: 250, 
      color: Colors.black.withOpacity(0.05),
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      ),
    );
  }
}
