import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'add_memory_screen.dart';

class TimeLockedMemory {
  final String id;
  final String title;
  final String preview;
  final DateTime unlockDate;
  final String? imageUrl;
  final double progress; // 0.0 to 1.0

  TimeLockedMemory({
    required this.id,
    required this.title,
    required this.preview,
    required this.unlockDate,
    this.imageUrl,
    required this.progress,
  });
}

class TimeLockScreen extends StatefulWidget {
  final bool isSearching;
  final TextEditingController searchController;
  final Function(bool) onThemeChanged;

  const TimeLockScreen({
    super.key,
    required this.isSearching,
    required this.searchController,
    required this.onThemeChanged,
  });

  @override
  State<TimeLockScreen> createState() => _TimeLockScreenState();
}

class _TimeLockScreenState extends State<TimeLockScreen> with SingleTickerProviderStateMixin {
  DateTime? _selectedSearchDate;
  final ImagePicker _picker = ImagePicker();
  bool _headerSearching = false;
  
  final List<TimeLockedMemory> _lockedMemories = [
    TimeLockedMemory(
      id: '1',
      title: "Letter to my future self",
      preview: "I hope you are doing well and still chasing your dreams...",
      unlockDate: DateTime(2026, 5, 12),
      progress: 0.45,
    ),
    TimeLockedMemory(
      id: '2',
      title: "Childhood Home Video",
      preview: "The day we moved into the blue house on 5th street.",
      unlockDate: DateTime(2030, 1, 1),
      progress: 0.15,
      imageUrl: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&q=80",
    ),
    TimeLockedMemory(
      id: '3',
      title: "Advice for my daughter",
      preview: "Everything I want you to know before you turn eighteen.",
      unlockDate: DateTime(2035, 8, 24),
      progress: 0.05,
    ),
  ];

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

  Future<void> _selectSearchDate() async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedSearchDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
        _headerSearching = true;
        widget.searchController.text = DateFormat('MMM d, yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
                  hintText: "Search capsules...",
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() {}),
              )
            : Text(
                "Time Capsules",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
          actions: [
            if (_headerSearching)
              IconButton(
                icon: Icon(Icons.calendar_month_outlined, color: theme.colorScheme.primary),
                onPressed: _selectSearchDate,
              ),
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
        ),
        body: _lockedMemories.isEmpty ? _buildEmptyState(theme) : _buildTimeline(theme),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddMemoryScreen(onSave: (m) {}),
              ),
            );
          },
          backgroundColor: theme.colorScheme.primary,
          icon: const Icon(Icons.lock_clock, color: Colors.white),
          label: const Text("Lock New Memory", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text("No time capsules found", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildTimeline(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _lockedMemories.length,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemBuilder: (context, index) {
        final memory = _lockedMemories[index];
        
        bool matchesTitle = memory.title.toLowerCase().contains(widget.searchController.text.toLowerCase());
        bool matchesDate = _selectedSearchDate == null || 
            (memory.unlockDate.year == _selectedSearchDate!.year && 
             memory.unlockDate.month == _selectedSearchDate!.month && 
             memory.unlockDate.day == _selectedSearchDate!.day);

        if ((widget.searchController.text.isNotEmpty || _selectedSearchDate != null) && !(matchesTitle && matchesDate)) {
          return const SizedBox.shrink();
        }
        
        return Stack(
          children: [
            if (index != _lockedMemories.length - 1)
              Positioned(
                left: 11,
                top: 30,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: theme.dividerColor,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 32),
              child: _buildLockedCard(memory, theme),
            ),
            Positioned(
              left: 0,
              top: 12,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLockedCard(TimeLockedMemory memory, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final daysRemaining = memory.unlockDate.difference(DateTime.now()).inDays;
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: () => _showLockedDetails(memory),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? theme.dividerColor : const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB45309).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock, size: 12, color: Color(0xFFB45309)),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Unlocks ${DateFormat('MMM yyyy').format(memory.unlockDate)}",
                                      style: const TextStyle(
                                        color: Color(0xFFB45309),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.more_horiz, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            memory.title,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Opacity(
                            opacity: 0.4,
                            child: Text(
                              memory.preview,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "$daysRemaining days left",
                                    style: TextStyle(
                                      color: theme.colorScheme.primary, 
                                      fontSize: 11, 
                                      fontWeight: FontWeight.w600
                                    ),
                                  ),
                                  Text(
                                    "${(memory.progress * 100).toInt()}%",
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4), 
                                      fontSize: 11
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: memory.progress,
                                  backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (memory.imageUrl != null)
                      Positioned(
                        top: 0, right: 0, bottom: 0, left: 0,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.05,
                            child: Image.network(memory.imageUrl!, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLockedDetails(TimeLockedMemory memory) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 32, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 32),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.rotate(
                    angle: (1 - value) * 0.5,
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.lock_clock_outlined, size: 48, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(memory.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Safely sealed until the specified date. Patience is part of the journey.",
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), height: 1.5),
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_available, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Available On", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12)),
                      Text(DateFormat('MMMM d, yyyy').format(memory.unlockDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text("Got it", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
