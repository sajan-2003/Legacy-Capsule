enum MemoryType { text, photo, video, audio }

class Memory {
  final String id;
  final DateTime date;
  final String title;
  final String preview;
  final MemoryType type;
  final String content;
  final String? imageUrl;
  final bool isLocked;

  Memory({
    required this.id,
    required this.date,
    required this.title,
    required this.preview,
    required this.type,
    required this.content,
    this.imageUrl,
    this.isLocked = false,
  });
}
