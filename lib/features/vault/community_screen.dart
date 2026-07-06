import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/memory.dart';
import '../../services/storage_service.dart';
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

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _headerSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        toolbarHeight: 56,
        title: _headerSearching
            ? TextField(
                controller: widget.searchController,
                autofocus: true,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Search community...",
                  hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(102)),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() {}),
              )
            : Text("Community",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          IconButton(
            icon: Icon(_headerSearching ? Icons.close : Icons.search,
                color: theme.colorScheme.onSurface.withAlpha(153), size: 22),
            onPressed: () => setState(() {
              _headerSearching = !_headerSearching;
              if (!_headerSearching) widget.searchController.clear();
            }),
          ),
          IconButton(
            icon: Icon(Icons.camera_alt_outlined,
                color: theme.colorScheme.onSurface.withAlpha(153), size: 22),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(127),
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 2,
          labelPadding: EdgeInsets.zero,
          tabs: const [
            Tab(height: 48, text: "Explore"),
            Tab(height: 48, text: "Friends"),
            Tab(height: 48, text: "Groups"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ExploreTab(searchController: widget.searchController),
          const _FriendsTab(),
          const _GroupsTab(),
        ],
      ),
    );
  }
}

class _ExploreTab extends StatefulWidget {
  final TextEditingController searchController;
  const _ExploreTab({required this.searchController});

  @override
  State<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<_ExploreTab>
    with AutomaticKeepAliveClientMixin {
  final StorageService _storageService = StorageService();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: StreamBuilder<List<Memory>>(
          stream: Stream.fromFuture(_storageService.getCommunityMemories()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final posts = snapshot.data ?? [];
            if (posts.isEmpty) {
              return Center(
                  child: Text("No posts yet.",
                      style: TextStyle(
                          color: theme.colorScheme.onSurface.withAlpha(127))));
            }

            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final memory = posts[index];
                final query = widget.searchController.text.toLowerCase();
                if (query.isNotEmpty &&
                    !memory.title.toLowerCase().contains(query)) {
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
          }),
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
    await _storageService.updateReaction(
        widget.memory.id, widget.memory.reactionCount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? theme.colorScheme.onSurface.withAlpha(25) : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary.withAlpha(25),
                  child: Icon(Icons.person,
                      color: theme.colorScheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.memory.authorName ?? "Legacy User",
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        dateFormat.format(widget.memory.date),
                        style: TextStyle(
                            color: theme.colorScheme.onSurface.withAlpha(102),
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz,
                      color: theme.colorScheme.onSurface.withAlpha(102), size: 18),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.memory.title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (widget.memory.content.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.memory.content,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(204),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Media
          if (widget.memory.imageUrls.isNotEmpty &&
              (widget.memory.type == MemoryType.photo ||
                  widget.memory.type == MemoryType.video))
            ClipRRect(
              child: widget.memory.type == MemoryType.photo
                  ? _PostImageGallery(
                      imageUrls: widget.memory.imageUrls, onTap: widget.onTap)
                  : _CommunityFullControlVideoPlayer(
                      videoPath: widget.memory.imageUrls.first,
                      onTap: widget.onTap,
                    ),
            ),

          // Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.favorite,
                    size: 12,
                    color: widget.memory.reactionCount > 0
                        ? Colors.red
                        : theme.colorScheme.onSurface.withAlpha(77)),
                const SizedBox(width: 4),
                Text(widget.memory.reactionCount.toString(),
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withAlpha(127))),
                const Spacer(),
                Text("${widget.memory.comments.length} comments",
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withAlpha(127))),
              ],
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _toggleReaction,
                    icon: Icon(
                      widget.memory.reactionCount > 0
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 18,
                      color: widget.memory.reactionCount > 0
                          ? Colors.red
                          : theme.colorScheme.onSurface.withAlpha(153),
                    ),
                    label: Text("Love",
                        style: TextStyle(
                            fontSize: 13,
                            color: widget.memory.reactionCount > 0
                                ? Colors.red
                                : theme.colorScheme.onSurface.withAlpha(153))),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _showComments = !_showComments),
                    icon: Icon(Icons.chat_bubble_outline,
                        size: 18,
                        color: theme.colorScheme.onSurface.withAlpha(153)),
                    label: Text("Comment",
                        style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withAlpha(153))),
                  ),
                ),
              ],
            ),
          ),

          if (_showComments) ...[
            const Divider(height: 1),
            Container(
              color:
                  isDark ? Colors.black.withAlpha(13) : const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  if (widget.memory.comments.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(8),
                      itemCount: widget.memory.comments.length > 2
                          ? 2
                          : widget.memory.comments.length,
                      itemBuilder: (context, index) {
                        final comment = widget.memory.comments[index];
                        return _WrappedCommentTile(comment: comment);
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: InkWell(
                      onTap: widget.onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Text("Write a comment...",
                                style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(102),
                                    fontSize: 12)),
                            const Spacer(),
                            Icon(Icons.send_rounded,
                                size: 16,
                                color:
                                    theme.colorScheme.primary.withAlpha(127)),
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primary.withAlpha(25),
            child:
                Icon(Icons.person, size: 12, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comment.userName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 11)),
                  Text(comment.text,
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withAlpha(204))),
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
    final isDark = theme.brightness == Brightness.dark;

    if (imageUrls.length == 1) {
      return _galleryImage(imageUrls.first, theme, isDark, height: 220);
    }

    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              _galleryImage(imageUrls[index], theme, isDark, height: 220),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${index + 1}/${imageUrls.length}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _galleryImage(String url, ThemeData theme, bool isDark, {required double height}) {
    return url.startsWith('http')
        ? CachedNetworkImage(
            imageUrl: url,
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.black12),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image),
          )
        : Image.file(
            File(url),
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
          );
  }
}

