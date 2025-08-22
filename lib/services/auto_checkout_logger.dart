import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/site.dart';

class AutoCheckoutLogger {
  static AutoCheckoutLogger? _instance;
  static AutoCheckoutLogger get instance => _instance ??= AutoCheckoutLogger._();

  AutoCheckoutLogger._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Log auto checkout activity
  Future<void> logAutoCheckoutActivity({
    required String action,
    required String userId,
    required String userName,
    required Site? site,
    required Position? currentPosition,
    required double? distance,
    required int? maxRange,
    required String note,
    required bool isSuccess,
    String? errorMessage,
  }) async {
    try {
      final logData = {
        'action': action, // 'check_in', 'check_out', 'auto_checkout', 'location_check', 'app_start_check'
        'userId': userId,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'siteId': site?.id,
        'siteName': site?.name,
        'siteLatitude': site?.latitude,
        'siteLongitude': site?.longitude,
        'siteMaxRange': site?.maxRange,
        'currentLatitude': currentPosition?.latitude,
        'currentLongitude': currentPosition?.longitude,
        'distance': distance,
        'maxRange': maxRange,
        'isWithinRange': distance != null && maxRange != null ? distance <= maxRange : null,
        'note': note,
        'isSuccess': isSuccess,
        'errorMessage': errorMessage,
        'deviceInfo': {
          'platform': 'flutter',
          'timestamp': DateTime.now().toIso8601String(),
        },
      };

      // Log to both general collection and user-specific collection
      await Future.wait([
        // General collection for all logs
        _firestore
            .collection('auto_checkout_logs')
            .add(logData),
        
        // User-specific collection for easy filtering
        _firestore
            .collection('users')
            .doc(userId)
            .collection('auto_checkout_logs')
            .add(logData),
      ]);

      log('Auto checkout log saved: $action - $note for user: $userName ($userId)');
    } catch (e) {
      log('Error logging auto checkout activity: $e');
    }
  }

  // Log location check
  Future<void> logLocationCheck({
    required String userId,
    required String userName,
    required Site site,
    required Position currentPosition,
    required double distance,
    required int maxRange,
    required bool isWithinRange,
    required String context, // 'background', 'foreground', 'app_start'
  }) async {
    await logAutoCheckoutActivity(
      action: 'location_check',
      userId: userId,
      userName: userName,
      site: site,
      currentPosition: currentPosition,
      distance: distance,
      maxRange: maxRange,
      note: 'Location check in $context context - Distance: ${distance.round()}m, Max Range: ${maxRange}m, Within Range: $isWithinRange',
      isSuccess: true,
    );
  }

  // Log auto checkout trigger
  Future<void> logAutoCheckoutTrigger({
    required String userId,
    required String userName,
    required Site site,
    required Position currentPosition,
    required double distance,
    required int maxRange,
    required String context, // 'background', 'foreground', 'app_start'
  }) async {
    await logAutoCheckoutActivity(
      action: 'auto_checkout_trigger',
      userId: userId,
      userName: userName,
      site: site,
      currentPosition: currentPosition,
      distance: distance,
      maxRange: maxRange,
      note: 'Auto checkout triggered in $context context - Distance: ${distance.round()}m, Max Range: ${maxRange}m',
      isSuccess: true,
    );
  }

  // Log auto checkout success
  Future<void> logAutoCheckoutSuccess({
    required String userId,
    required String userName,
    required Site site,
    required Position? currentPosition,
    required double? distance,
    required int? maxRange,
    required String context,
  }) async {
    await logAutoCheckoutActivity(
      action: 'auto_checkout_success',
      userId: userId,
      userName: userName,
      site: site,
      currentPosition: currentPosition,
      distance: distance,
      maxRange: maxRange,
      note: 'Auto checkout completed successfully in $context context',
      isSuccess: true,
    );
  }

