import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/memory.dart';
import '../models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageService {
  static const String _memoriesBoxName = 'memories';
  static const String _communityCacheBoxName = 'community_cache';
  static const String _userBoxName = 'user_profile';
  static const int _maxFirebaseSize = 50 * 1024 * 1024; // 50MB in bytes

  // --- User Profile ---

  Future<void> saveUserProfile(UserProfile profile) async {
    final box = Hive.box(_userBoxName);
    await box.put('current_user', jsonEncode(profile.toJson()));
    
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(profile.uid).set(profile.toJson());
      } catch (e) {
        debugPrint("Cloud profile save failed: $e");
      }
    }
  }

  UserProfile? getUserProfile() {
    final box = Hive.box(_userBoxName);
    final data = box.get('current_user');
    if (data != null) {
      return UserProfile.fromJson(jsonDecode(data));
    }
    return null;
  }

  // --- Journal (Local) ---
  
  Future<void> saveMemoryLocally(Memory memory) async {
    final box = Hive.box(_memoriesBoxName);
    await box.put(memory.id, jsonEncode(memory.toJson()));
  }

  List<Memory> getLocalMemories() {
    final box = Hive.box(_memoriesBoxName);
    return box.values
        .map((m) => Memory.fromJson(jsonDecode(m)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> deleteLocalMemory(String id) async {
    final box = Hive.box(_memoriesBoxName);
    await box.delete(id);
  }

  // --- Community (Firebase + Local Cache) ---

  Future<void> shareToCommunity(Memory memory, File? file) async {
    final cacheBox = Hive.box(_communityCacheBoxName);
    await cacheBox.put(memory.id, jsonEncode(memory.toJson()));

    if (Firebase.apps.isNotEmpty) {
      try {
        if (file != null && await file.length() > _maxFirebaseSize) {
          throw Exception("File too large for cloud sharing.");
        }
        await FirebaseFirestore.instance.collection('community_posts').doc(memory.id).set(memory.toJson());
      } catch (e) {
        debugPrint("Cloud share failed: $e");
      }
    }
  }

  Future<void> updateReaction(String memoryId, int newCount) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance.collection('community_posts').doc(memoryId).update({
          'reactionCount': newCount,
        });
      }
    } catch (e) {
      debugPrint("Update reaction failed: $e");
    }
    
    final box = Hive.box(_communityCacheBoxName);
    final data = box.get(memoryId);
    if (data != null) {
      final memory = Memory.fromJson(jsonDecode(data));
      memory.reactionCount = newCount;
      await box.put(memoryId, jsonEncode(memory.toJson()));
    }
  }

  Future<void> addCommunityComment(String memoryId, Comment comment) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance.collection('community_posts').doc(memoryId).update({
          'comments': FieldValue.arrayUnion([comment.toJson()]),
        });
      }
    } catch (e) {
      debugPrint("Add comment failed: $e");
    }

    final box = Hive.box(_communityCacheBoxName);
    final data = box.get(memoryId);
    if (data != null) {
      final memory = Memory.fromJson(jsonDecode(data));
      memory.comments.add(comment);
      await box.put(memoryId, jsonEncode(memory.toJson()));
    }
  }

  List<Memory> getCachedCommunityPosts() {
    final box = Hive.box(_communityCacheBoxName);
    return box.values
        .map((m) => Memory.fromJson(jsonDecode(m)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Stream<List<Memory>> getCommunityPosts() {
    if (Firebase.apps.isEmpty) {
      return Stream.value(getCachedCommunityPosts());
    }

    return FirebaseFirestore.instance
        .collection('community_posts')
        .orderBy('date', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs.map((doc) => Memory.fromJson(doc.data())).toList();
          _updateCache(posts);
          return posts;
        })
        .handleError((error) {
          debugPrint("Firestore Stream Error: $error");
          return getCachedCommunityPosts();
        });
  }

  void _updateCache(List<Memory> posts) async {
    try {
      final box = Hive.box(_communityCacheBoxName);
      final Map<String, dynamic> data = {};
      final recentPosts = posts.length > 20 ? posts.sublist(0, 20) : posts;
      for (var post in recentPosts) {
        data[post.id] = jsonEncode(post.toJson());
      }
      if (data.isNotEmpty) {
        await box.putAll(data);
      }
    } catch (e) {
      debugPrint("Cache update error: $e");
    }
  }
}
