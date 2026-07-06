import 'package:flutter/material.dart';
import '../../services/chat_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final String _currentUserId = 'demo_user'; 

  // Default demo friends data
  final List<Map<String, dynamic>> _demoFriends = [
    {
      'name': 'Sarah Jenkins',
      'lastMsg': 'That photo from yesterday was amazing!',
      'time': '10:45 AM',
      'unread': 2,
      'online': true,
      'avatar': 'https://i.pravatar.cc/150?u=sarah',
      'color': Colors.pinkAccent
    },
    {
      'name': 'David Chen',
      'lastMsg': 'Did you see the new community post?',
      'time': 'Yesterday',
      'unread': 0,
      'online': false,
      'avatar': 'https://i.pravatar.cc/150?u=david',
      'color': Colors.blueAccent
    },
    {
      'name': 'Elena Rodriguez',
      'lastMsg': 'I locked a new memory for us.',
      'time': 'Monday',
      'unread': 1,
      'online': true,
      'avatar': 'https://i.pravatar.cc/150?u=elena',
      'color': Colors.amberAccent
    },
    {
      'name': 'Marcus Thorne',
      'lastMsg': 'Check out this video clip! 🎥',
      'time': '2:15 PM',
      'unread': 0,
      'online': true,
      'avatar': 'https://i.pravatar.cc/150?u=marcus',
      'color': Colors.deepPurpleAccent
    },
    {
      'name': 'Aisha Khan',
      'lastMsg': 'Let\'s catch up soon.',
      'time': 'Just now',
      'unread': 5,
      'online': true,
      'avatar': 'https://i.pravatar.cc/150?u=aisha',
      'color': Colors.tealAccent
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text("Messages", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, size: 20),
                  hintText: "Search chats...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Chat List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _demoFriends.length,
              itemBuilder: (context, index) {
                final friend = _demoFriends[index];
                return _buildChatTile(friend, theme, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> friend, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: () {
          // Navigation to chat room
        },
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, friend['color']],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.surface,
                backgroundImage: NetworkImage(friend['avatar']),
              ),
            ),
            if (friend['online'])
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 2.5),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          friend['name'],
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: friend['unread'] > 0 ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          friend['lastMsg'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: friend['unread'] > 0 
                ? theme.colorScheme.onSurface 
                : theme.colorScheme.onSurface.withOpacity(0.5),
            fontWeight: friend['unread'] > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              friend['time'],
              style: TextStyle(
                fontSize: 11,
                color: friend['unread'] > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.4),
                fontWeight: friend['unread'] > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 6),
            if (friend['unread'] > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  friend['unread'].toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
