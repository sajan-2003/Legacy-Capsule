import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String message;
  final String time;
  bool isUnread;

  NotificationModel({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.message,
    required this.time,
    this.isUnread = true,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      icon: Icons.lock_open,
      iconColor: const Color(0xFF0284C7),
      bgColor: const Color(0xFFE0F2FE),
      title: "Capsule Unlocked!",
      message: "Your 'Letter to my future self' is now available to read.",
      time: "2 hours ago",
      isUnread: true,
    ),
    NotificationModel(
      id: '2',
      icon: Icons.security,
      iconColor: const Color(0xFF059669),
      bgColor: const Color(0xFFD1FAE5),
      title: "Security Alert",
      message: "New login detected from a Chrome browser on Windows.",
      time: "Yesterday",
      isUnread: false,
    ),
    NotificationModel(
      id: '3',
      icon: Icons.favorite_border,
      iconColor: const Color(0xFFDC2626),
      bgColor: const Color(0xFFFEE2E2),
      title: "Memory Anniversary",
      message: "It's been 2 years since 'Summer Vacation at the Beach'.",
      time: "3 days ago",
      isUnread: false,
    ),
  ];

  void _markAsRead(int index) {
    setState(() {
      _notifications[index].isUnread = false;
    });
  }

  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isUnread = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          "Notifications",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_notifications.any((n) => n.isUnread))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text("Mark all as read", style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.dividerColor, height: 1),
        ),
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) => _deleteNotification(index),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    ),
                    child: _buildNotificationItem(notification, index, theme),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            "All caught up!",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "No new notifications for you.",
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, int index, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    // Adapt notification icon colors for dark mode visibility
    final iconBgColor = isDark ? notification.iconColor.withOpacity(0.15) : notification.bgColor;
    final iconColor = isDark ? notification.iconColor.withOpacity(0.9) : notification.iconColor;

    return InkWell(
      onTap: () => _markAsRead(index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notification.isUnread 
              ? theme.colorScheme.primary.withOpacity(0.4) 
              : (isDark ? theme.dividerColor : const Color(0xFFF1F5F9))
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(notification.icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.title,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (notification.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.time,
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 11),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_horiz, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                        color: theme.colorScheme.surface,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 120),
                        onSelected: (value) {
                          if (value == 'read') _markAsRead(index);
                          if (value == 'delete') _deleteNotification(index);
                        },
                        itemBuilder: (context) => [
                          if (notification.isUnread)
                            PopupMenuItem(
                              value: 'read',
                              child: Row(
                                children: [
                                  const Icon(Icons.done, size: 18),
                                  const SizedBox(width: 8),
                                  Text("Mark as read", style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
                                ],
                              ),
                            ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                const SizedBox(width: 8),
                                Text("Delete", style: const TextStyle(fontSize: 13, color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
