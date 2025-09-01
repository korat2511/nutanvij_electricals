import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io' show Platform;

class LocationServiceOld {
  static const String _checkInLatKey = 'check_in_latitude';
  static const String _checkInLngKey = 'check_in_longitude';
  static const double _maxDistanceMeters = 1200.0;
  static StreamSubscription<Position>? _positionStreamSubscription;
  static Function(String)? onAutoPunchOut;
  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _maxRetryDelay = Duration(minutes: 5);
  static int _consecutiveTimeouts = 0;
  static Timer? _retryTimer;

  static Future<String> getCurrentAddress() async {
    try {
      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Failed to get location within 15 seconds');
      });

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Failed to get address within 15 seconds');
      });

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
      }

      return 'Address not found';
    } on TimeoutException {
      return 'Location request timed out. Please try again.';
    } catch (e) {
      return 'Error getting location: $e';
    }
  }

  static Future<void> saveCheckInLocation(double latitude, double longitude) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_checkInLatKey, latitude);
    await prefs.setDouble(_checkInLngKey, longitude);
  }

  static Future<Position?> getCheckInLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_checkInLatKey);
    final lng = prefs.getDouble(_checkInLngKey);
    
    if (lat != null && lng != null) {
      return Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
    return null;
  }

  static Future<void> clearCheckInLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_checkInLatKey);
    await prefs.remove(_checkInLngKey);
  }

  static Duration _calculateRetryDelay() {
    // Exponential backoff with jitter
    final baseDelay = Duration(seconds: 5 * (1 << _consecutiveTimeouts));
    final jitter = Duration(seconds: (DateTime.now().millisecondsSinceEpoch % 5));
    final delay = baseDelay + jitter;
    return delay > _maxRetryDelay ? _maxRetryDelay : delay;
  }
  //
  static Future<void> startLocationTracking() async {
    try {
      // Cancel any existing retry timer
      _retryTimer?.cancel();
      _retryTimer = null;
  //
      // Start location tracking with proper error handling
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
          timeLimit: _timeout, // Consistent timeout across platforms
        ),
      ).listen(
        (Position position) async {
          try {
            // Reset consecutive timeouts on successful position update
            _consecutiveTimeouts = 0;
  //
            final checkInLocation = await getCheckInLocation();
            if (checkInLocation != null) {
              final distance = Geolocator.distanceBetween(
                checkInLocation.latitude,
                checkInLocation.longitude,
                position.latitude,
                position.longitude,
              );
  //
              if (distance > _maxDistanceMeters) {
                // Stop tracking and trigger auto punch out
                stopLocationTracking();
                if (onAutoPunchOut != null) {
                  onAutoPunchOut!('away from site');
                }
              }
            }
          } catch (e) {
            print('Error processing position update: $e');
            // Don't stop tracking on processing errors
          }
        },
        onError: (error) {
          print('Location stream error: $error');
  //
          if (error is TimeoutException) {
            _consecutiveTimeouts++;
            print('Consecutive timeouts: $_consecutiveTimeouts');
  //
            // Stop current stream
            stopLocationTracking();
  //
            // Calculate retry delay with exponential backoff
            final retryDelay = _calculateRetryDelay();
            print('Retrying location tracking in ${retryDelay.inSeconds} seconds');
  //
            // Schedule retry
            _retryTimer = Timer(retryDelay, () {
              if (_consecutiveTimeouts < 5) { // Limit retries to prevent infinite loop
                startLocationTracking();
              } else {
                print('Max retries reached. Stopping location tracking.');
                stopLocationTracking();
                if (onAutoPunchOut != null) {
                  onAutoPunchOut!('location tracking failed');
                }
              }
            });
          }
        },
        cancelOnError: false, // Keep stream alive on errors
      );
    } catch (e) {
      print('Error starting location tracking: $e');
      // Attempt to restart tracking after a delay
      final retryDelay = _calculateRetryDelay();
      _retryTimer = Timer(retryDelay, startLocationTracking);
    }
  }
  //
  static void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _consecutiveTimeouts = 0;
  }
}