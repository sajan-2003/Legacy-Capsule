import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/memory.dart';
import '../services/storage_service.dart';
import 'add_memory_screen.dart';
import 'profile_view_screen.dart';
import 'profile_screen.dart';
import 'memory_detail_screen.dart';
import 'time_lock_screen.dart';
import 'notifications_screen.dart';
import 'community_screen.dart';
import 'chat_list_screen.dart';

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
  bool _showSearchHeader = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime? _selectedSearchDate;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  final StorageService _storageService = StorageService();
  List<Memory> _memories = [];
  final Memory _demoVideo = Memory(
    id: "demo_video_constant",
    date: DateTime.now(),
    title: "Journal Demo: Discover Your Legacy",
    preview: "Experience how Legacy Capsule preserves your story with immersive video memories.",
    type: MemoryType.video,
    content: "This is a demo of our community-style video player inside your journal. It plays automatically when you focus on it and stops when you scroll away.",
    imageUrls: ["https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4"],
    isLocked: false,
    authorName: "Legacy Team",
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    try {
      final memories = _storageService.getLocalMemories();
      setState(() {
        _memories = memories;
      });
    } catch (e) {
      debugPrint("Error loading memories: $e");
    }
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
        imageUrls: m.imageUrls,
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
          content: "",
          imageUrls: [photo.path],
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddMemoryScreen(
              onSave: _addMemory,
              initialMemory: newMemory,
            ),
          ),
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
    const hackerPhoto = "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=400&q=80";

    final List<Widget> pages = [
      _buildJournalContent(),
      CommunityScreen(isSearching: _isSearching, searchController: _searchController, onThemeChanged: widget.onThemeChanged),
      const ProfileViewScreen(),
      const ChatListScreen(),
      TimeLockScreen(isSearching: _isSearching, searchController: _searchController, onThemeChanged: widget.onThemeChanged),
    ];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        body: IndexedStack(
          index: _bottomNavIndex,
          children: pages,
        ),
        bottomNavigationBar: Container(
          height: 72, 
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
          ),
          child: BottomNavigationBar(
            currentIndex: _bottomNavIndex,
            onTap: (index) {
              setState(() {
                _bottomNavIndex = index;
                _isSearching = false;
                _showSearchHeader = false;
                _searchController.clear();
                _selectedSearchDate = null;
              });
            },
            backgroundColor: theme.colorScheme.surface,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.auto_stories_outlined, size: 20),
                activeIcon: Icon(Icons.auto_stories, size: 20),
                label: 'Journal',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.public_outlined, size: 24),
                activeIcon: Icon(Icons.public, size: 24),
                label: 'Social',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: const NetworkImage(hackerPhoto),
                  ),
                ),
                label: 'Profile',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline, size: 24),
                activeIcon: Icon(Icons.chat_bubble, size: 24),
                label: 'Chat',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.lock_clock_outlined, size: 20),
                activeIcon: Icon(Icons.lock_clock, size: 20),
                label: 'Capsule',
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
              mini: true,
              backgroundColor: theme.colorScheme.primary,
              elevation: 4,
              child: const Icon(Icons.add, size: 24, color: Colors.white),
            )
          : null,
      ),
    );
  }

  Widget _buildJournalContent() {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            bottom: 12,
            left: 20,
            right: 12,
          ),
          decoration: BoxDecoration(color: theme.colorScheme.surface),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _showSearchHeader 
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "Search memories...",
                        border: InputBorder.none,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.calendar_today, size: 18),
                              onPressed: _selectSearchDate,
                              tooltip: "Filter by date",
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() {
                                _showSearchHeader = false;
                                _isSearching = false;
                                _searchController.clear();
                                _selectedSearchDate = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                      onChanged: (val) => setState(() => _isSearching = val.isNotEmpty || _selectedSearchDate != null),
                    )
                  : Text("Journal", style: theme.textTheme.titleLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.camera_alt_outlined, color: theme.colorScheme.primary, size: 20),
                      onPressed: _openCamera,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: theme.colorScheme.primary, size: 24),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'settings') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(onThemeChanged: widget.onThemeChanged, currentThemeMode: widget.currentThemeMode)));
                      } else if (value == 'notifications') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                      } else if (value == 'search') {
                        setState(() => _showSearchHeader = true);
                      } else if (value == 'calendar') {
                        _selectSearchDate();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'search', child: Row(children: [Icon(Icons.search, size: 18), SizedBox(width: 8), Text("Search")])),
                      const PopupMenuItem(value: 'calendar', child: Row(children: [Icon(Icons.calendar_today, size: 18), SizedBox(width: 8), Text("Filter by Date")])),
                      const PopupMenuItem(value: 'notifications', child: Row(children: [Icon(Icons.notifications_none, size: 18), SizedBox(width: 8), Text("Alerts")])),
                      const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings_outlined, size: 18), SizedBox(width: 8), Text("Settings")])),
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
            indicatorWeight: 2,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(height: 36, text: "My Memories"),
              Tab(height: 36, text: "Future Plans"),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMemoriesTab(theme, theme.brightness == Brightness.dark),
              _buildFuturePlansTab(theme, theme.brightness == Brightness.dark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemoriesTab(ThemeData theme, bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadMemories,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          MemoryCard(
            key: const ValueKey("demo_video_card"),
            memory: _demoVideo,
            onDelete: () {},
            onToggleLock: () {},
            onTap: () {},
            isDemo: true,
          ),
          ..._memories.where((memory) {
            final query = _searchController.text.toLowerCase();
            bool matchesTitle = memory.title.toLowerCase().contains(query);
            bool matchesDate = _selectedSearchDate == null || 
                (memory.date.year == _selectedSearchDate!.year && 
                 memory.date.month == _selectedSearchDate!.month && 
                 memory.date.day == _selectedSearchDate!.day);
            return _isSearching ? (_selectedSearchDate != null ? matchesDate : matchesTitle) : true;
          }).map((memory) => MemoryCard(
            key: ValueKey(memory.id),
            memory: memory,
            onDelete: () => _deleteMemory(memory.id),
            onToggleLock: () => _toggleLock(memory.id),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => MemoryDetailScreen(memory: memory, onDelete: _deleteMemory, onToggleLock: _toggleLock)));
            },
          )),
        ],
      ),
    );
  }

  Widget _buildFuturePlansTab(ThemeData theme, bool isDark) {
    final luminousColors = [
      Colors.cyanAccent,
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.greenAccent,
      Colors.yellowAccent,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark ? [Colors.indigo.shade900, Colors.black] : [Colors.indigo.shade50, Colors.white],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.1), blurRadius: 30)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLuminousStat("Day", DateFormat('EEE').format(_selectedDay!), luminousColors[0], isDark),
                _buildLuminousStat("Month", DateFormat('MMM').format(_selectedDay!), luminousColors[1], isDark),
                _buildLuminousStat("Year", DateFormat('yyyy').format(_selectedDay!), luminousColors[2], isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(luminousColors.length, (index) => Container(
                    width: 14, height: 4, margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: luminousColors[index],
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [BoxShadow(color: luminousColors[index], blurRadius: 6)],
                    ),
                  )),
                ),
                const SizedBox(height: 12),
                Theme(
                  data: theme.copyWith(
                    colorScheme: theme.colorScheme.copyWith(
                      primary: theme.colorScheme.primary,
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: _focusedDay,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    onDateChanged: (date) => setState(() { _selectedDay = date; _focusedDay = date; }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFEFCE8),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.05), blurRadius: 15)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: luminousColors[1].withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(Icons.auto_awesome, color: luminousColors[1], size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Vision Board", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          Text(DateFormat('MMMM d, yyyy').format(_selectedDay!), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    TextField(
                      controller: _noteController,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                      decoration: InputDecoration(
                        hintText: "What are your future visions...",
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    Positioned(bottom: 8, right: 8, child: Icon(Icons.edit_outlined, size: 18, color: theme.colorScheme.primary.withValues(alpha: 0.3))),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPlanFeature(Icons.lock_clock, "Memories Locked", "2 Capsules waiting", luminousColors[0]),
                const Divider(height: 24, thickness: 0.5),
                _buildPlanFeature(Icons.alarm, "Daily Intent", "Stay mindful and focused", luminousColors[3]),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLuminousStat(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color, shadows: [Shadow(color: color, blurRadius: 10)])),
        ),
      ],
    );
  }

  Widget _buildPlanFeature(IconData icon, String title, String subtitle, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.chevron_right, size: 14, color: color),
        ),
      ],
    );
  }
}

class MemoryCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleLock;
  final bool isDemo;

  const MemoryCard({
    super.key,
    required this.memory,
    required this.onTap,
    required this.onDelete,
    required this.onToggleLock,
    this.isDemo = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasMedia = memory.imageUrls.isNotEmpty && (memory.type == MemoryType.video || memory.type == MemoryType.photo);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? theme.colorScheme.onSurface.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                if (isDemo) ...[
                  CircleAvatar(radius: 12, backgroundColor: theme.colorScheme.primary.withAlpha(20), child: Icon(Icons.star, size: 14, color: theme.colorScheme.primary)),
                  const SizedBox(width: 8),
                  Text("Legacy Community", style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  const Spacer(),
                ] else ...[
                  Text(DateFormat('MMM d, yyyy').format(memory.date), style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                  const Spacer(),
                ],
                if (!isDemo)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (v) => v == 'delete' ? onDelete() : onToggleLock(),
                    itemBuilder: (c) => [const PopupMenuItem(value: 'lock', child: Text("Lock")), const PopupMenuItem(value: 'delete', child: Text("Delete"))],
                  ),
              ],
            ),
          ),
          if (hasMedia)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: memory.type == MemoryType.video 
                  ? _FullControlVideoPlayer(videoPath: memory.imageUrls.first, onTap: onTap)
                  : GestureDetector(
                      onTap: onTap,
                      child: CachedNetworkImage(
                        imageUrl: memory.imageUrls.first, 
                        height: 200, 
                        width: double.infinity, 
                        fit: BoxFit.cover, 
                        errorWidget: (c, u, e) => Container(color: Colors.grey[200]),
                      ),
                    ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, hasMedia ? 4 : 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(memory.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Text(memory.preview, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullControlVideoPlayer extends StatefulWidget {
  final String videoPath;
  final VoidCallback onTap;
  const _FullControlVideoPlayer({required this.videoPath, required this.onTap});

  @override
  State<_FullControlVideoPlayer> createState() => _FullControlVideoPlayerState();
}

class _FullControlVideoPlayerState extends State<_FullControlVideoPlayer> {
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
    try {
      if (widget.videoPath.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      } else {
        _controller = VideoPlayerController.file(File(widget.videoPath));
      }
      await _controller.initialize();
      _controller.setLooping(true);
      if (mounted) setState(() => _isInitialized = true);
      _startHideTimer();
    } catch (e) { 
      debugPrint("Video error: $e");
      if (mounted) setState(() => _isInitialized = false);
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () { if (mounted) setState(() => _showControls = false); });
  }

  @override
  void dispose() { _hideTimer?.cancel(); _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return Container(height: 200, color: Colors.black12, child: const Center(child: Icon(Icons.error_outline, color: Colors.white, size: 30)));
    return VisibilityDetector(
      key: Key(widget.videoPath),
      onVisibilityChanged: (info) {
        if (!mounted || !_isInitialized) return;
        if (info.visibleFraction > 0.9 && !_controller.value.isPlaying) {
          _controller.play();
        } else if (info.visibleFraction < 0.6 && _controller.value.isPlaying) {
          _controller.pause();
        }
      },
      child: GestureDetector(
        onTap: () { setState(() { _showControls = !_showControls; if (_showControls) _startHideTimer(); }); },
        child: Container(
          width: double.infinity,
          height: 200,
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller)),
              if (_showControls)
                Container(
                  color: Colors.black26,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(alignment: Alignment.topRight, child: IconButton(icon: Icon(_controller.value.volume > 0 ? Icons.volume_up : Icons.volume_off, color: Colors.white, size: 18), onPressed: () { setState(() => _controller.setVolume(_controller.value.volume > 0 ? 0 : 1)); _startHideTimer(); })),
                      IconButton(iconSize: 40, icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white), onPressed: () { setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()); _startHideTimer(); }),
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
