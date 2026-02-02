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
import '../widgets/skeleton_loader.dart';
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
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime? _selectedSearchDate;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isSaving = false;
  
  // Vision Book States
  bool _isBookOpen = false;
  bool _isSearchingBook = false;
  
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
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    await _loadMemories();
    _loadInitialPlan();
    if (mounted) setState(() => _isLoading = false);
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

  void _loadInitialPlan() {
    if (_selectedDay != null) {
      _noteController.text = _storageService.getPlan(_selectedDay!);
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

    final List<Widget> pages = [
      _buildJournalContent(),
      CommunityScreen(isSearching: _isSearching, searchController: _searchController, onThemeChanged: widget.onThemeChanged),
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
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 72,
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
                elevation: 0,
                backgroundColor: Colors.transparent,
                selectedItemColor: theme.colorScheme.primary,
                unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedFontSize: 12,
                unselectedFontSize: 12,
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
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.chat_bubble_outline, size: 22),
                    activeIcon: Icon(Icons.chat_bubble, size: 22),
                    label: 'Chat',
                  ),
                  BottomNavigationBarItem(
                    icon: _CapsuleIcon(isActive: _bottomNavIndex == 3),
                    label: 'Capsule',
                  ),
                ],
              ),
            ),
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
              child: const Icon(Icons.add, size: 24, color: Colors.white),
            )
          : null,
      ),
    );
  }

  Widget _buildJournalContent() {
    final theme = Theme.of(context);
    const hackerPhoto = "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=400&q=80";

    return Column(
      children: [
        // Refined Premium Header Navigation
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            bottom: 10,
            left: 16,
            right: 8,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileViewScreen())),
                child: Hero(
                  tag: 'profile_avatar_header',
                  child: Container(
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
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: _showSearchHeader 
                    ? TextField(
                        key: const ValueKey('searchField'),
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: "Search memories...",
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setState(() {
                              _showSearchHeader = false;
                              _isSearching = false;
                              _searchController.clear();
                              _selectedSearchDate = null;
                            }),
                          ),
                        ),
                        onChanged: (val) => setState(() => _isSearching = val.isNotEmpty || _selectedSearchDate != null),
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          key: const ValueKey('titleText'),
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Journal", 
                              style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                            Text(
                              "Your life's vault",
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.camera_alt_outlined, color: theme.colorScheme.primary, size: 20),
                    onPressed: _openCamera,
                    tooltip: "Quick Capture",
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 22),
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
                      const PopupMenuItem(value: 'search', child: Row(children: [Icon(Icons.search, size: 18), SizedBox(width: 12), Text("Search")])),
                      const PopupMenuItem(value: 'calendar', child: Row(children: [Icon(Icons.calendar_today, size: 18), SizedBox(width: 12), Text("Date Filter")])),
                      const PopupMenuItem(value: 'notifications', child: Row(children: [Icon(Icons.notifications_none, size: 18), SizedBox(width: 12), Text("Alerts")])),
                      const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings_outlined, size: 18), SizedBox(width: 12), Text("Settings")])),
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
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(height: 48, text: "My Memories"),
              Tab(height: 48, text: "Future Plans"),
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
    if (_isLoading) {
      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: 3,
        itemBuilder: (context, index) => const MemorySkeleton(),
      );
    }

    final filteredMemories = _memories.where((memory) {
      final query = _searchController.text.toLowerCase();
      bool matchesTitle = memory.title.toLowerCase().contains(query);
      bool matchesDate = _selectedSearchDate == null || 
          (memory.date.year == _selectedSearchDate!.year && 
           memory.date.month == _selectedSearchDate!.month && 
           memory.date.day == _selectedSearchDate!.day);
      return _isSearching ? (_selectedSearchDate != null ? matchesDate : matchesTitle) : true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadMemories,
      child: filteredMemories.isEmpty && !_isSearching
          ? _buildEmptyJournal(theme)
          : ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (!_isSearching)
                  MemoryCard(
                    key: const ValueKey("demo_video_card"),
                    memory: _demoVideo,
                    onDelete: () {},
                    onToggleLock: () {},
                    onTap: () {},
                    isDemo: true,
                    fullWidth: true,
                  ),
                ...filteredMemories.map((memory) => MemoryCard(
                  key: ValueKey(memory.id),
                  memory: memory,
                  onDelete: () => _deleteMemory(memory.id),
                  onToggleLock: () => _toggleLock(memory.id),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MemoryDetailScreen(memory: memory, onDelete: _deleteMemory, onToggleLock: _toggleLock)));
                  },
                  fullWidth: true,
                )),
              ],
            ),
    );
  }

  Widget _buildEmptyJournal(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Text(
            "Your legacy starts here",
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 8),
          Text(
            "Capture a moment or seal a vision.",
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturePlansTab(ThemeData theme, bool isDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _isSearchingBook 
        ? _buildSearchingBookAnimation(theme)
        : _isBookOpen 
          ? _buildOpenBookUI(theme, isDark)
          : _buildClosedBookUI(theme, isDark),
    );
  }

  Widget _buildClosedBookUI(ThemeData theme, bool isDark) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          setState(() => _isSearchingBook = true);
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() {
              _isSearchingBook = false;
              _isBookOpen = true;
            });
          }
        },
        child: Container(
          width: 300, // Increased Width
          height: 420, // Increased Height
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFF0C4A6E),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
              topLeft: Radius.circular(6),
              bottomLeft: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(15, 15),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Premium Gold Foil Border
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.2), width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Book Spine Detail
              Positioned(
                left: 14,
                top: 24,
                bottom: 24,
                child: Container(
                  width: 3,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 64),
                    const SizedBox(height: 32),
                    const Text(
                      "Vision Board",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontFamily: 'Serif',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "TAP TO OPEN",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
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

  Widget _buildSearchingBookAnimation(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _PageFlipIcon(),
          const SizedBox(height: 32),
          Text(
            "Searching through your visions...",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 18,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenBookUI(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          // Open Book Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Vision Board",
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    Text(
                      "Turn pages, shape future",
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_fullscreen_rounded),
                  onPressed: () => setState(() => _isBookOpen = false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _VisionOptionCard(
                    icon: Icons.edit_note_rounded,
                    title: "Add a Plan",
                    subtitle: "Write down your vision for today",
                    onTap: () {
                      _showAddPlanDialog(theme, isDark);
                    },
                  ),
                  const SizedBox(height: 16),
                  _VisionOptionCard(
                    icon: Icons.menu_book_rounded,
                    title: "View Plans",
                    subtitle: "Browse your journey of visions",
                    onTap: () {
                      _showViewPlansDialog(theme, isDark);
                    },
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      const Icon(Icons.history_edu_rounded, size: 20, color: Colors.blueAccent),
                      const SizedBox(width: 12),
                      Text(
                        "Today's Reflection",
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      _noteController.text.isEmpty 
                        ? "The page is blank. What will you write today?" 
                        : _noteController.text,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.7,
                        fontStyle: _noteController.text.isEmpty ? FontStyle.italic : FontStyle.normal,
                        color: theme.colorScheme.onSurface.withValues(alpha: _noteController.text.isEmpty ? 0.4 : 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPlanDialog(ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Vision", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(DateFormat('EEEE, MMMM d').format(DateTime.now()), style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 24),
            Expanded(
              child: TextField(
                controller: _noteController,
                maxLines: null,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "What do you see for your future today?",
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 18, height: 1.6),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ElevatedButton(
                onPressed: () {
                  _storageService.savePlan(DateTime.now(), _noteController.text);
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text("Seal Today's Vision"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showViewPlansDialog(ThemeData theme, bool isDark) {
    final allPlans = _storageService.getAllPlans();
    final sortedKeys = allPlans.keys.toList()..sort((a, b) => b.compareTo(a));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("All Visions", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: sortedKeys.isEmpty 
                ? Center(child: Text("Your vision book is empty.", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))))
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: sortedKeys.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final key = sortedKeys[index];
                      final plan = allPlans[key]!;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent)),
                            const SizedBox(height: 8),
                            Text(plan, style: const TextStyle(fontSize: 15, height: 1.5)),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _markAchievement(bool success) async {
    await _storageService.saveAchievement(_selectedDay!, success);
    if (!mounted) return;
    setState(() {});
    final status = success ? "Legacy Milestone Achieved! 🎉" : "The path is long. Keep moving forward. 💪";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: success ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _VisionOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _VisionOptionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }
}

class _PageFlipIcon extends StatefulWidget {
  const _PageFlipIcon();

  @override
  State<_PageFlipIcon> createState() => _PageFlipIconState();
}

class _PageFlipIconState extends State<_PageFlipIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_controller.value * 3.14),
          alignment: Alignment.center,
          child: const Icon(Icons.menu_book_rounded, size: 100, color: Colors.blueAccent), // Increased Size
        );
      },
    );
  }
}

class _CapsuleIcon extends StatelessWidget {
  final bool isActive;
  const _CapsuleIcon({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (isActive)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1 * value),
                  shape: BoxShape.circle,
                ),
              ),
            Transform.scale(
              scale: 1.0 + (0.1 * value),
              child: Icon(
                isActive ? Icons.lock_clock : Icons.lock_clock_outlined,
                size: 20,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedGlowIcon extends StatelessWidget {
  final Color color;
  const _AnimatedGlowIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.2 * value), blurRadius: 15 * value, spreadRadius: 2 * value)
            ],
          ),
          child: Icon(Icons.auto_awesome, color: color, size: 24),
        );
      },
    );
  }
}

