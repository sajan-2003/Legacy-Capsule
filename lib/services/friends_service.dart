import 'package:flutter/foundation.dart';
import '../models/user.dart';

class FriendRequest {
  final String id;
  final String fromId;
  final String toId;
  final String status;
  final UserProfile? fromUser;

  FriendRequest({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.status,
    this.fromUser,
  });
}

class FriendsService {
  // Mocked for Demo
  String get currentUserId => 'demo_user';

  Future<void> sendFriendRequest(String targetUserId) async {
    debugPrint("Mock: Friend request sent to $targetUserId");
  }

  Future<void> acceptFriendRequest(String requestId, String fromUserId) async {
    debugPrint("Mock: Accepted request from $fromUserId");
  }

  Future<void> declineFriendRequest(String requestId) async {
    debugPrint("Mock: Declined request $requestId");
  }

  Stream<List<UserProfile>> getFriends() {
    // Return empty list or mock friends for demo
    return Stream.value([
      UserProfile(uid: '1', email: 'friend1@demo.com', displayName: 'Demo Friend 1'),
    ]);
  }

  Stream<List<FriendRequest>> getIncomingFriendRequests() {
    // Mock incoming requests
    return Stream.value([
      FriendRequest(
        id: 'req_1',
        fromId: 'user_2',
        toId: currentUserId,
        status: 'pending',
        fromUser: UserProfile(uid: '2', displayName: 'Requesting User', email: 'user2@demo.com'),
      ),
    ]);
  }

  Future<List<UserProfile>> syncContacts() async {
    return [
      UserProfile(uid: '2', email: 'contact@demo.com', displayName: 'Contact Suggestion'),
    ];
  }
}
