import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class LocationService {
  static const String _checkInLatKey = 'check_in_latitude';
  static const String _checkInLngKey = 'check_in_longitude';
  static const double _maxDistanceMeters = 1200.0;
  static StreamSubscription<Position>? _positionStreamSubscription;
  static Function(String)? onAutoPunchOut;

  static Future<bool> _requestBackgroundPermissions() async {
    if (Platform.isIOS) {
      // For iOS, we need to request "Always" permission for background tracking
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // Request "Always" permission for background tracking
      if (permission == LocationPermission.whileInUse) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always) {
          return false;
        }
      }
    } else {
      // Android permission handling
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // Request background location permission for Android 10+
      if (permission == LocationPermission.whileInUse) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always) {
          return false;
        }
      }

      // Request battery optimization exemption for Android
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 23) {
        final status = await Permission.ignoreBatteryOptimizations.status;
        if (!status.isGranted) {
          await Permission.ignoreBatteryOptimizations.request();
        }
      }
    }

    return true;
  }

  static Future<String> getCurrentAddress() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Location permission denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return 'Location permission permanently denied';
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
      }

      return 'Address not found';
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

  static Future<void> startLocationTracking() async {
    // Request all necessary permissions
    final hasPermissions = await _requestBackgroundPermissions();
    if (!hasPermissions) {
      return;
    }

    // Start location tracking
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
        timeLimit: Platform.isIOS ? const Duration(seconds: 30) : null, // iOS requires time limit
      ),
    ).listen((Position position) async {
      final checkInLocation = await getCheckInLocation();
      if (checkInLocation != null) {
        final distance = Geolocator.distanceBetween(
          checkInLocation.latitude,
          checkInLocation.longitude,
          position.latitude,
          position.longitude,
        );

        if (distance > _maxDistanceMeters) {
          // Stop tracking and trigger auto punch out
          stopLocationTracking();
          if (onAutoPunchOut != null) {
            onAutoPunchOut!('away from site');
          }
        }
      }
    });
  }

  static void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
} 