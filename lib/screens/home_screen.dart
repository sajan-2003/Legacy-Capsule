import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/memory.dart';
import 'add_memory_screen.dart';
import 'profile_screen.dart';
import 'memory_detail_screen.dart';
import 'time_lock_screen.dart';
import 'notifications_screen.dart';
import 'community_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final ImagePicker _picker = ImagePicker();

  final List<Memory> _memories = [
    Memory(
      id: '1',
      date: DateTime.now(),
      title: 'Summer Vacation at the Beach',
      preview: 'The waves were so calm today. The kids built a giant sandcastle near the pier...',
      type: MemoryType.photo,
      content: 'The waves were so calm today. The kids built a giant sandcastle near the pier. We stayed until sunset. The weather was perfect and we all had a great time.',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
      isLocked: false,
    ),
  ];

  void _addMemory(Memory memory) {
    setState(() {
      _memories.insert(0, memory);
    });
  }

  void _deleteMemory(String id) {
    setState(() {
      _memories.removeWhere((m) => m.id == id);
    });
  }

  void _toggleLock(String id) {
    setState(() {
      final index = _memories.indexWhere((m) => m.id == id);
      if (index != -1) {
        final m = _memories[index];
        _memories[index] = Memory(
          id: m.id,
          date: m.date,
          title: m.title,
          preview: m.preview,
          type: m.type,
          content: m.content,
          imageUrl: m.imageUrl,
          isLocked: !m.isLocked,
        );
      }
    });
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
    final List<Widget> pages = [
      _buildHomeContent(),
      const CommunityScreen(),
      const TimeLockScreen(),
      const NotificationsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0284C7),
          unselectedItemColor: const Color(0xFF94A3B8),
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
      floatingActionButton: _currentIndex == 0 
        ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMemoryScreen(onSave: _addMemory),
                ),
              );
            },
            backgroundColor: const Color(0xFF0284C7),
            elevation: 4,
            child: const Icon(Icons.add, size: 28, color: Colors.white),
          )
        : null,
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        // Custom App Bar
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 16,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "My Memories",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _openCamera,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF0369A1),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Timeline / Content
        Expanded(
          child: _memories.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  itemCount: _memories.length,
                  itemBuilder: (context, index) {
                    final memory = _memories[index];
                    return MemoryCard(
                      memory: memory,
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
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Your story starts here. Add your first memory.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF475569),
                height: 1.4,
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

  const MemoryCard({
    super.key,
    required this.memory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                    // Date & Icons
                    Row(
                      children: [
                        Text(
                          dateFormat.format(memory.date),
                          style: const TextStyle(
                            color: Color(0xFF0369A1),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(typeIcon, size: 18, color: const Color(0xFF64748B)),
                        if (memory.isLocked) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.lock, size: 18, color: Color(0xFFB45309)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Thumbnail for Photo
                    if (memory.imageUrl != null && memory.type == MemoryType.photo) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          memory.imageUrl!,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 160,
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Title
                    Text(
                      memory.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Preview Text
                    Text(
                      memory.preview,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
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
