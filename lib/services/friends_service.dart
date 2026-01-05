import 'package:flutter/foundation.dart';
import '../models/user.dart';

class FriendRequest {
  final String id;
  final String fromId;
  final String toId;
  final String status;
  final UserProfile? fromUser;
  final DateTime? timestamp;

  FriendRequest({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.status,
    this.fromUser,
    this.timestamp,
  });
}

class FriendsService extends ChangeNotifier {
  // Internal state for demo
  final List<UserProfile> _friends = [
    UserProfile(uid: '1', email: 'alice@demo.com', displayName: 'Alice Thompson', bio: 'Living my best life'),
    UserProfile(uid: '3', email: 'bob@demo.com', displayName: 'Bob Miller', bio: 'Adventurer'),
  ];
  
  final List<FriendRequest> _incomingRequests = [
    FriendRequest(
      id: 'req_1',
      fromId: 'user_2',
      toId: 'demo_user',
      status: 'pending',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      fromUser: UserProfile(uid: '2', displayName: 'Charlie Brown', email: 'charlie@demo.com', bio: 'History buff'),
    ),
  ];

  String get currentUserId => 'demo_user';

  // Streams to mimic real-time DB behavior
  Stream<List<UserProfile>> getFriendsStream() async* {
    yield _friends;
  }

  Stream<List<FriendRequest>> getIncomingRequestsStream() async* {
    yield _incomingRequests;
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    // Logic for sending request
    debugPrint("Mock: Friend request sent to $targetUserId");
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> acceptFriendRequest(FriendRequest request) async {
    // In a real app, this would update the DB
    if (request.fromUser != null) {
      _friends.add(request.fromUser!);
    }
    _incomingRequests.removeWhere((r) => r.id == request.id);
    notifyListeners();
    debugPrint("Mock: Accepted request from ${request.fromId}");
  }

  Future<void> declineFriendRequest(String requestId) async {
    _incomingRequests.removeWhere((r) => r.id == requestId);
    notifyListeners();
    debugPrint("Mock: Declined request $requestId");
  }

  Future<void> removeFriend(String friendId) async {
    _friends.removeWhere((u) => u.uid == friendId);
    notifyListeners();
    debugPrint("Mock: Removed friend $friendId");
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    // Simulating user discovery
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      UserProfile(uid: 'u_101', displayName: 'David Wilson', email: 'david@demo.com'),
      UserProfile(uid: 'u_102', displayName: 'Diana Prince', email: 'diana@demo.com'),
    ].where((u) => u.displayName!.toLowerCase().contains(query.toLowerCase())).toList();
  }

  Future<List<UserProfile>> syncContacts() async {
    // Mocking contact discovery logic
    await Future.delayed(const Duration(seconds: 1));
    return [
      UserProfile(uid: 'c_01', email: 'mom@demo.com', displayName: 'Mom (Contact)'),
      UserProfile(uid: 'c_02', email: 'brother@demo.com', displayName: 'Brother (Contact)'),
    ];
  }
}
