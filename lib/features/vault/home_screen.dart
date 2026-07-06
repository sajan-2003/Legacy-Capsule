import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/memory.dart';
import '../../services/storage_service.dart';
import '../../widgets/skeleton_loader.dart';
import 'add_memory_screen.dart';
import '../profile/profile_view_screen.dart';
import '../profile/profile_screen.dart';
import 'memory_detail_screen.dart';
import 'time_lock_screen.dart';
import 'notifications_screen.dart';
import 'community_screen.dart';
import '../chat/chat_list_screen.dart';

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
                          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Journal", style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                            Text("Your life's vault", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w500)),
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
          Text("Your legacy starts here", style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          Text("Capture a moment or seal a vision.", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
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

    final currentMarkColor = Color(_storageService.getCalendarColor(_selectedDay!) ?? luminousColors[1].toARGB32());

    return Container(
      decoration: isDark ? const BoxDecoration(
        color: Color(0xFF030213),
        image: DecorationImage(
          image: NetworkImage("https://www.transparenttextures.com/patterns/grid-me.png"),
          repeat: ImageRepeat.repeat,
          opacity: 0.05,
        ),
      ) : null,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPremiumHeader(luminousColors, isDark),
            const SizedBox(height: 20),
            
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF030213).withValues(alpha: 0.8) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 15))
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(luminousColors.length, (index) => GestureDetector(
                          onTap: () {
                            _storageService.saveCalendarColor(_selectedDay!, luminousColors[index].toARGB32());
                            setState(() {}); 
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.elasticOut,
                            width: _storageService.getCalendarColor(_selectedDay!) == luminousColors[index].toARGB32() ? 32 : 24,
                            height: _storageService.getCalendarColor(_selectedDay!) == luminousColors[index].toARGB32() ? 32 : 24,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: luminousColors[index],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _storageService.getCalendarColor(_selectedDay!) == luminousColors[index].toARGB32()
                                  ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: luminousColors[index].withValues(alpha: 0.6), 
                                  blurRadius: _storageService.getCalendarColor(_selectedDay!) == luminousColors[index].toARGB32() ? 15 : 5,
                                  spreadRadius: _storageService.getCalendarColor(_selectedDay!) == luminousColors[index].toARGB32() ? 2 : 0,
                                )
                              ],
                            ),
                          ),
                        )),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.refresh, size: 20, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                          onPressed: () {
                            _storageService.saveCalendarColor(_selectedDay!, 0);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  _MarkableCalendar(
                    storageService: _storageService,
                    selectedDay: _selectedDay!,
                    onDateChanged: (date) {
                      setState(() { 
                        _selectedDay = date; 
                        _focusedDay = date;
                        _noteController.text = _storageService.getPlan(date);
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF030213).withValues(alpha: 0.8) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: currentMarkColor.withValues(alpha: 0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(color: currentMarkColor.withValues(alpha: 0.05), blurRadius: 30, spreadRadius: 5)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _AnimatedGlowIcon(color: currentMarkColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Vision Board", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 0.5)),
                            Text(DateFormat('EEEE, MMMM d').format(_selectedDay!), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _noteController,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w500),
                    onChanged: (val) {
                      _storageService.savePlan(_selectedDay!, val);
                      setState(() => _isSaving = true);
                      Timer(const Duration(seconds: 1), () => setState(() => _isSaving = false));
                    },
                    decoration: InputDecoration(
                      hintText: "Whisper your future visions here...",
                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.2), fontStyle: FontStyle.italic),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(24),
                    ),
                  ),
                  if (_isSaving)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 16),
                      child: Text("Saving changes...", style: TextStyle(fontSize: 10, color: currentMarkColor.withValues(alpha: 0.5))),
                    ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: _ModernAchievementButton(
                          label: "Achieved",
                          icon: Icons.auto_awesome,
                          color: Colors.greenAccent,
                          isActive: _storageService.getAchievement(_selectedDay!) == true,
                          onPressed: () => _markAchievement(true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ModernAchievementButton(
                          label: "Missed",
                          icon: Icons.blur_on,
                          color: Colors.redAccent,
                          isActive: _storageService.getAchievement(_selectedDay!) == false,
                          onPressed: () => _markAchievement(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSavingButton(theme, currentMarkColor),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(List<Color> colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF030213) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLuminousStat("Day", DateFormat('EEE').format(_selectedDay!), colors[0], isDark),
          Container(width: 1, height: 30, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
          _buildLuminousStat("Month", DateFormat('MMM').format(_selectedDay!), colors[1], isDark),
          Container(width: 1, height: 30, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
          _buildLuminousStat("Year", DateFormat('yyyy').format(_selectedDay!), colors[2], isDark),
        ],
      ),
    );
  }

  Widget _buildLuminousStat(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10)])),
      ],
    );
  }

  Widget _buildSavingButton(ThemeData theme, Color color) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.8), color]),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: () {
          _storageService.savePlan(_selectedDay!, _noteController.text);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Plan sealed in your legacy timeline."),
              backgroundColor: color.withValues(alpha: 0.9),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text("Seal Vision", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
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

class _MarkableCalendar extends StatefulWidget {
  final StorageService storageService;
  final DateTime selectedDay;
  final Function(DateTime) onDateChanged;

  const _MarkableCalendar({
    required this.storageService,
    required this.selectedDay,
    required this.onDateChanged,
  });

  @override
  State<_MarkableCalendar> createState() => _MarkableCalendarState();
}

class _MarkableCalendarState extends State<_MarkableCalendar> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDay.year, widget.selectedDay.month);
  }

  bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final firstDayOffset = firstDayWeekday % 7; 

    final weekdays = ["S", "M", "T", "W", "T", "F", "S"];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_left_rounded, size: 28),
                onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 4),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_right_rounded, size: 28),
                onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((w) => Text(w, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black26))).toList(),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 10, crossAxisSpacing: 10),
            itemCount: daysInMonth + firstDayOffset,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) return const SizedBox();
              final day = index - firstDayOffset + 1;
              final date = DateTime(_currentMonth.year, _currentMonth.month, day);
              final isSelected = isSameDay(date, widget.selectedDay);
              final isToday = isSameDay(date, DateTime.now());
              
              final colorValue = widget.storageService.getCalendarColor(date);
              final markedColor = colorValue != null && colorValue != 0 ? Color(colorValue) : null;
              final achievement = widget.storageService.getAchievement(date);

              return GestureDetector(
                onTap: () => widget.onDateChanged(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? (markedColor ?? theme.colorScheme.primary).withValues(alpha: 0.2)
                      : (markedColor != null ? markedColor.withValues(alpha: 0.05) : Colors.transparent),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected 
                        ? (markedColor ?? theme.colorScheme.primary).withValues(alpha: 0.6)
                        : (markedColor != null ? markedColor.withValues(alpha: 0.2) : Colors.transparent),
                      width: 1.5
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (markedColor != null)
                        _BreathingGlow(color: markedColor),
                      
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$day",
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected 
                                ? (markedColor ?? (isDark ? Colors.white : Colors.black))
                                : (markedColor ?? (isDark ? Colors.white70 : Colors.black87)),
                              fontWeight: isSelected || markedColor != null || isToday ? FontWeight.w900 : FontWeight.w400,
                            ),
                          ),
                          if (achievement != null)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 4, height: 4,
                              decoration: BoxDecoration(
                                color: achievement ? Colors.amber : Colors.redAccent,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: achievement ? Colors.amber : Colors.redAccent, blurRadius: 4)],
                              ),
                            ),
                        ],
                      ),
                      if (isToday && !isSelected)
                        Positioned(
                          top: 4, right: 4,
                          child: Container(width: 4, height: 4, decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BreathingGlow extends StatefulWidget {
  final Color color;
  const _BreathingGlow({required this.color});

  @override
  State<_BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<_BreathingGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _animation = Tween<double>(begin: 2.0, end: 10.0).animate(_controller);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.3), blurRadius: _animation.value, spreadRadius: 1)],
          ),
        );
      },
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
