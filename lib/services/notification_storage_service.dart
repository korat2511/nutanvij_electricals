import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationStorageService {
  static const String _storageKey = 'notifications';
  static const int _maxNotifications = 100; // Keep last 100 notifications

  /// Save notification to local storage
  static Future<void> saveNotification(NotificationModel notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = await getNotifications();
      
      // Add new notification at the beginning
      notifications.insert(0, notification);
      
      // Keep only the last _maxNotifications
      if (notifications.length > _maxNotifications) {
        notifications.removeRange(_maxNotifications, notifications.length);
      }
      
      // Convert to JSON and save
      final notificationsJson = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(notificationsJson));
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  /// Get all notifications from local storage
  static Future<List<NotificationModel>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_storageKey);
      
      if (notificationsJson != null) {
        final List<dynamic> jsonList = jsonDecode(notificationsJson);
        return jsonList.map((json) => NotificationModel.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final notifications = await getNotifications();
      final index = notifications.indexWhere((n) => n.id == notificationId);
      
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        await _saveNotifications(notifications);
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final notifications = await getNotifications();
      final updatedNotifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
      await _saveNotifications(updatedNotifications);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final notifications = await getNotifications();
      notifications.removeWhere((n) => n.id == notificationId);
      await _saveNotifications(notifications);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  /// Get unread notifications count
  static Future<int> getUnreadCount() async {
    try {
      final notifications = await getNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Save notifications list
  static Future<void> _saveNotifications(List<NotificationModel> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(notificationsJson));
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }
} 