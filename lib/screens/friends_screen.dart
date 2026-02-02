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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Connections',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            fontSize: 22,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor:
              theme.colorScheme.onSurface.withValues(alpha: 0.4),
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'MY FRIENDS'),
            Tab(text: 'REQUESTS'),
            Tab(text: 'DISCOVER'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(theme),
          _buildRequestsList(theme),
          _buildSyncTab(theme),
        ],
      ),
    );
  }

  Widget _buildFriendsList(ThemeData theme) {
    return StreamBuilder<List<UserProfile>>(
      stream: _friendsService.getFriendsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return _buildEmptyState(
            theme,
            Icons.people_outline,
            'No connections yet',
            'Find your circle by syncing contacts.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.05)),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _buildAvatar(friend, theme),
                title: Text(friend.displayName ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text("Legacy Member",
                          style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                trailing: CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: IconButton(
                    icon: Icon(Icons.chat_bubble_rounded,
                        size: 18, color: theme.colorScheme.primary),
                    onPressed: () => _startChat(friend),
                  ),
                ),
                onTap: () => _startChat(friend),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsList(ThemeData theme) {
    return StreamBuilder<List<FriendRequest>>(
      stream: _friendsService.getIncomingRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return _buildEmptyState(
            theme,
            Icons.mark_email_read_outlined,
            'No pending requests',
            'When someone invites you, they\'ll appear here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final user = req.fromUser;
            if (user == null) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  _buildAvatar(user, theme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName ?? 'User',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Sent a friend request",
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildActionButton(
                          Icons.check,
                          Colors.green,
                          () => _friendsService.acceptFriendRequest(req)),
                      const SizedBox(width: 8),
                      _buildActionButton(
                          Icons.close,
                          Colors.red,
                          () => _friendsService.declineFriendRequest(req.id)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSyncTab(ThemeData theme) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.7)
            ]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12)
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.contact_page_rounded,
                  color: Colors.white, size: 40),
              const SizedBox(height: 12),
              const Text("Expand Your Legacy",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const Text(
                  "Sync your contacts to find friends already on the platform.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoadingContacts ? null : _syncContacts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoadingContacts
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Sync Contacts Now",
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        if (_contactSuggestions.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _contactSuggestions.length,
              itemBuilder: (context, index) {
                final user = _contactSuggestions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      _buildAvatar(user, theme),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.displayName ?? 'User',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(user.phoneNumber ?? '',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _friendsService.sendFriendRequest(user.uid);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Request sent!')));
                        },
                        child: const Text("ADD"),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else if (!_isLoadingContacts)
          const Spacer(),
      ],
    );
  }

  Widget _buildAvatar(UserProfile user, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.1), width: 2),
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        backgroundImage:
            user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
        child: user.photoUrl == null
            ? Icon(Icons.person, color: theme.colorScheme.primary)
            : null,
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildEmptyState(
      ThemeData theme, IconData icon, String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(sub,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 12)),
        ],
      ),
    );
  }
}
