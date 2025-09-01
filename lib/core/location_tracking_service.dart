import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationTrackingService {
  static const platform = MethodChannel('com.nutanvij.nutanvij_electricals/location_service');
  StreamSubscription<Position>? _positionStream;
  Position? _lastStationaryPosition;
  DateTime? _stationaryStartTime;
  Timer? _stationaryTimer;
  final String userId;
  StreamSubscription<Position>? _wakeUpStream;
  bool _isTracking = false;

  LocationTrackingService(this.userId);

  Future<void> startTracking() async {
    if (_isTracking) return;
    _isTracking = true;

    try {
      // Start Android background service
      await platform.invokeMethod('startLocationService');
    } on PlatformException catch (e) {
      print('Failed to start background service: ${e.message}');
    }

    _lastStationaryPosition = null;
    _stationaryStartTime = null;
    _stationaryTimer?.cancel();
    _logEvent('start', position: _lastStationaryPosition);

    // // Start high accuracy location updates (assume permission already granted)
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        timeLimit: Duration(seconds: 30), // Force updates every 30 seconds
      ),
    ).listen(_onLocationUpdate);
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;
    _isTracking = false;
    //
    try {
      // Stop Android background service
      await platform.invokeMethod('stopLocationService');
    } on PlatformException catch (e) {
      print('Failed to stop background service: ${e.message}');
    }
    //
    _logEvent('stop', position: _lastStationaryPosition);
    _positionStream?.cancel();
    _positionStream = null;
    _stationaryTimer?.cancel();
    //
    // Start low-power wake-up listener
    _wakeUpStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.lowest,
        distanceFilter: 300,
        timeLimit: Duration(minutes: 5), // Check every 5 minutes
      ),
    ).listen(_onWakeUpMove);
  }

  void _onLocationUpdate(Position position) async {
    final now = DateTime.now();
    print('Location update at: $now Lat: ${position.latitude}, Lng: ${position.longitude}');
  //
    if (_lastStationaryPosition == null) {
      _lastStationaryPosition = position;
      _stationaryStartTime = now;
      log("_lastStationaryPosition 2 = $_lastStationaryPosition");
      log("_stationaryStartTime 2 = $_stationaryStartTime");
      _logEvent('first_location', position: position);
  //
      _stationaryTimer?.cancel();
      _stationaryTimer = Timer(const Duration(minutes: 5), () {
        _logEvent('stationary', position: position);
        stopTracking();
      });
      return;
    }
  //
    double distance = Geolocator.distanceBetween(
      _lastStationaryPosition!.latitude,
      _lastStationaryPosition!.longitude,
      position.latitude,
      position.longitude,
    );
  //
    if (distance < 30) {
      log("true");
      log("_lastStationaryPosition 3 = $_lastStationaryPosition");
      log("_stationaryStartTime 3 = $_stationaryStartTime");
      // User is stationary
    } else {
      // User is moving (distance >= 30)
      log("true > 30");
      _logEvent('moving', position: position);
      _lastStationaryPosition = position;
      _stationaryStartTime = now;
  //
      _stationaryTimer?.cancel();
      _stationaryTimer = Timer(const Duration(minutes: 5), () {
        _logEvent('stationary', position: position);
        stopTracking();
      });
    }
  }
  //
  void _onWakeUpMove(Position position) {
    // User has moved 300m+ after being stationary
    _wakeUpStream?.cancel();
    _wakeUpStream = null;
    _logEvent('moving', position: position);
    startTracking(); // Resume normal tracking
  }
  //
  void _logEvent(String eventType, {Position? position}) async {
    await FirebaseFirestore.instance
        .collection('user_locations')
        .doc(userId).set({
      'latitude': position?.latitude,
      'longitude': position?.longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'event_type': eventType,
      'device_time': DateTime.now().toIso8601String(),
    });
  //
    await FirebaseFirestore.instance
        .collection('user_location_history')
        .doc(userId).collection('routes').add({
      'latitude': position?.latitude,
      'longitude': position?.longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'event_type': eventType,
      'device_time': DateTime.now().toIso8601String(),
    });
  }
}