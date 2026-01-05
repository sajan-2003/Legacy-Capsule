import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/user.dart';

class ChatService extends ChangeNotifier {
  // Internal mock database for demo
  final Map<String, List<ChatMessage>> _roomMessages = {};
  final List<ChatRoom> _chatRooms = [];

  String get _currentUserId => 'demo_user';

  ChatService() {
    // Initialize with some mock data
    _initMockData();
  }

  void _initMockData() {
    final room1Id = 'demo_room_1';
    _chatRooms.add(ChatRoom(
      id: room1Id,
      participants: [_currentUserId, '1'],
      lastMessage: 'Hello! This is a legacy message.',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
    ));

    _roomMessages[room1Id] = [
      ChatMessage(
        id: 'm1',
        senderId: '1',
        content: 'Hello! How are you keeping your legacy?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatMessage(
        id: 'm2',
        senderId: _currentUserId,
        content: 'I am using the digital vault. It is amazing!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  Future<String> getOrCreateChatRoom(String otherUserId) async {
    // Check if room exists
    for (var room in _chatRooms) {
      if (room.participants.contains(otherUserId)) {
        return room.id;
      }
    }

    // Create new room
    final newRoomId = "room_${DateTime.now().millisecondsSinceEpoch}";
    final newRoom = ChatRoom(
      id: newRoomId,
      participants: [_currentUserId, otherUserId],
      lastMessage: '',
      lastMessageTime: DateTime.now(),
    );
    
    _chatRooms.add(newRoom);
    _roomMessages[newRoomId] = [];
    notifyListeners();
    return newRoomId;
  }

  Stream<List<ChatRoom>> getChatRoomsStream() async* {
    yield _chatRooms;
  }

  Stream<List<ChatMessage>> getMessagesStream(String chatRoomId) async* {
    // In a real app, this would be a Firestore listener
    while (true) {
      yield _roomMessages[chatRoomId] ?? [];
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> sendMessage(String chatRoomId, String content, {MessageType type = MessageType.text}) async {
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUserId,
      content: content,
      timestamp: DateTime.now(),
      type: type,
    );

    _roomMessages[chatRoomId]?.add(newMessage);
    
    // Update last message in room
    final roomIndex = _chatRooms.indexWhere((r) => r.id == chatRoomId);
    if (roomIndex != -1) {
      _chatRooms[roomIndex] = ChatRoom(
        id: chatRoomId,
        participants: _chatRooms[roomIndex].participants,
        lastMessage: content,
        lastMessageTime: DateTime.now(),
      );
    }

    notifyListeners();
    debugPrint("Mock: Message sent to $chatRoomId: $content");
  }

  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    _roomMessages[chatRoomId]?.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }
}
