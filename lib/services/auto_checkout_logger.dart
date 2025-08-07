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

      await _firestore
          .collection('auto_checkout_logs')
          .add(logData);

      log('Auto checkout log saved: $action - $note');
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

  // Get logs for a specific user
  Future<List<Map<String, dynamic>>> getUserLogs({
    required String userId,
    int limit = 50,
  }) async {
    try {
      // Get all logs and filter by user in memory to avoid index requirement
      final querySnapshot = await _firestore
          .collection('auto_checkout_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit * 2) // Get more logs to filter from
          .get();

      // Filter user logs in memory
      final userLogs = querySnapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['userId'] == userId;
          })
          .take(limit)
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList();

      return userLogs;
    } catch (e) {
      log('Error getting user logs: $e');
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
} 