class _ModernAchievementButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback onPressed;

  const _ModernAchievementButton({required this.label, required this.icon, required this.color, required this.isActive, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.white : color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20)] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isActive ? Colors.black : color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? Colors.black : color, fontWeight: FontWeight.w900, fontSize: 14)),
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
  final bool isDemo;
  final bool fullWidth;

  const MemoryCard({
    super.key,
    required this.memory,
    required this.onTap,
    required this.onDelete,
    required this.onToggleLock,
    this.isDemo = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasMedia = memory.imageUrls.isNotEmpty && (memory.type == MemoryType.video || memory.type == MemoryType.photo);
    
    return Container(
      margin: EdgeInsets.only(bottom: fullWidth ? 0 : 16, left: fullWidth ? 0 : 16, right: fullWidth ? 0 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: fullWidth ? BorderRadius.zero : BorderRadius.circular(16),
        border: Border(
          bottom: BorderSide(
            color: isDark ? theme.colorScheme.onSurface.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
        boxShadow: fullWidth ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                if (isDemo) ...[
                  CircleAvatar(radius: 12, backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1), child: Icon(Icons.star, size: 14, color: theme.colorScheme.primary)),
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
              padding: EdgeInsets.symmetric(horizontal: fullWidth ? 0 : 16, vertical: 8),
              child: ClipRRect(
                borderRadius: fullWidth ? BorderRadius.zero : BorderRadius.circular(12),
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
                      VideoProgressIndicator(_controller, allowScrubbing: true, colors: VideoProgressColors(playedColor: Theme.of(context).colorScheme.primary)),
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
