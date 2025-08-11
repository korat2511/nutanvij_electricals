import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/site.dart';
import '../services/foreground_notification_service.dart';
import '../services/auto_checkout_logger.dart';

class AutoCheckoutService {
  static AutoCheckoutService? _instance;
  static AutoCheckoutService get instance => _instance ??= AutoCheckoutService._();

  AutoCheckoutService._();

  Timer? _locationTimer;
  Timer? _loggingTimer;
  Position? _lastPosition;
  Site? _checkInSite;
  bool _isMonitoring = false;
  bool _isTracking = false; // Whether actively tracking movement
  BuildContext? _context;
  DateTime? _lastLogTime;
  DateTime? _lastMovementTime;
  Position? _lastMovementPosition;
  
  // Keys for SharedPreferences
  static const String _keyIsMonitoring = 'auto_checkout_monitoring';
  static const String _keyCheckInSiteId = 'auto_checkout_site_id';
  static const String _keyCheckInSiteName = 'auto_checkout_site_name';
  static const String _keyCheckInSiteLat = 'auto_checkout_site_lat';
  static const String _keyCheckInSiteLng = 'auto_checkout_site_lng';
  static const String _keyCheckInSiteMaxRange = 'auto_checkout_site_max_range';
  static const String _keyCheckInTime = 'auto_checkout_checkin_time';

  // Start monitoring location for auto checkout
  void startMonitoring(BuildContext context, Site checkInSite) async {
    log('🚀 Starting auto checkout monitoring...');
    log('Site: ${checkInSite.name}');
    log('Max Range: ${checkInSite.maxRange ?? 500}m');
    log('Site Coordinates: ${checkInSite.latitude}, ${checkInSite.longitude}');
    
    if (_isMonitoring) {
      log('⚠️ Already monitoring, skipping start');
      return;
    }
    
    _context = context;
    _checkInSite = checkInSite;
    _isMonitoring = true;
    _isTracking = true; // Start with active tracking
    
    log('✅ Monitoring state set - isMonitoring: $_isMonitoring, isTracking: $_isTracking');
    
    // Save monitoring state to SharedPreferences for background persistence
    await _saveMonitoringState();
    log('✅ Monitoring state saved to SharedPreferences');
    
    log('Auto checkout monitoring started for site: ${checkInSite.name} with max range: ${checkInSite.maxRange ?? 500}m');
    
    // Log monitoring start
    _logMonitoringStart();
    
    // Start intelligent tracking (delayed to avoid interference with attendance marking)
    Future.delayed(const Duration(seconds: 5), () {
      if (_isMonitoring) {
        _startIntelligentTracking();
        log('✅ Intelligent tracking started (delayed)');
        
        // Also check immediately to establish baseline
        _checkLocationAndAutoCheckout();
        
        // Log initial status
        _logPeriodicStatus();
      }
    });
    
    log('🎉 Auto checkout monitoring setup complete (delayed start)');
  }

  // Stop monitoring
  void stopMonitoring() async {
    if (!_isMonitoring) return;
    
    // Log monitoring stop
    _logMonitoringStop('manual_stop');
    
    _locationTimer?.cancel();
    _locationTimer = null;
    _loggingTimer?.cancel();
    _loggingTimer = null;
    _isMonitoring = false;
    _isTracking = false;
    _checkInSite = null;
    _lastPosition = null;
    _lastMovementPosition = null;
    _lastMovementTime = null;
    _context = null;
    _lastLogTime = null;
    
    // Clear monitoring state from SharedPreferences
    await _clearMonitoringState();
    
    log('Auto checkout monitoring stopped');
  }

