import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/user.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  Future<void> sendFriendRequest(String targetUserId) async {
    if (_currentUserId.isEmpty) return;
    
    await _firestore.collection('friend_requests').add({
      'from': _currentUserId,
      'to': targetUserId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptFriendRequest(String requestId, String fromUserId) async {
    WriteBatch batch = _firestore.batch();

    // Update request status
    batch.update(_firestore.collection('friend_requests').doc(requestId), {
      'status': 'accepted',
    });

    // Add to friends list for both users
    batch.set(_firestore.collection('users').doc(_currentUserId).collection('friends').doc(fromUserId), {
      'addedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_firestore.collection('users').doc(fromUserId).collection('friends').doc(_currentUserId), {
      'addedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Stream<List<UserProfile>> getFriends() {
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .snapshots()
        .asyncMap((snapshot) async {
      List<UserProfile> friends = [];
      for (var doc in snapshot.docs) {
        var userDoc = await _firestore.collection('users').doc(doc.id).get();
        if (userDoc.exists) {
          friends.add(UserProfile.fromJson(userDoc.data()!));
        }
      }
      return friends;
    });
  }

  Future<List<UserProfile>> syncContacts() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      return [];
    }

    final contacts = await FlutterContacts.getContacts(withProperties: true);
    final List<String> phoneNumbers = contacts
        .expand((c) => c.phones.map((p) => p.number.replaceAll(RegExp(r'\D'), '')))
        .toList();

    if (phoneNumbers.isEmpty) return [];

    // Firestore query to find users with these phone numbers
    // Note: This might need optimization for many contacts
    final querySnapshot = await _firestore
        .collection('users')
        .where('phoneNumber', whereIn: phoneNumbers.take(10).toList()) // Limited by Firestore whereIn limit
        .get();

    return querySnapshot.docs
        .map((doc) => UserProfile.fromJson(doc.data()))
        .where((user) => user.uid != _currentUserId)
        .toList();
  }
}
