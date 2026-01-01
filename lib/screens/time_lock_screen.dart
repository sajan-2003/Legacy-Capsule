import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  const TimeLockScreen({super.key});

  @override
  State<TimeLockScreen> createState() => _TimeLockScreenState();
}

class _TimeLockScreenState extends State<TimeLockScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Time Capsules",
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _lockedMemories.isEmpty ? _buildEmptyState() : _buildTimeline(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddMemoryScreen(onSave: (m) {}),
            ),
          );
        },
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.lock_clock, color: Colors.white),
        label: const Text("Lock New Memory", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTimeline() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _lockedMemories.length,
      itemBuilder: (context, index) {
        final memory = _lockedMemories[index];
        return _buildLockedCard(memory);
      },
    );
  }

  Widget _buildLockedCard(TimeLockedMemory memory) {
    final daysRemaining = memory.unlockDate.difference(DateTime.now()).inDays;
    
    return GestureDetector(
      onTap: () => _showLockedDetails(memory),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock, size: 14, color: Color(0xFFB45309)),
                              const SizedBox(width: 4),
                              Text(
                                "Unlocks ${DateFormat('MMM yyyy').format(memory.unlockDate)}",
                                style: const TextStyle(
                                  color: Color(0xFFB45309),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      memory.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Blurred/Faded Preview
                    Opacity(
                      opacity: 0.5,
                      child: Text(
                        memory.preview,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Progress Indicator
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "$daysRemaining days remaining",
                              style: const TextStyle(color: Color(0xFF0284C7), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              "${(memory.progress * 100).toInt()}%",
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: memory.progress,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Blurred Overlay for visual effect
              if (memory.imageUrl != null)
                Positioned(
                  top: 0, right: 0, bottom: 0, left: 0,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.1,
                      child: Image.network(memory.imageUrl!, fit: BoxFit.cover),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLockedDetails(TimeLockedMemory memory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFFF0F9FF), shape: BoxShape.circle),
              child: const Icon(Icons.lock_clock_outlined, size: 48, color: Color(0xFF0284C7)),
            ),
            const SizedBox(height: 24),
            Text(memory.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "This memory is safely sealed until the specified date. You cannot view the content yet.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 16, height: 1.5),
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Text("UNLOCK DATE", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMMM d, yyyy').format(memory.unlockDate),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 32, bottom: 40),
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Understood", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text("No locked memories yet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          const Text("Secure your future words today.", style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
