import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/utils/snackbar_utils.dart';
import 'foreground_notification_service.dart';
import 'notification_storage_service.dart';
import '../models/notification_model.dart';
import '../firebase_options.dart';
import '../widgets/custom_app_bar.dart';

class NotificationPermissionService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Request notification permissions for both Android and iOS
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        return await _requestAndroidPermission(context);
      } else if (Platform.isIOS) {
        return await _requestIOSPermission(context);
      }
      return false;
    } catch (e) {
      // Check if context is still valid before showing error
      if (context.mounted) {
        SnackBarUtils.showError(context, 'Failed to request notification permission: $e');
      }
      return false;
    }
  }

  /// Request notification permission for Android
  static Future<bool> _requestAndroidPermission(BuildContext context) async {
    try {
      // Check if permission is already granted
      PermissionStatus status = await Permission.notification.status;
      
      if (status.isGranted) {
        return true;
      }

      // Request permission
      status = await Permission.notification.request();
      
      if (status.isGranted) {
        if (context.mounted) {
          SnackBarUtils.showSuccess(context, 'Notification permission granted');
        }
        return true;
      } else if (status.isDenied) {
        if (context.mounted) {
          SnackBarUtils.showError(context, 'Notification permission denied');
        }
        return false;
      } else if (status.isPermanentlyDenied) {
        // Show dialog to open app settings
        bool shouldOpenSettings = await _showPermissionDialog(context);
        if (shouldOpenSettings) {
          await openAppSettings();
        }
        return false;
      }
      
      return false;
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to request Android notification permission: $e');
      return false;
    }
  }

  /// Request notification permission for iOS
  static Future<bool> _requestIOSPermission(BuildContext context) async {
    try {
      // Request authorization
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (context.mounted) {
          SnackBarUtils.showSuccess(context, 'Notification permission granted');
        }
        return true;
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (context.mounted) {
          SnackBarUtils.showError(context, 'Notification permission denied');
        }
        return false;
      } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        if (context.mounted) {
          SnackBarUtils.showError(context, 'Notification permission not determined');
        }
        return false;
      }
      
      return false;
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to request iOS notification permission: $e');
      return false;
    }
  }

  /// Show dialog to open app settings when permission is permanently denied
  static Future<bool> _showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notification Permission Required'),
          content: const Text(
            'To receive important notifications, please enable notification permission in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Check if notification permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    try {
      if (Platform.isAndroid) {
        PermissionStatus status = await Permission.notification.status;
        return status.isGranted;
      } else if (Platform.isIOS) {
        NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
        return settings.authorizationStatus == AuthorizationStatus.authorized;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get FCM token
  static Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      return null;
    }
  }

  /// Configure FCM for background messages
  static void configureBackgroundMessage() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Configure FCM for foreground messages
  static void configureForegroundMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground messages here
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        
        // Save notification to storage
        _saveNotification(message);
        
        // Show in-app notification for foreground messages
        _showForegroundNotification(message);
      }
    });
  }

  /// Save notification to local storage
  static void _saveNotification(RemoteMessage message) {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body,
        data: message.data,
        timestamp: DateTime.now(),
        type: _getNotificationType(message.data),
      );
      
      NotificationStorageService.saveNotification(notification);
      
      // Refresh app bar notification count
      _refreshAppBarCount();
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  /// Refresh app bar notification count
  static void _refreshAppBarCount() {
    try {
      customAppBarKey.currentState?.refreshUnreadCount();
    } catch (e) {
      print('Error refreshing app bar count: $e');
    }
  }

  /// Determine notification type from data
  static String? _getNotificationType(Map<String, dynamic> data) {
    if (data.containsKey('task_id')) return 'task';
    if (data.containsKey('site_id')) return 'site';
    if (data.containsKey('attendance')) return 'attendance';
    if (data.containsKey('leave')) return 'leave';
    return null;
  }

  /// Show in-app notification for foreground messages
  static void _showForegroundNotification(RemoteMessage message) {
    // Use the foreground notification service
    ForegroundNotificationService.showNotification(message);
  }

  /// Subscribe to topics
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
      print('Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from topics
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
      print('Failed to unsubscribe from topic: $e');
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');
  
  if (message.notification != null) {
    print('Message also contained a notification: ${message.notification}');
    
    // Save notification to storage
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body,
        data: message.data,
        timestamp: DateTime.now(),
        type: _getNotificationTypeFromData(message.data),
      );
      
      await NotificationStorageService.saveNotification(notification);
    } catch (e) {
      print('Error saving background notification: $e');
    }
  }
}

// Handle notification tap when app is opened from background
@pragma('vm:entry-point')
Future<void> _handleNotificationTap(RemoteMessage message) async {
  print('Handling notification tap: ${message.data}');
  
  final data = message.data;
  if (data.containsKey('screen')) {
    final screen = data['screen'];
    
    switch (screen) {
      case 'taskDetailsScreen':
        if (data.containsKey('task_id')) {
          print('Navigate to task details: ${data['task_id']}');
          // NavigationUtils.push(context, TaskDetailsScreen(taskId: data['task_id']));
        }
        break;
      case 'siteDetailsScreen':
        if (data.containsKey('site_id')) {
          print('Navigate to site details: ${data['site_id']}');
          // NavigationUtils.push(context, SiteDetailsScreen(siteId: data['site_id']));
        }
        break;
      case 'attendanceScreen':
        print('Navigate to attendance screen');
        // NavigationUtils.push(context, AttendanceScreen());
        break;
      case 'leaveScreen':
        print('Navigate to leave screen');
        // NavigationUtils.push(context, LeaveScreen());
        break;
      default:
        print('Unknown screen: $screen');
        break;
    }
  }
}

// Helper function for background handler
String? _getNotificationTypeFromData(Map<String, dynamic> data) {
  if (data.containsKey('task_id')) return 'task';
  if (data.containsKey('site_id')) return 'site';
  if (data.containsKey('attendance')) return 'attendance';
  if (data.containsKey('leave')) return 'leave';
  return null;
} 