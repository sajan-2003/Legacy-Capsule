import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../models/memory.dart';
import '../services/storage_service.dart';
import 'add_memory_screen.dart';
import 'profile_screen.dart';
import 'memory_detail_screen.dart';
import 'time_lock_screen.dart';
import 'notifications_screen.dart';
import 'community_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final ThemeMode currentThemeMode;

  const HomeScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 0;
  final ImagePicker _picker = ImagePicker();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime? _selectedSearchDate;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  final StorageService _storageService = StorageService();
  List<Memory> _memories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    final memories = _storageService.getLocalMemories();
    setState(() {
      _memories = memories;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addMemory(Memory memory) async {
    await _storageService.saveMemoryLocally(memory);
    _loadMemories();
  }

  Future<void> _deleteMemory(String id) async {
    await _storageService.deleteLocalMemory(id);
    _loadMemories();
  }

  Future<void> _toggleLock(String id) async {
    final index = _memories.indexWhere((m) => m.id == id);
    if (index != -1) {
      final m = _memories[index];
      final updatedMemory = Memory(
        id: m.id,
        date: m.date,
        title: m.title,
        preview: m.preview,
        type: m.type,
        content: m.content,
        imageUrl: m.imageUrl,
        isLocked: !m.isLocked,
        reactionCount: m.reactionCount,
        comments: m.comments,
      );
      await _storageService.saveMemoryLocally(updatedMemory);
      _loadMemories();
    }
  }

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null && mounted) {
        final newMemory = Memory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: DateTime.now(),
          title: "Camera Capture",
          preview: "Photo taken on ${DateFormat('MMM d').format(DateTime.now())}",
          type: MemoryType.photo,
          content: "Captured via camera.",
          imageUrl: photo.path,
        );
        _addMemory(newMemory);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accessing camera: $e')),
        );
      }
    }
  }

  Future<void> _selectSearchDate() async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedSearchDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onSurface: theme.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedSearchDate = picked;
        _isSearching = true;
        _searchController.text = DateFormat('MMM d, yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Widget> pages = [
      _buildJournalContent(),
      CommunityScreen(isSearching: _isSearching, searchController: _searchController, onThemeChanged: widget.onThemeChanged),
      TimeLockScreen(isSearching: _isSearching, searchController: _searchController, onThemeChanged: widget.onThemeChanged),
      const NotificationsScreen(),
    ];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        body: pages[_bottomNavIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: _bottomNavIndex,
            onTap: (index) {
              setState(() {
                _bottomNavIndex = index;
                _isSearching = false;
                _searchController.clear();
                _selectedSearchDate = null;
              });
            },
            backgroundColor: theme.colorScheme.surface,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_stories_outlined),
                activeIcon: Icon(Icons.auto_stories),
                label: 'Journal',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.lock_clock_outlined),
                activeIcon: Icon(Icons.lock_clock),
                label: 'Capsules',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  label: Text('1'),
                  child: Icon(Icons.notifications_outlined),
                ),
                activeIcon: Icon(Icons.notifications),
                label: 'Notifications',
              ),
            ],
          ),
        ),
        floatingActionButton: (_bottomNavIndex == 0 && MediaQuery.of(context).viewInsets.bottom == 0)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddMemoryScreen(onSave: _addMemory),
                  ),
                );
              },
              backgroundColor: theme.colorScheme.primary,
              elevation: 4,
              child: const Icon(Icons.add, size: 28, color: Colors.white),
            )
          : null,
      ),
    );
  }

  Widget _buildJournalContent() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 8,
            left: 24,
            right: 12,
          ),
          decoration: BoxDecoration(color: theme.colorScheme.surface),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Journal", style: theme.textTheme.titleLarge?.copyWith(fontSize: 24)),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.camera_alt_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    onPressed: _openCamera,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(
                            onThemeChanged: widget.onThemeChanged,
                            currentThemeMode: widget.currentThemeMode,
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.person, color: theme.colorScheme.primary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? theme.colorScheme.onSurface.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.more_vert,
                        color: isDark ? theme.colorScheme.onSurface.withValues(alpha: 0.7) : const Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    color: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (value) {
                      if (value == 'theme') widget.onThemeChanged(!isDark);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'theme',
                        child: Row(
                          children: [
                            Icon(isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round, size: 20, color: isDark ? Colors.amber : const Color(0xFF475569)),
                            const SizedBox(width: 12),
                            Text(isDark ? "Day Mode" : "Night Mode", style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Tab Bar
        Container(
          color: theme.colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "My Memories"),
              Tab(text: "Future Plans"),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMemoriesTab(theme, isDark),
              _buildFuturePlansTab(theme, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemoriesTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _buildBodyActionBar(theme, isDark),
        const SizedBox(height: 16),
        if (_memories.isEmpty)
          _buildEmptyState()
        else
          ..._memories.where((memory) {
            bool matchesTitle = memory.title.toLowerCase().contains(_searchController.text.toLowerCase());
            bool matchesDate = _selectedSearchDate == null || 
                (memory.date.year == _selectedSearchDate!.year && 
                 memory.date.month == _selectedSearchDate!.month && 
                 memory.date.day == _selectedSearchDate!.day);
            return !(_isSearching && !(matchesTitle && matchesDate));
          }).map((memory) => MemoryCard(
            memory: memory,
            onDelete: () => _deleteMemory(memory.id),
            onToggleLock: () => _toggleLock(memory.id),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MemoryDetailScreen(
                    memory: memory,
                    onDelete: _deleteMemory,
                    onToggleLock: _toggleLock,
                  ),
                ),
              );
            },
          )),
      ],
    );
  }

  Widget _buildFuturePlansTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Styled Calendar View
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: CalendarDatePicker(
              initialDate: _focusedDay,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              onDateChanged: (date) {
                setState(() {
                  _selectedDay = date;
                  _focusedDay = date;
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Notepad
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Notes for ${DateFormat('MMM d').format(_selectedDay!)}",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.save_outlined, color: theme.colorScheme.primary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Note saved locally.")));
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEFCE8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? theme.dividerColor : const Color(0xFFFEF08A)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: TextField(
              controller: _noteController,
              maxLines: 12,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontFamily: 'Courier',
                fontSize: 16,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: "Start typing your plans or thoughts...",
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBodyActionBar(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48, // Increased height for a bigger bar
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Search memories...",
                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      suffixIcon: _selectedSearchDate != null 
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16), 
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() {
                              _selectedSearchDate = null;
                              _searchController.clear();
                              _isSearching = false;
                            })
                          ) 
                        : null,
                    ),
                    onChanged: (val) => setState(() => _isSearching = val.isNotEmpty || _selectedSearchDate != null),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_month_outlined, size: 20, color: theme.colorScheme.primary),
                  onPressed: _selectSearchDate,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: theme.dividerColor),
              ),
              child: Icon(
                Icons.description_outlined,
                size: 40,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Your story starts here.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MemoryCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleLock;

  const MemoryCard({
    super.key,
    required this.memory,
    required this.onTap,
    required this.onDelete,
    required this.onToggleLock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy');

    IconData typeIcon;
    switch (memory.type) {
      case MemoryType.text:
        typeIcon = Icons.description_outlined;
        break;
      case MemoryType.photo:
        typeIcon = Icons.image_outlined;
        break;
      case MemoryType.video:
        typeIcon = Icons.videocam_outlined;
        break;
      case MemoryType.audio:
        typeIcon = Icons.mic_none_outlined;
        break;
    }

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
                        Text(
                          dateFormat.format(memory.date),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(typeIcon, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        if (memory.isLocked) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.lock, size: 18, color: Color(0xFFB45309)),
                        ],
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.more_vert, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                          ),
                          color: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onSelected: (value) {
                            if (value == 'delete') onDelete();
                            if (value == 'lock') onToggleLock();
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'lock',
                              child: Row(
                                children: [
                                  Icon(Icons.lock_outline, size: 18, color: Colors.black),
                                  SizedBox(width: 12),
                                  Text("Lock/Unlock"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                  SizedBox(width: 12),
                                  Text("Delete", style: TextStyle(color: Colors.redAccent)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (memory.imageUrl != null && (memory.type == MemoryType.photo || memory.type == MemoryType.video)) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: memory.type == MemoryType.photo 
                          ? (memory.imageUrl!.startsWith('http') 
                              ? Image.network(
                                  memory.imageUrl!,
                                  width: double.infinity,
                                  height: 200, // Uniform height
                                  fit: BoxFit.cover, // Crop to fit
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 200,
                                    color: isDark ? theme.colorScheme.onSurface.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                                    child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                                  ),
                                )
                              : Image.file(
                                  File(memory.imageUrl!),
                                  width: double.infinity,
                                  height: 200, // Uniform height
                                  fit: BoxFit.cover, // Crop to fit
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 200,
                                    color: isDark ? theme.colorScheme.onSurface.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                                    child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                                  ),
                                ))
                          : VideoGifPreview(videoPath: memory.imageUrl!),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      memory.title,
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      memory.preview,
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

class VideoGifPreview extends StatefulWidget {
  final String videoPath;
  const VideoGifPreview({super.key, required this.videoPath});

  @override
  State<VideoGifPreview> createState() => _VideoGifPreviewState();
}

class _VideoGifPreviewState extends State<VideoGifPreview> {
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
          height: 200, // Fixed height for uniformity
          color: Colors.black.withOpacity(0.05),
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.cover, // Crop to fit the container
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
