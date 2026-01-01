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
  DateTime? _selectedSearchDate;
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
    final isDark = theme.brightness == Brightness.dark;

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
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
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
            icon: Icon(_headerSearching ? Icons.close : Icons.search, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            onPressed: () => setState(() {
              _headerSearching = !_headerSearching;
              if (!_headerSearching) {
                widget.searchController.clear();
                _selectedSearchDate = null;
              }
            }),
          ),
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round, color: isDark ? Colors.amber : Colors.blueGrey),
            onPressed: () => widget.onThemeChanged(!isDark),
          ),
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            onPressed: _openCamera,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
            return Center(child: Text("No posts yet. Be the first to share!", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

class _PostCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  const _PostCard({super.key, required this.memory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? theme.colorScheme.onSurface.withValues(alpha: 0.1) : const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.person, color: theme.colorScheme.primary, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(memory.authorName ?? "Legacy User", style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              dateFormat.format(memory.date),
                              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (memory.imageUrl != null && (memory.type == MemoryType.photo || memory.type == MemoryType.video)) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: memory.type == MemoryType.photo 
                          ? (memory.imageUrl!.startsWith('http') 
                              ? Image.network(
                                  memory.imageUrl!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 200,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                    child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                                  ),
                                )
                              : Image.file(
                                  File(memory.imageUrl!),
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 200,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                    child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                                  ),
                                ))
                          : _CommunityVideoPreview(videoPath: memory.imageUrl!),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      memory.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (memory.content.isNotEmpty)
                      Text(
                        memory.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
            border: Border.all(color: isDark ? theme.colorScheme.onSurface.withValues(alpha: 0.1) : const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Text("F${index + 1}", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text("Friend ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Online", style: TextStyle(color: Colors.green.shade400, fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
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
  const _CommunityVideoPreview({required this.videoPath});

  @override
  State<_CommunityVideoPreview> createState() => _CommunityVideoPreviewState();
}

class _CommunityVideoPreviewState extends State<_CommunityVideoPreview> {
  late VideoPlayerController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.videoPath.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoPath))
        : VideoPlayerController.file(File(widget.videoPath));

    _controller.initialize().then((_) {
      _controller.setLooping(true);
      _controller.setVolume(0); 
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovering) {
    if (!_controller.value.isInitialized) return;
    setState(() {
      _isHovered = isHovering;
    });
    if (isHovering) {
      _controller.play();
    } else {
      _controller.pause();
      _controller.seekTo(Duration.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTapDown: (_) => _handleHover(true),
        onTapUp: (_) => _handleHover(false),
        onTapCancel: () => _handleHover(false),
        child: Container(
          width: double.infinity,
          height: 200, 
          color: Colors.black.withOpacity(0.05),
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    if (!_isHovered)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
