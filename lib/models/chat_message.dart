import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, file }

class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
  });

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'content': content,
    'timestamp': Timestamp.fromDate(timestamp),
    'type': type.index,
  };

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> json = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: json['senderId'],
      content: json['content'],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      type: MessageType.values[json['type'] ?? 0],
    );
  }
}

class ChatRoom {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  ChatRoom({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> json = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null 
          ? (json['lastMessageTime'] as Timestamp).toDate() 
          : null,
    );
  }
}
