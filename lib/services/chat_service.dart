import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  Future<String> getOrCreateChatRoom(String otherUserId) async {
    // Check if a chat room already exists between these two users
    var query = await _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: _currentUserId)
        .get();

    for (var doc in query.docs) {
      List participants = doc['participants'];
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Create new room if not found
    var docRef = await _firestore.collection('chat_rooms').add({
      'participants': [_currentUserId, otherUserId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
  }

  Future<void> sendMessage(String chatRoomId, String content, {MessageType type = MessageType.text}) async {
    if (content.trim().isEmpty) return;

    final messageData = {
      'senderId': _currentUserId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type.index,
    };

    // Add message
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    // Update last message in room
    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'lastMessage': type == MessageType.text ? content : '[Media]',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
}
