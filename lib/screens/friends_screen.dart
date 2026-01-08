import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/friends_service.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FriendsService _friendsService = FriendsService();
  final ChatService _chatService = ChatService();
  List<UserProfile> _contactSuggestions = [];
  bool _isLoadingContacts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _syncContacts() async {
    setState(() => _isLoadingContacts = true);
    try {
      final suggestions = await _friendsService.syncContacts();
      setState(() => _contactSuggestions = suggestions);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error syncing contacts: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingContacts = false);
    }
  }

  void _startChat(UserProfile otherUser) async {
    try {
      final roomId = await _chatService.getOrCreateChatRoom(otherUser.uid);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ChatRoomScreen(chatRoomId: roomId, otherUser: otherUser),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Friends'),
            Tab(text: 'Requests'),
            Tab(text: 'Sync Contacts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(),
          _buildRequestsList(),
          _buildSyncTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return StreamBuilder<List<UserProfile>>(
      stream: _friendsService.getFriendsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return const Center(
              child: Text('No friends yet. Try syncing contacts!'));
        }
        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: friend.photoUrl != null
                    ? NetworkImage(friend.photoUrl!)
                    : null,
                child:
                    friend.photoUrl == null ? const Icon(Icons.person) : null,
              ),
              title: Text(friend.displayName ?? 'User'),
              trailing: IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => _startChat(friend),
              ),
              onTap: () => _startChat(friend),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return StreamBuilder<List<FriendRequest>>(
      stream: _friendsService.getIncomingRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(child: Text('No pending requests'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final user = req.fromUser;

            if (user == null) return const SizedBox.shrink();

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child:
                    user.photoUrl == null ? const Icon(Icons.person) : null,
              ),
              title: Text(user.displayName ?? 'User'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () =>
                        _friendsService.acceptFriendRequest(req),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () =>
                        _friendsService.declineFriendRequest(req.id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSyncTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _isLoadingContacts ? null : _syncContacts,
            icon: const Icon(Icons.sync),
            label: const Text('Find Friends from Contacts'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        if (_isLoadingContacts)
          const Center(child: CircularProgressIndicator())
        else if (_contactSuggestions.isEmpty)
          const Expanded(
              child: Center(
                  child:
                      Text('Sync contacts to find friends on Legacy Capsule')))
        else
          Expanded(
            child: ListView.builder(
              itemCount: _contactSuggestions.length,
              itemBuilder: (context, index) {
                final user = _contactSuggestions[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child:
                        user.photoUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(user.displayName ?? 'User'),
                  subtitle: Text(user.phoneNumber ?? ''),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _friendsService.sendFriendRequest(user.uid);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Friend request sent!')),
                      );
                    },
                    child: const Text('Add'),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
