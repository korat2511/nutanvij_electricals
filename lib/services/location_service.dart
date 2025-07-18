import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

enum LocationErrorType {
  permissionDenied,
  permissionDeniedForever,
  locationServiceDisabled,
  timeout,
  networkError,
  unknown,
}

class LocationResult {
  final String? address;
  final Position? position;
  final LocationErrorType? errorType;
  final String? errorMessage;

  LocationResult({
    this.address,
    this.position,
    this.errorType,
    this.errorMessage,
  });

  bool get isSuccess => address != null && position != null;
  bool get hasError => errorType != null;
    }

class LocationService {
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
                }
              }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  static Future<LocationResult> getCurrentAddressWithRetry() async {
    try {
      // Get current position
      Position position = await getCurrentPosition();

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
        return LocationResult(address: address, position: position);
      }

      return LocationResult(
        address: 'Address not found',
        position: position,
      );
    } catch (e) {
      debugPrint('Error getting address: $e');
      return _handleLocationError(e);
    }
  }

  static Future<String> getCurrentAddress() async {
    try {
      // Get current position
      Position position = await getCurrentPosition();

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
      debugPrint('Error getting address: $e');
      return 'Address not available';
    }
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationPermission> getLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  static LocationResult _handleLocationError(dynamic error) {
    String errorMessage = error.toString();
    
    if (errorMessage.contains('Location services are disabled')) {
      return LocationResult(
        errorType: LocationErrorType.locationServiceDisabled,
        errorMessage: 'Location services are disabled. Please enable location services in your device settings.',
      );
    } else if (errorMessage.contains('Location permissions are denied')) {
      return LocationResult(
        errorType: LocationErrorType.permissionDenied,
        errorMessage: 'Location permission is required. Please grant location permission.',
      );
    } else if (errorMessage.contains('permanently denied')) {
      return LocationResult(
        errorType: LocationErrorType.permissionDeniedForever,
        errorMessage: 'Location permission is permanently denied. Please enable it in device settings.',
      );
    } else if (errorMessage.contains('timeout') || errorMessage.contains('time limit')) {
      return LocationResult(
        errorType: LocationErrorType.timeout,
        errorMessage: 'Location request timed out. Please try again.',
      );
    } else if (errorMessage.contains('network') || errorMessage.contains('connection')) {
      return LocationResult(
        errorType: LocationErrorType.networkError,
        errorMessage: 'Network error. Please check your internet connection and try again.',
      );
    } else {
      return LocationResult(
        errorType: LocationErrorType.unknown,
        errorMessage: 'Failed to get location. Please try again.',
      );
    }
  }

  static Future<bool> isWithinDistance({
    required double userLatitude,
    required double userLongitude,
    required String siteLatitude,
    required String siteLongitude,
    required double maxDistanceInMeters,
  }) async {
    try {
      final siteLat = double.parse(siteLatitude);
      final siteLng = double.parse(siteLongitude);
      
      final distanceInMeters = Geolocator.distanceBetween(
        userLatitude,
        userLongitude,
        siteLat,
        siteLng,
      );

      return distanceInMeters <= maxDistanceInMeters;
    } catch (e) {
      debugPrint('Error calculating distance: $e');
      return false;
    }
  }
} 