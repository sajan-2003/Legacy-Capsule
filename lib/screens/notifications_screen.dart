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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Notifications",
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_notifications.any((n) => n.isUnread))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text("Mark all as read", style: TextStyle(fontSize: 12, color: Color(0xFF0284C7))),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
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
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.delete_outline, color: Colors.red[400]),
                    ),
                    child: _buildNotificationItem(notification, index),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "All caught up!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          const Text(
            "No new notifications for you.",
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, int index) {
    return InkWell(
      onTap: () => _markAsRead(index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: notification.isUnread ? const Color(0xFFBAE6FD) : const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
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
                color: notification.bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(notification.icon, color: notification.iconColor, size: 24),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color:  Color(0xFF0F172A),
                          fontSize: 15,
                        ),
                      ),
                      if (notification.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0284C7),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.time,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, size: 18, color: Color(0xFF94A3B8)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 120),
                        onSelected: (value) {
                          if (value == 'read') _markAsRead(index);
                          if (value == 'delete') _deleteNotification(index);
                        },
                        itemBuilder: (context) => [
                          if (notification.isUnread)
                            const PopupMenuItem(
                              value: 'read',
                              child: Row(
                                children: [
                                  Icon(Icons.done, size: 18),
                                  SizedBox(width: 8),
                                  Text("Mark as read", style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text("Delete", style: TextStyle(fontSize: 13, color: Colors.red)),
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
