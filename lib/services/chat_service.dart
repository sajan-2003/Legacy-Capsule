import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';

class ChatService {
  String get _currentUserId => 'demo_user';

  Future<String> getOrCreateChatRoom(String otherUserId) async {
    // Return a dummy room ID for demo
    return "demo_room_${otherUserId}";
  }

  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    // Return a mock conversation for demo
    return Stream.value([
      ChatMessage(
        id: '1',
        senderId: 'other_user',
        content: 'Hello! This is a demo message.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      ChatMessage(
        id: '2',
        senderId: _currentUserId,
        content: 'Hi! The app is now in Demo Mode.',
        timestamp: DateTime.now(),
      ),
    ]);
  }

  Future<void> sendMessage(String chatRoomId, String content, {MessageType type = MessageType.text}) async {
    debugPrint("Mock: Message sent to $chatRoomId: $content");
  }
}