  // Save monitoring state to SharedPreferences
  Future<void> _saveMonitoringState() async {
    if (_checkInSite == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsMonitoring, true);
    await prefs.setInt(_keyCheckInSiteId, _checkInSite!.id);
    await prefs.setString(_keyCheckInSiteName, _checkInSite!.name);
    await prefs.setString(_keyCheckInSiteLat, _checkInSite!.latitude);
    await prefs.setString(_keyCheckInSiteLng, _checkInSite!.longitude);
    await prefs.setInt(_keyCheckInSiteMaxRange, _checkInSite!.maxRange ?? 500);
    await prefs.setString(_keyCheckInTime, DateTime.now().toIso8601String());
  }

  // Clear monitoring state from SharedPreferences
  Future<void> _clearMonitoringState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsMonitoring);
    await prefs.remove(_keyCheckInSiteId);
    await prefs.remove(_keyCheckInSiteName);
    await prefs.remove(_keyCheckInSiteLat);
    await prefs.remove(_keyCheckInSiteLng);
    await prefs.remove(_keyCheckInSiteMaxRange);
    await prefs.remove(_keyCheckInTime);
  }

  // Load monitoring state from SharedPreferences
  Future<Site?> _loadMonitoringState() async {
    final prefs = await SharedPreferences.getInstance();
    final isMonitoring = prefs.getBool(_keyIsMonitoring) ?? false;
    
    if (!isMonitoring) return null;
    
    try {
      final siteId = prefs.getInt(_keyCheckInSiteId);
      final siteName = prefs.getString(_keyCheckInSiteName);
      final siteLat = prefs.getString(_keyCheckInSiteLat);
      final siteLng = prefs.getString(_keyCheckInSiteLng);
      final siteMaxRange = prefs.getInt(_keyCheckInSiteMaxRange);
      
      if (siteId != null && siteName != null && siteLat != null && siteLng != null) {
        return Site(
          id: siteId,
          name: siteName,
          latitude: siteLat,
          longitude: siteLng,
          address: '', // Not stored
          company: '', // Not stored
          status: 'Active',
          pinned: 0,
          siteImages: [],
          maxRange: siteMaxRange,
        );
      }
    } catch (e) {
      log('Error loading monitoring state: $e');
    }
    
    return null;
  }

  // Start intelligent tracking system
  void _startIntelligentTracking() {
    log('🔄 Starting intelligent tracking system...');
    
    // Start with 2-minute tracking interval
    _locationTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      log('⏰ Location check timer triggered');
      _checkLocationAndAutoCheckout();
    });
    
    // Start periodic logging every 2 minutes (only when tracking is active)
    _loggingTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_isTracking) {
        log('📝 Logging timer triggered');
        _logPeriodicStatus();
      } else {
        log('📝 Logging timer triggered (tracking paused - skipping location check)');
      }
    });
    
    log('✅ Intelligent tracking timers started (2-minute intervals)');
  }

  // Check if user is still within range and auto checkout if not
  Future<void> _checkLocationAndAutoCheckout() async {
    if (!_isMonitoring || _checkInSite == null) {
      log('Auto checkout check skipped - isMonitoring: $_isMonitoring, checkInSite: ${_checkInSite?.name}');
      return;
    }

    try {
      log('Starting auto checkout location check...');
      
      // Get current position with timeout and lower accuracy for faster response
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Use low accuracy for faster response
        timeLimit: const Duration(seconds: 10), // Reduced timeout
      );

      log('Current position obtained: ${currentPosition.latitude}, ${currentPosition.longitude}');

      // Calculate distance from check-in site
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        double.parse(_checkInSite!.latitude),
        double.parse(_checkInSite!.longitude),
      );

      final maxRange = _checkInSite!.maxRange ?? 500; // Default to 500m if not set
      
      log('Distance calculation - Distance: ${distance.round()}m, Max range: ${maxRange}m, Site: ${_checkInSite!.name}');

      // Check for movement and update tracking status
      _checkMovementAndUpdateTracking(currentPosition);

      // If user is outside the max range, auto checkout
      if (distance > maxRange) {
        log('🚨 AUTO CHECKOUT TRIGGERED - User is outside max range!');
        log('Distance: ${distance.round()}m, Max Range: ${maxRange}m');
        
        // Log auto checkout trigger (always log this important event)
        _logAutoCheckoutTrigger(currentPosition, distance, maxRange, 'background');
        
        await _performAutoCheckout();
      } else {
        log('User is within range - Distance: ${distance.round()}m, Max Range: ${maxRange}m');
        // Update last position for comparison
        _lastPosition = currentPosition;
      }
    } catch (e) {
      log('❌ Error in auto checkout location check: $e');
      // Log error (always log errors)
      _logAutoCheckoutError(e.toString(), 'background');
      // Don't auto checkout on location errors to avoid false positives
    }
  }

  // Check movement and update tracking status
  void _checkMovementAndUpdateTracking(Position currentPosition) {
    if (_lastMovementPosition == null) {
      // First position, initialize
      _lastMovementPosition = currentPosition;
      _lastMovementTime = DateTime.now();
      _isTracking = true;
      log('Initializing movement tracking');
      return;
    }

    // Calculate distance moved
    final distanceMoved = Geolocator.distanceBetween(
      _lastMovementPosition!.latitude,
      _lastMovementPosition!.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    final timeSinceLastMovement = DateTime.now().difference(_lastMovementTime!);
    const fiveMinutes = Duration(minutes: 5);

    log('Movement check - Distance moved: ${distanceMoved.round()}m, Time since last movement: ${timeSinceLastMovement.inMinutes}min');

    if (distanceMoved > 300) {
      // User moved more than 300m, start/continue tracking
      if (!_isTracking) {
        log('User moved more than 300m, resuming tracking');
        _isTracking = true;
        _restartTracking();
      }
      _lastMovementPosition = currentPosition;
      _lastMovementTime = DateTime.now();
    } else if (timeSinceLastMovement > fiveMinutes && _isTracking) {
      // User hasn't moved for more than 5 minutes, stop tracking
      log('User stationary for more than 5 minutes, stopping tracking');
      _isTracking = false;
      _stopTracking();
    }
  }

  // Restart tracking with 2-minute intervals
  void _restartTracking() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _checkLocationAndAutoCheckout();
    });
    log('Location tracking restarted with 2-minute intervals');
  }

  // Stop tracking (but keep monitoring active)
  void _stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    log('Location tracking stopped - user stationary (logging continues)');
  }

  // Log periodic status every 5 minutes
  Future<void> _logPeriodicStatus() async {
    if (!_isMonitoring || _checkInSite == null) return;

    try {
      // Get current position
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Calculate distance
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        double.parse(_checkInSite!.latitude),
        double.parse(_checkInSite!.longitude),
      );

      final maxRange = _checkInSite!.maxRange ?? 500;
      final isWithinRange = distance <= maxRange;
      
      // Log periodic status
      _logLocationCheck(currentPosition, distance, maxRange, isWithinRange, 'periodic');
      
      // Update last log time
      _lastLogTime = DateTime.now();
      
      log('Periodic status logged - Distance: ${distance.round()}m, Within Range: $isWithinRange');
    } catch (e) {
      log('Error in periodic status logging: $e');
      _logAutoCheckoutError(e.toString(), 'periodic');
    }
  }

  // Background location check (called when app is in background)
  Future<void> checkLocationInBackground() async {
    if (!_isMonitoring || _checkInSite == null) return;
    
    log('Background location check for auto checkout');
    
    try {
      // Get current position
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Calculate distance
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        double.parse(_checkInSite!.latitude),
        double.parse(_checkInSite!.longitude),
      );

      final maxRange = _checkInSite!.maxRange ?? 500;
      
      // Check movement and update tracking status
      _checkMovementAndUpdateTracking(currentPosition);
      
      // Check if auto checkout needed (only log important events)
      if (distance > maxRange) {
        _logAutoCheckoutTrigger(currentPosition, distance, maxRange, 'foreground');
        await _performAutoCheckout();
      }
    } catch (e) {
      log('Error in background location check: $e');
      _logAutoCheckoutError(e.toString(), 'foreground');
    }
  }

  // Perform the actual auto checkout
  Future<void> _performAutoCheckout() async {
    try {
      log('🔄 Starting auto checkout process...');
      
      // Get user provider from global context if available
      UserProvider? userProvider;
      if (_context != null && _context!.mounted) {
        userProvider = Provider.of<UserProvider>(_context!, listen: false);
        log('Got user provider from context');
      } else {
        // Try to get from global navigator context
        final navigatorContext = ForegroundNotificationService.navigatorKey.currentContext;
        if (navigatorContext != null) {
          userProvider = Provider.of<UserProvider>(navigatorContext, listen: false);
          log('Got user provider from global navigator context');
        }
      }
      
      if (userProvider == null) {
        log('❌ No user provider available for auto checkout');
        return;
      }
      
      final user = userProvider.user;
      if (user == null) {
        log('❌ No user data available for auto checkout');
        return;
      }

      log('✅ User found: ${user.data.name}');
      
      // Get context for API calls
      final context = _context ?? ForegroundNotificationService.navigatorKey.currentContext;
      if (context == null) {
        throw Exception('No context available for API call');
      }
      
      // Check if user is actually checked in before attempting auto checkout
      try {
        final attendanceData = await ApiService().attendanceCheck(context, user.data.apiToken);
        if (attendanceData != null && attendanceData['flag'] == 'check_out') {
          log('✅ User is already checked out - stopping monitoring');
          stopMonitoring();
          return;
        }
        log('✅ User is checked in - proceeding with auto checkout');
      } catch (e) {
        log('⚠️ Could not verify attendance status: $e');
        // Continue with auto checkout anyway
      }
      
      log('🔄 Calling API for auto checkout...');

      // Get current location and address for auto checkout
      log('🔄 Getting current location for auto checkout...');
      
      Position currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium, // Use medium accuracy for faster response
          timeLimit: const Duration(seconds: 15), // Increased timeout
        );
        log('✅ Current position obtained: ${currentPosition.latitude}, ${currentPosition.longitude}');
      } catch (e) {
        log('❌ Failed to get current position: $e');
        // Use last known position if available
        if (_lastPosition != null) {
          currentPosition = _lastPosition!;
          log('⚠️ Using last known position: ${currentPosition.latitude}, ${currentPosition.longitude}');
        } else {
          // If no position available, use default coordinates
          currentPosition = Position(
            latitude: 0.0,
            longitude: 0.0,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );
          log('⚠️ Using default position (0,0)');
        }
      }
      
      // Get address for the current location with timeout
      final address = await _getAddressWithTimeout(currentPosition);
      
      try {
        log('🔄 Making API call with data:');
        log('  - API Token: ${user.data.apiToken.substring(0, 10)}...');
        log('  - Type: check_out');
        log('  - Latitude: ${currentPosition.latitude}');
        log('  - Longitude: ${currentPosition.longitude}');
        log('  - Address: $address');
        
        await ApiService().saveAttendance(
          context: context,
          apiToken: user.data.apiToken,
          type: 'check_out',
          latitude: currentPosition.latitude.toString(),
          longitude: currentPosition.longitude.toString(),
          address: address,
          imagePath: '', // No image for auto checkout
          siteId: null,
        );
        log('✅ API call successful');
      } catch (apiError) {
        log('❌ API call failed: $apiError');
        log('❌ API error type: ${apiError.runtimeType}');
        log('❌ API error details: ${apiError.toString()}');
        
        // Check if it's a specific API error
        if (apiError.toString().contains('already checked out') || 
            apiError.toString().contains('not checked in')) {
          log('✅ User already checked out or not checked in - stopping monitoring');
          stopMonitoring();
          return; // Don't treat this as an error
        }
        // Re-throw other API errors
        rethrow;
      }

      // Log auto checkout success
      _logAutoCheckoutSuccess('background');

      // Stop monitoring after successful auto checkout
      log('🔄 Stopping monitoring after successful auto checkout');
      stopMonitoring();

      // Show notification to user
      if (_context != null && _context!.mounted) {
        SnackBarUtils.showInfo(
          _context!,
          'Auto checkout: You moved outside the site range (${_checkInSite?.name ?? "Unknown site"})',
        );
        log('✅ Notification shown to user');
      }

      log('🎉 Auto checkout completed successfully');
    } catch (e) {
      log('❌ Error during auto checkout: $e');
      // Log error
      _logAutoCheckoutError(e.toString(), 'background');
      // Don't stop monitoring on error, let it retry
    }
  }

  // Check if monitoring is active
  bool get isMonitoring => _isMonitoring;

  // Get the current check-in site
  Site? get checkInSite => _checkInSite;

  // Manually trigger auto checkout (for testing or manual override)
  Future<void> manualAutoCheckout(BuildContext context) async {
    if (!_isMonitoring) {
      SnackBarUtils.showError(context, 'No active monitoring to trigger auto checkout');
      return;
    }
    
    log('🔧 Manual auto checkout triggered');
    await _performAutoCheckout();
  }

  // Force trigger auto checkout for testing (bypasses distance check)
  Future<void> forceAutoCheckoutForTesting(BuildContext context) async {
    log('🧪 Force auto checkout for testing');
    
    if (_checkInSite == null) {
      log('❌ No check-in site available for testing');
      return;
    }
    
    // Temporarily set a very small max range to trigger auto checkout
    final originalMaxRange = _checkInSite!.maxRange;
    _checkInSite = _checkInSite!.copyWith(maxRange: 1); // 1 meter range
    
    log('🔄 Triggering auto checkout with 1m range for testing');
    await _checkLocationAndAutoCheckout();
    
    // Restore original max range
    _checkInSite = _checkInSite!.copyWith(maxRange: originalMaxRange);
  }

  // Test auto checkout directly (bypasses all checks)
  Future<void> testAutoCheckoutDirectly(BuildContext context) async {
    log('🧪 Testing auto checkout directly');
    
    // Set context for testing
    _context = context;
    
    // Create a dummy site for testing
    final testSite = Site(
      id: 999,
      name: 'Test Site',
      latitude: '21.2991211',
      longitude: '72.9013905',
      address: 'Test Address',
      company: 'Test Company',
      status: 'Active',
      pinned: 0,
      siteImages: [],
      maxRange: 500,
    );
    _checkInSite = testSite;
    
    log('🔄 Testing auto checkout with dummy site');
    await _performAutoCheckout();
  }

  // Manually trigger a location check for testing
  Future<void> triggerLocationCheckForTesting() async {
    log('🧪 Manual location check for testing');
    await _checkLocationAndAutoCheckout();
  }

  // Get address with timeout and fallback
  Future<String> _getAddressWithTimeout(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude,
      ).timeout(
        const Duration(seconds: 8), // Shorter timeout for geocoding
        onTimeout: () {
          log('⚠️ Geocoding timeout, using fallback address');
          return [];
        },
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = '${placemark.street}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}';
        log('✅ Address obtained: $address');
        return address;
      } else {
        log('⚠️ No placemarks found, using fallback address');
        return 'Auto checkout - moved outside site range';
      }
    } catch (e) {
      log('⚠️ Could not get address: $e');
      return 'Auto checkout - moved outside site range';
    }
  }





  // Helper method to get user info for logging
  Map<String, String> _getUserInfo() {
    try {
      UserProvider? userProvider;
      if (_context != null && _context!.mounted) {
        userProvider = Provider.of<UserProvider>(_context!, listen: false);
      } else {
        final navigatorContext = ForegroundNotificationService.navigatorKey.currentContext;
        if (navigatorContext != null) {
          userProvider = Provider.of<UserProvider>(navigatorContext, listen: false);
        }
      }
      
      if (userProvider?.user != null) {
        return {
          'userId': userProvider!.user!.data.id.toString(),
          'userName': userProvider.user!.data.name,
        };
      }
    } catch (e) {
      log('Error getting user info for logging: $e');
    }
    
    return {'userId': 'unknown', 'userName': 'Unknown User'};
  }

  // Log monitoring start
  void _logMonitoringStart() {
    if (_checkInSite == null) return;
    
    final userInfo = _getUserInfo();
    AutoCheckoutLogger.instance.logMonitoringStart(
      userId: userInfo['userId']!,
      userName: userInfo['userName']!,
      site: _checkInSite!,
      currentPosition: _lastPosition,
    );
  }

  // Log monitoring stop
  void _logMonitoringStop(String reason) {
    final userInfo = _getUserInfo();
    AutoCheckoutLogger.instance.logMonitoringStop(
      userId: userInfo['userId']!,
      userName: userInfo['userName']!,
      site: _checkInSite,
      reason: reason,
    );
  }

  // Log location check
  void _logLocationCheck(Position currentPosition, double distance, int maxRange, bool isWithinRange, String context) {
    if (_checkInSite == null) return;
    
    final userInfo = _getUserInfo();
    AutoCheckoutLogger.instance.logLocationCheck(
      userId: userInfo['userId']!,
      userName: userInfo['userName']!,
      site: _checkInSite!,
      currentPosition: currentPosition,
      distance: distance,
      maxRange: maxRange,
      isWithinRange: isWithinRange,
      context: context,
    );
  }

  // Log auto checkout trigger
  void _logAutoCheckoutTrigger(Position currentPosition, double distance, int maxRange, String context) {
    if (_checkInSite == null) return;
    
    final userInfo = _getUserInfo();
    AutoCheckoutLogger.instance.logAutoCheckoutTrigger(
      userId: userInfo['userId']!,
      userName: userInfo['userName']!,
      site: _checkInSite!,
      currentPosition: currentPosition,
      distance: distance,
      maxRange: maxRange,
      context: context,
    );
  }

  // Log auto checkout success
  void _logAutoCheckoutSuccess(String context) {
    if (_checkInSite == null) return;
    
    final userInfo = _getUserInfo();
    AutoCheckoutLogger.instance.logAutoCheckoutSuccess(
      userId: userInfo['userId']!,
      userName: userInfo['userName']!,
      site: _checkInSite!,
      currentPosition: _lastPosition,
      distance: null, // Will be calculated if needed
      maxRange: _checkInSite!.maxRange,
      context: context,
    );
  }

  // Log auto checkout error
  void _logAutoCheckoutError(String errorMessage, String context) {
    final userInfo = _getUserInfo();
    AutoCheckoutLogger.instance.logAutoCheckoutError(
      userId: userInfo['userId']!,
      userName: userInfo['userName']!,
      site: _checkInSite,
      currentPosition: _lastPosition,
      distance: null,
      maxRange: _checkInSite?.maxRange,
      errorMessage: errorMessage,
      context: context,
    );
  }

  // Log app start check
  void _logAppStartCheck(Site site, Position currentPosition, double distance, int maxRange, bool wasOutsideRange) {
    final userInfo = _getUserInfo();
    AutoCheckoutLogger.instance.logAppStartCheck(
      userId: userInfo['userId']!,
      userName: userInfo['userName']!,
      site: site,
      currentPosition: currentPosition,
      distance: distance,
      maxRange: maxRange,
      wasOutsideRange: wasOutsideRange,
    );
  }

  // Check for auto checkout when app starts (called from main.dart or splash screen)
  Future<void> checkForAutoCheckoutOnAppStart(BuildContext context) async {
    try {
      // Check if user is exempted from location checking
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user != null && user.data.isCheckInExmpted == 1) {
        log('User is exempted from location checking, skipping auto checkout monitoring');
        // Clear any existing monitoring state for exempted users
        await _clearMonitoringState();
        return;
      }
      
      // Load monitoring state from SharedPreferences
      final savedSite = await _loadMonitoringState();
      
      if (savedSite != null) {
        log('Found saved auto checkout monitoring for site: ${savedSite.name}');
        
        // Check current location against saved site
        final currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium, // Use medium accuracy for faster response
          timeLimit: const Duration(seconds: 15), // Increased timeout
        );
        
        final distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          double.parse(savedSite.latitude),
          double.parse(savedSite.longitude),
        );
        
        final maxRange = savedSite.maxRange ?? 500;
        log('Distance from saved check-in site: ${distance.round()}m, Max range: ${maxRange}m');
        
        if (distance > maxRange) {
          log('User is outside max range on app start, performing auto checkout');
          
          // Log app start check (always log this important event)
          _logAppStartCheck(savedSite, currentPosition, distance, maxRange, true);
          
          // Set context for API call
          _context = context;
          _checkInSite = savedSite;
          
          // Perform auto checkout
          await _performAutoCheckout();
          
          // Show notification to user
          if (context.mounted) {
            SnackBarUtils.showInfo(
              context,
              'Auto checkout: You were outside the site range when the app started (${savedSite.name})',
            );
          }
        } else {
          log('User is within range on app start, continuing monitoring');
          
          // Log app start check (always log this important event)
          _logAppStartCheck(savedSite, currentPosition, distance, maxRange, false);
          
          // Restart monitoring with saved site
          _checkInSite = savedSite;
          _isMonitoring = true;
          _isTracking = true; // Start with active tracking
          _context = context;
          
          // Start intelligent tracking
          _startIntelligentTracking();
        }
      } else {
        log('No saved auto checkout monitoring found');
      }
    } catch (e) {
      log('Error checking for auto checkout on app start: $e');
      // Clear any corrupted state
      await _clearMonitoringState();
    }
  }

  // Perform auto checkout from background (called when app is in background)
  Future<void> performBackgroundAutoCheckout() async {
    try {
      log('🔄 Background auto checkout check...');
      
      // Load monitoring state from SharedPreferences
      final savedSite = await _loadMonitoringState();
      
      if (savedSite == null) {
        log('No saved monitoring state for background auto checkout');
        return;
      }
      
      log('Found saved monitoring for site: ${savedSite.name}');
      
      // Get current location with lower accuracy for faster response
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Use low accuracy for faster response
        timeLimit: const Duration(seconds: 8), // Shorter timeout for background
      );
      
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        double.parse(savedSite.latitude),
        double.parse(savedSite.longitude),
      );
      
      final maxRange = savedSite.maxRange ?? 500;
      log('Background check - Distance: ${distance.round()}m, Max range: ${maxRange}m');
      
      if (distance > maxRange) {
        log('🚨 BACKGROUND AUTO CHECKOUT TRIGGERED!');
        
        // Set context for API call (use global navigator context)
        final context = ForegroundNotificationService.navigatorKey.currentContext;
        if (context != null) {
          _context = context;
          _checkInSite = savedSite;
          
          // Perform auto checkout
          await _performAutoCheckout();
          
          // Show notification to user
          if (_context != null && _context!.mounted) {
            SnackBarUtils.showInfo(
              _context!,
              'Auto checkout: You moved outside the site range while the app was in background (${savedSite.name})',
            );
          }
        } else {
          log('❌ No context available for background auto checkout');
          _logAutoCheckoutError('No context available for background auto checkout', 'background');
        }
      } else {
        log('User is within range in background - continuing monitoring');
      }
    } catch (e) {
      log('❌ Error in background auto checkout: $e');
      // Don't clear state on background errors to avoid losing monitoring
    }
  }


} 