  // Log auto checkout error
  Future<void> logAutoCheckoutError({
    required String userId,
    required String userName,
    required Site? site,
    required Position? currentPosition,
    required double? distance,
    required int? maxRange,
    required String errorMessage,
    required String context,
  }) async {
    await logAutoCheckoutActivity(
      action: 'auto_checkout_error',
      userId: userId,
      userName: userName,
      site: site,
      currentPosition: currentPosition,
      distance: distance,
      maxRange: maxRange,
      note: 'Auto checkout error in $context context',
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  // Log monitoring start
  Future<void> logMonitoringStart({
    required String userId,
    required String userName,
    required Site site,
    required Position? currentPosition,
  }) async {
    await logAutoCheckoutActivity(
      action: 'monitoring_start',
      userId: userId,
      userName: userName,
      site: site,
      currentPosition: currentPosition,
      distance: null,
      maxRange: site.maxRange,
      note: 'Auto checkout monitoring started for site: ${site.name}',
      isSuccess: true,
    );
  }

  // Log monitoring stop
  Future<void> logMonitoringStop({
    required String userId,
    required String userName,
    required Site? site,
    required String reason, // 'manual_checkout', 'auto_checkout', 'app_terminated'
  }) async {
    await logAutoCheckoutActivity(
      action: 'monitoring_stop',
      userId: userId,
      userName: userName,
      site: site,
      currentPosition: null,
      distance: null,
      maxRange: site?.maxRange,
      note: 'Auto checkout monitoring stopped - Reason: $reason',
      isSuccess: true,
    );
  }

  // Log app start check
  Future<void> logAppStartCheck({
    required String userId,
    required String userName,
    required Site? site,
    required Position? currentPosition,
    required double? distance,
    required int? maxRange,
    required bool wasOutsideRange,
  }) async {
    await logAutoCheckoutActivity(
      action: 'app_start_check',
      userId: userId,
      userName: userName,
      site: site,
      currentPosition: currentPosition,
      distance: distance,
      maxRange: maxRange,
      note: 'App start check - Was outside range: $wasOutsideRange, Distance: ${distance?.round()}m, Max Range: ${maxRange}m',
      isSuccess: true,
    );
  }

  // Get logs for a specific user (from user-specific collection)
  Future<List<Map<String, dynamic>>> getUserLogs({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('auto_checkout_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      log('Error getting user logs: $e');
      return [];
    }
  }

  // Get error logs for a specific user
  Future<List<Map<String, dynamic>>> getUserErrorLogs({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('auto_checkout_logs')
          .where('isSuccess', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      log('Error getting user error logs: $e');
      return [];
    }
  }

  // Get logs for a specific user by action type
  Future<List<Map<String, dynamic>>> getUserLogsByAction({
    required String userId,
    required String action,
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('auto_checkout_logs')
          .where('action', isEqualTo: action)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      log('Error getting user logs by action: $e');
      return [];
    }
  }

  // Get logs for a specific site
  Future<List<Map<String, dynamic>>> getSiteLogs({
    required int siteId,
    int limit = 50,
  }) async {
    try {
      // Get all logs and filter by site in memory to avoid index requirement
      final querySnapshot = await _firestore
          .collection('auto_checkout_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit * 2) // Get more logs to filter from
          .get();

      // Filter site logs in memory
      final siteLogs = querySnapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['siteId'] == siteId;
          })
          .take(limit)
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList();

      return siteLogs;
    } catch (e) {
      log('Error getting site logs: $e');
      return [];
    }
  }

  // Get all logs
  Future<List<Map<String, dynamic>>> getAllLogs({
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('auto_checkout_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      log('Error getting all logs: $e');
      return [];
    }
  }

  // Get error logs
  Future<List<Map<String, dynamic>>> getErrorLogs({
    int limit = 50,
  }) async {
    try {
      // First, get all logs and filter in memory to avoid index requirement
      final querySnapshot = await _firestore
          .collection('auto_checkout_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit * 2) // Get more logs to filter from
          .get();

      // Filter error logs in memory
      final errorLogs = querySnapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['isSuccess'] == false;
          })
          .take(limit)
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList();

      return errorLogs;
    } catch (e) {
      log('Error getting error logs: $e');
      return [];
    }
  }

  // Get user statistics and summary
  Future<Map<String, dynamic>> getUserStatistics({
    required String userId,
    int days = 30,
  }) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('auto_checkout_logs')
          .where('timestamp', isGreaterThan: startDate)
          .get();

      final logs = querySnapshot.docs.map((doc) => doc.data()).toList();
      
      // Calculate statistics
      int totalLogs = logs.length;
      int successLogs = logs.where((log) => log['isSuccess'] == true).length;
      int errorLogs = logs.where((log) => log['isSuccess'] == false).length;
      
      // Count by action type
      Map<String, int> actionCounts = {};
      for (final log in logs) {
        final action = log['action'] as String? ?? 'unknown';
        actionCounts[action] = (actionCounts[action] ?? 0) + 1;
      }
      
      // Get recent errors
      final recentErrors = logs
          .where((log) => log['isSuccess'] == false)
          .take(10)
          .toList();
      
      return {
        'userId': userId,
        'period': '$days days',
        'totalLogs': totalLogs,
        'successLogs': successLogs,
        'errorLogs': errorLogs,
        'successRate': totalLogs > 0 ? (successLogs / totalLogs * 100).roundToDouble() : 0.0,
        'actionCounts': actionCounts,
        'recentErrors': recentErrors,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      log('Error getting user statistics: $e');
      return {
        'userId': userId,
        'error': e.toString(),
        'totalLogs': 0,
        'successLogs': 0,
        'errorLogs': 0,
        'successRate': 0.0,
        'actionCounts': {},
        'recentErrors': [],
      };
    }
  }

  // Get all users with recent activity
  Future<List<Map<String, dynamic>>> getActiveUsers({
    int days = 7,
  }) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      
      // Get all users who have logs in the specified period
      final querySnapshot = await _firestore
          .collection('auto_checkout_logs')
          .where('timestamp', isGreaterThan: startDate)
          .get();

      // Group by user
      Map<String, Map<String, dynamic>> userActivity = {};
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String? ?? 'unknown';
        final userName = data['userName'] as String? ?? 'Unknown User';
        
        if (!userActivity.containsKey(userId)) {
          userActivity[userId] = {
            'userId': userId,
            'userName': userName,
            'logCount': 0,
            'lastActivity': null,
            'hasErrors': false,
          };
        }
        
        userActivity[userId]!['logCount'] = (userActivity[userId]!['logCount'] as int) + 1;
        
        final timestamp = data['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final lastActivity = userActivity[userId]!['lastActivity'] as Timestamp?;
          if (lastActivity == null || timestamp.compareTo(lastActivity) > 0) {
            userActivity[userId]!['lastActivity'] = timestamp;
          }
        }
        
        if (data['isSuccess'] == false) {
          userActivity[userId]!['hasErrors'] = true;
        }
      }
      
      // Convert to list and sort by last activity
      final activeUsers = userActivity.values.toList();
      activeUsers.sort((a, b) {
        final aTime = a['lastActivity'] as Timestamp?;
        final bTime = b['lastActivity'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      return activeUsers;
    } catch (e) {
      log('Error getting active users: $e');
      return [];
    }
  }

  // Export user logs for analysis (CSV format)
  Future<String> exportUserLogs({
    required String userId,
    int days = 30,
  }) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('auto_checkout_logs')
          .where('timestamp', isGreaterThan: startDate)
          .orderBy('timestamp', descending: true)
          .get();

      final logs = querySnapshot.docs.map((doc) => doc.data()).toList();
      
      // Create CSV header
      String csv = 'Timestamp,Action,Success,Note,Error Message,Site Name,Distance,Max Range\n';
      
      // Add data rows
      for (final log in logs) {
        final timestamp = log['timestamp'] as Timestamp?;
        final timestampStr = timestamp?.toDate().toIso8601String() ?? 'Unknown';
        final action = log['action'] ?? 'Unknown';
        final isSuccess = log['isSuccess'] ?? false;
        final note = (log['note'] ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
        final errorMessage = (log['errorMessage'] ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
        final siteName = log['siteName'] ?? 'Unknown';
        final distance = log['distance']?.toString() ?? '';
        final maxRange = log['maxRange']?.toString() ?? '';
        
        csv += '$timestampStr,$action,$isSuccess,"$note","$errorMessage",$siteName,$distance,$maxRange\n';
      }
      
      return csv;
    } catch (e) {
      log('Error exporting user logs: $e');
      return 'Error: $e';
    }
  }

  // Get system-wide statistics
  Future<Map<String, dynamic>> getSystemStatistics({
    int days = 30,
  }) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      
      final querySnapshot = await _firestore
          .collection('auto_checkout_logs')
          .where('timestamp', isGreaterThan: startDate)
          .get();

      final logs = querySnapshot.docs.map((doc) => doc.data()).toList();
      
      // Calculate system statistics
      int totalLogs = logs.length;
      int successLogs = logs.where((log) => log['isSuccess'] == true).length;
      int errorLogs = logs.where((log) => log['isSuccess'] == false).length;
      
      // Count by action type
      Map<String, int> actionCounts = {};
      for (final log in logs) {
        final action = log['action'] as String? ?? 'unknown';
        actionCounts[action] = (actionCounts[action] ?? 0) + 1;
      }
      
      // Get unique users
      Set<String> uniqueUsers = {};
      for (final log in logs) {
        final userId = log['userId'] as String?;
        if (userId != null) {
          uniqueUsers.add(userId);
        }
      }
      
      // Get unique sites
      Set<String> uniqueSites = {};
      for (final log in logs) {
        final siteName = log['siteName'] as String?;
        if (siteName != null) {
          uniqueSites.add(siteName);
        }
      }
      
      return {
        'period': '$days days',
        'totalLogs': totalLogs,
        'successLogs': successLogs,
        'errorLogs': errorLogs,
        'successRate': totalLogs > 0 ? (successLogs / totalLogs * 100).roundToDouble() : 0.0,
        'uniqueUsers': uniqueUsers.length,
        'uniqueSites': uniqueSites.length,
        'actionCounts': actionCounts,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      log('Error getting system statistics: $e');
      return {
        'error': e.toString(),
        'totalLogs': 0,
        'successLogs': 0,
        'errorLogs': 0,
        'successRate': 0.0,
        'uniqueUsers': 0,
        'uniqueSites': 0,
        'actionCounts': {},
      };
    }
  }
} 