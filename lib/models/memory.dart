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

  Map<String, dynamic> toJson() => {
    'id': id,
    'userName': userName,
    'text': text,
    'date': date.toIso8601String(),
  };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'],
    userName: json['userName'],
    text: json['text'],
    date: DateTime.parse(json['date']),
  );
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
  final String? authorId;
  final String? authorName;
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
    this.authorId,
    this.authorName,
    this.reactionCount = 0,
    List<Comment>? comments,
  }) : comments = comments ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'title': title,
    'preview': preview,
    'type': type.name,
    'content': content,
    'imageUrl': imageUrl,
    'isLocked': isLocked,
    'authorId': authorId,
    'authorName': authorName,
    'reactionCount': reactionCount,
    'comments': comments.map((c) => c.toJson()).toList(),
  };

  factory Memory.fromJson(Map<String, dynamic> json) => Memory(
    id: json['id'],
    date: DateTime.parse(json['date']),
    title: json['title'],
    preview: json['preview'],
    type: MemoryType.values.byName(json['type']),
    content: json['content'],
    imageUrl: json['imageUrl'],
    isLocked: json['isLocked'] ?? false,
    authorId: json['authorId'],
    authorName: json['authorName'],
    reactionCount: json['reactionCount'] ?? 0,
    comments: (json['comments'] as List? ?? [])
        .map((c) => Comment.fromJson(c as Map<String, dynamic>))
        .toList(),
  );
}
