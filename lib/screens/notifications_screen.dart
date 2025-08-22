import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/notification_model.dart';
import '../services/notification_storage_service.dart';
import '../widgets/custom_app_bar.dart';
import '../screens/task/task_details_screen.dart';
import 'home/home_screen.dart';
import 'task/task_list_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await NotificationStorageService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      SnackBarUtils.showError(context, 'Failed to load notifications');
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() => _isRefreshing = true);
    await _loadNotifications();
    setState(() => _isRefreshing = false);
  }

  Future<void> _markAsRead(String notificationId) async {
    await NotificationStorageService.markAsRead(notificationId);
    await _loadNotifications();
    // Refresh app bar notification count
    _refreshAppBarCount();
  }

  Future<void> _markAllAsRead() async {
    await NotificationStorageService.markAllAsRead();
    await _loadNotifications();
    _refreshAppBarCount();
    SnackBarUtils.showSuccess(context, 'All notifications marked as read');
  }

  Future<void> _deleteNotification(String notificationId) async {
    await NotificationStorageService.deleteNotification(notificationId);
    await _loadNotifications();
    _refreshAppBarCount();
    SnackBarUtils.showSuccess(context, 'Notification deleted');
  }

  void _refreshAppBarCount() {
    // Refresh app bar notification count
    try {
      customAppBarKey.currentState?.refreshUnreadCount();
    } catch (e) {
      print('Error refreshing app bar count: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
            'Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NotificationStorageService.clearAllNotifications();
      await _loadNotifications();
      _refreshAppBarCount();
      SnackBarUtils.showSuccess(context, 'All notifications cleared');
    }
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read first
    await _markAsRead(notification.id);

    // Handle different notification types
    final data = notification.data;

    if (data.containsKey('screen')) {
      final screen = data['screen'];

      switch (screen) {
        case 'taskDetailsScreen':
          if (data.containsKey('task_id')) {
            NavigationUtils.push(
                context, TaskDetailsScreen(taskId: data['task_id']));
          }
          break;
        case 'taskListScreen':
          if (data.containsKey('site_id')) {
            NavigationUtils.push(
                context, TaskListScreen(siteId: data['site_id']));
          }
          break;
        case 'homeScreen':
          NavigationUtils.push(context, const HomeScreen());
          break;
        default:

          _showNotificationDetails(notification);
          break;
      }
    } else {

      if (data.containsKey('task_id')) {

        // NavigationUtils.push(context, TaskDetailsScreen(taskId: data['task_id']));
      } else if (data.containsKey('site_id')) {
        // NavigationUtils.push(context, SiteDetailsScreen(siteId: data['site_id']));
      } else {
        // Show notification details
        _showNotificationDetails(notification);
      }
    }
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (notification.body != null) ...[
              Text(notification.body!),
              const SizedBox(height: 16),
            ],
            Text(
              'Received: ${DateFormat('MMM dd, yyyy HH:mm').format(notification.timestamp)}',
              style: AppTypography.bodySmall.copyWith(color: Colors.grey),
            ),
            if (notification.data.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Data:',
                style: AppTypography.bodySmall
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  notification.data.toString(),
                  style: AppTypography.bodySmall,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isUnread = !notification.isRead;
    final timeAgo = _getTimeAgo(notification.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isUnread ? 2 : 1,
      color: isUnread ? Colors.blue.shade50 : Colors.white,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        onLongPress: () => _showNotificationOptions(notification),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight:
                                  isUnread ? FontWeight.w600 : FontWeight.w500,
                              color: isUnread ? Colors.black87 : Colors.black54,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification.body != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body!,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      timeAgo,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationOptions(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Details'),
              onTap: () {
                Navigator.of(context).pop();
                _showNotificationDetails(notification);
              },
            ),
            if (!notification.isRead)
              ListTile(
                leading: const Icon(Icons.mark_email_read),
                title: const Text('Mark as Read'),
                onTap: () {
                  Navigator.of(context).pop();
                  _markAsRead(notification.id);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                _deleteNotification(notification.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'task':
        return Colors.orange;
      case 'site':
        return Colors.green;
      case 'attendance':
        return Colors.blue;
      case 'leave':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'task':
        return Icons.assignment;
      case 'site':
        return Icons.location_on;
      case 'attendance':
        return Icons.access_time;
      case 'leave':
        return Icons.event_note;
      default:
        return Icons.notifications;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: CustomAppBar(
        onMenuPressed: () => NavigationUtils.pop(context),
        title: 'Notifications',
        showNotification: false,
        actions: [
          if (_notifications.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All Notifications'),
                    content: const Text(
                        'Are you sure you want to clear all notifications? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _clearAllNotifications();
                        },
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refreshNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(_notifications[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: AppTypography.headlineSmall.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see your notifications here when you receive them',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
