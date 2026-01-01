enum MemoryType { text, photo, video, audio }

class Comment {
  final String id;
  final String userName;
  final String text;
  final DateTime date;

  Comment({
    required this.id,
    required this.userName,
    required this.text,
    required this.date,
  });
}

class Memory {
  final String id;
  final DateTime date;
  final String title;
  final String preview;
  final MemoryType type;
  final String content;
  final String? imageUrl;
  final bool isLocked;
  int reactionCount;
  List<Comment> comments;

  Memory({
    required this.id,
    required this.date,
    required this.title,
    required this.preview,
    required this.type,
    required this.content,
    this.imageUrl,
    this.isLocked = false,
    this.reactionCount = 0,
    List<Comment>? comments,
  }) : comments = comments ?? [];
}
