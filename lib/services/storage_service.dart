import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/memory.dart';
import '../models/user.dart';

class StorageService {
  static const String _memoriesBoxName = 'memories';
  static const String _communityCacheBoxName = 'community_cache';
  static const String _userBoxName = 'user_profile';
  static const String _plansBoxName = 'future_plans';
  static const String _colorsBoxName = 'calendar_colors';
  static const String _achievementsBoxName = 'achievements';

  // --- Clear Data ---
  Future<void> clearAllData() async {
    try {
      await Hive.box(_memoriesBoxName).clear();
      await Hive.box(_communityCacheBoxName).clear();
      await Hive.box(_userBoxName).clear();
      await Hive.box(_plansBoxName).clear();
      await Hive.box(_colorsBoxName).clear();
      await Hive.box(_achievementsBoxName).clear();
      debugPrint("All local boxes cleared.");
    } catch (e) {
      debugPrint("Error clearing local data: $e");
    }
  }

  // --- Calendar Color Marking ---
  Future<void> saveCalendarColor(DateTime date, int colorValue) async {
    final box = Hive.box(_colorsBoxName);
    final key = "${date.year}-${date.month}-${date.day}";
    await box.put(key, colorValue);
  }

  int? getCalendarColor(DateTime date) {
    final box = Hive.box(_colorsBoxName);
    final key = "${date.year}-${date.month}-${date.day}";
    return box.get(key) as int?;
  }

  // --- Future Plans (Vision Board) ---
  Future<void> savePlan(DateTime date, String note) async {
    final box = Hive.box(_plansBoxName);
    final key = "${date.year}-${date.month}-${date.day}";
    await box.put(key, note);
  }

  String getPlan(DateTime date) {
    final box = Hive.box(_plansBoxName);
    final key = "${date.year}-${date.month}-${date.day}";
    return box.get(key, defaultValue: "") as String;
  }

  Map<String, String> getAllPlans() {
    final box = Hive.box(_plansBoxName);
    return box.toMap().map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  // --- Achievement Tracking ---
  Future<void> saveAchievement(DateTime date, bool? achieved) async {
    final box = Hive.box(_achievementsBoxName);
    final key = "${date.year}-${date.month}-${date.day}";
    if (achieved == null) {
      await box.delete(key);
    } else {
      await box.put(key, achieved);
    }
  }

  bool? getAchievement(DateTime date) {
    final box = Hive.box(_achievementsBoxName);
    final key = "${date.year}-${date.month}-${date.day}";
    return box.get(key) as bool?;
  }

  // --- Demo Data Injection ---
  Future<void> initializeDemoData() async {
    final memoriesBox = Hive.box(_memoriesBoxName);
    final communityBox = Hive.box(_communityCacheBoxName);

    if (memoriesBox.isEmpty) {
      debugPrint("Injecting Journal Demo Data...");
      final demoJournal = [
        Memory(
          id: 'demo_j1',
          date: DateTime.now().subtract(const Duration(days: 1)),
          title: "My Journey Begins",
          preview: "Started my digital legacy journey today.",
          type: MemoryType.photo,
          content: "This app is exactly what I needed to keep my private thoughts and memories safe for the future.",
          imageUrls: ["https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80"],
        ),
        Memory(
          id: 'demo_j2',
          date: DateTime.now().subtract(const Duration(days: 3)),
          title: "Note to Future Self",
          preview: "Remember to stay curious and never stop learning.",
          type: MemoryType.text,
          content: "Life moves fast. I'm writing this to remind myself of the goals I set this year.",
        ),
      ];
      for (var m in demoJournal) {
        await memoriesBox.put(m.id, jsonEncode(m.toJson()));
      }
    }

    if (communityBox.isEmpty) {
      debugPrint("Injecting Community Demo Data...");
      final demoCommunity = [
        Memory(
          id: 'demo_c1',
          date: DateTime.now().subtract(const Duration(hours: 2)),
          title: "Coffee & Code",
          preview: "Best way to spend a Saturday morning.",
          type: MemoryType.photo,
          content: "Exploring some new Flutter features while enjoying a flat white.",
          imageUrls: ["https://images.unsplash.com/photo-1495474472287-4bd374c3f58b?w=800&q=80"],
          authorId: 'user_alex',
          authorName: 'Alex Rivers',
          reactionCount: 15,
        ),
        Memory(
          id: 'demo_c2',
          date: DateTime.now().subtract(const Duration(days: 2)),
          title: "Peaceful Retreat",
          preview: "A short clip from my weekend getaway.",
          type: MemoryType.video,
          content: "The nature here is breathtaking. So glad I could capture this moment.",
          imageUrls: ["https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4"],
          authorId: 'user_sarah',
          authorName: 'Sarah Jenkins',
          reactionCount: 42,
        ),
      ];
      for (var m in demoCommunity) {
        await communityBox.put(m.id, jsonEncode(m.toJson()));
      }
    }
  }

  // --- User Profile ---
  Future<void> saveUserProfile(UserProfile profile) async {
    final box = Hive.box(_userBoxName);
    await box.put('current_user', jsonEncode(profile.toJson()));
  }

  UserProfile? getUserProfile() {
    final box = Hive.box(_userBoxName);
    final data = box.get('current_user');
    if (data != null) {
      try {
        return UserProfile.fromJson(jsonDecode(data));
      } catch (e) {
        debugPrint("Error parsing user profile: $e");
      }
    }
    return null;
  }

  // --- Journal ---
  Future<void> saveMemoryLocally(Memory memory) async {
    final box = Hive.box(_memoriesBoxName);
    await box.put(memory.id, jsonEncode(memory.toJson()));
  }

  List<Memory> getLocalMemories() {
    try {
      final box = Hive.box(_memoriesBoxName);
      final memories = box.values
          .map((m) => Memory.fromJson(jsonDecode(m as String)))
          .toList();
      memories.sort((a, b) => b.date.compareTo(a.date));
      return memories;
    } catch (e) {
      debugPrint("Error retrieving local memories: $e");
      return [];
    }
  }

  Future<void> deleteLocalMemory(String id) async {
    final box = Hive.box(_memoriesBoxName);
    await box.delete(id);
  }

  // --- Community ---
  Future<void> shareToCommunity(Memory memory, dynamic file) async {
    final cacheBox = Hive.box(_communityCacheBoxName);
    await cacheBox.put(memory.id, jsonEncode(memory.toJson()));
  }

  Future<void> updateReaction(String memoryId, int newCount) async {
    final box = Hive.box(_communityCacheBoxName);
    final data = box.get(memoryId);
    if (data != null) {
      final memory = Memory.fromJson(jsonDecode(data as String));
      memory.reactionCount = newCount;
      await box.put(memoryId, jsonEncode(memory.toJson()));
    }
  }

  Future<void> addCommunityComment(String memoryId, Comment comment) async {
    final box = Hive.box(_communityCacheBoxName);
    final data = box.get(memoryId);
    if (data != null) {
      final memory = Memory.fromJson(jsonDecode(data as String));
      memory.comments.add(comment);
      await box.put(memoryId, jsonEncode(memory.toJson()));
    }
  }

  List<Memory> getCachedCommunityPosts() {
    try {
      final box = Hive.box(_communityCacheBoxName);
      final posts = box.values
          .map((m) => Memory.fromJson(jsonDecode(m as String)))
          .toList();
      posts.sort((a, b) => b.date.compareTo(a.date));
      return posts;
    } catch (e) {
      debugPrint("Error retrieving community posts: $e");
      return [];
    }
  }

  Future<List<Memory>> getCommunityMemories() async {
    return getCachedCommunityPosts();
  }
}