class _FriendsTab extends StatefulWidget {
  const _FriendsTab();

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: isDark ? theme.colorScheme.onSurface.withAlpha(25) : const Color(0xFFF1F5F9),
                width: 1,
              ),
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary.withAlpha(25),
              child: Text("${index + 1}",
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ),
            title: Text("Friend ${index + 1}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("Online",
                style: TextStyle(color: Colors.green.shade400, fontSize: 11)),
            trailing: Icon(Icons.chat_bubble_outline,
                size: 16, color: theme.colorScheme.primary),
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

class _GroupsTabState extends State<_GroupsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const Center(child: Text("Groups coming soon"));
  }
}

class _CommunityFullControlVideoPlayer extends StatefulWidget {
  final String videoPath;
  final VoidCallback onTap;
  const _CommunityFullControlVideoPlayer({required this.videoPath, required this.onTap});

  @override
  State<_CommunityFullControlVideoPlayer> createState() => _CommunityFullControlVideoPlayerState();
}

class _CommunityFullControlVideoPlayerState extends State<_CommunityFullControlVideoPlayer> {
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
        setState(() => _isInitialized = true);
        _startHideTimer();
      }
    } catch (e) {
      debugPrint("Community video init error: $e");
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
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
      return Container(height: 220, width: double.infinity, color: Colors.black12, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    return VisibilityDetector(
      key: Key(widget.videoPath),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        if (info.visibleFraction > 0.8 && !_controller.value.isPlaying) {
          _controller.play();
        } else if (info.visibleFraction < 0.2 && _controller.value.isPlaying) {
          _controller.pause();
        }
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
            if (_showControls) _startHideTimer();
          });
        },
        child: Container(
          width: double.infinity,
          height: 220,
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(child: AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))),
              if (_showControls)
                Container(
                  color: Colors.black26,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: Icon(_controller.value.volume > 0 ? Icons.volume_up : Icons.volume_off, color: Colors.white, size: 18),
                          onPressed: () {
                            setState(() => _controller.setVolume(_controller.value.volume > 0 ? 0 : 1));
                            _startHideTimer();
                          },
                        ),
                      ),
                      IconButton(
                        iconSize: 40,
                        icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white),
                        onPressed: () {
                          setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play());
                          _startHideTimer();
                        },
                      ),
                      VideoProgressIndicator(_controller, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.blueAccent)),
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
