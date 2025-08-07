import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ForegroundNotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  /// Show foreground notification
  static void showNotification(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      _showInAppNotification(context, message);
      // Refresh app bar notification count
      _refreshAppBarCount();
    } else {
      // Fallback to console log
      print('🔔 FOREGROUND NOTIFICATION: ${message.notification?.title ?? 'New notification'}');
      print('📝 Message body: ${message.notification?.body ?? 'No body'}');
      print('📊 Data: ${message.data}');
    }
  }

  /// Refresh app bar notification count
  static void _refreshAppBarCount() {
    // This will be called when new notifications are received
    // The app bar will automatically refresh when it rebuilds
  }
  
  /// Show in-app notification
  static void _showInAppNotification(BuildContext context, RemoteMessage message) {
    // Create a custom top notification using Navigator overlay
    final navigator = Navigator.of(context);
    final overlay = navigator.overlay;
    
    if (overlay != null) {
      late OverlayEntry overlayEntry;
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.notification?.title ?? 'New notification',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (message.notification?.body != null)
                          Text(
                            message.notification!.body!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      overlayEntry.remove();
                      _handleNotificationTap(message);
                    },
                    child: const Text(
                      'View',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      overlay.insert(overlayEntry);

      // Auto-remove after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        overlayEntry.remove();
      });
    } else {
      // Fallback to console log if overlay is not available
      print('🔔 FOREGROUND NOTIFICATION: ${message.notification?.title ?? 'New notification'}');
      print('📝 Message body: ${message.notification?.body ?? 'No body'}');
      print('📊 Data: ${message.data}');
    }
  }
  
  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    // Handle different types of notifications based on data
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
    } else {
      // Fallback to old logic
      if (data.containsKey('task_id')) {
        print('Navigate to task: ${data['task_id']}');
        // NavigationUtils.push(context, TaskDetailsScreen(taskId: data['task_id']));
      } else if (data.containsKey('site_id')) {
        print('Navigate to site: ${data['site_id']}');
        // NavigationUtils.push(context, SiteDetailsScreen(siteId: data['site_id']));
      } else {
        print('Default notification action');
      }
    }
  }
} 