import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationProvider with ChangeNotifier {
  Position? _lastPosition;
  DateTime? _lastMovementTime;
  StreamSubscription<Position>? _positionStream;

  bool _isTracking = false;
  String? _userId;

  bool get isTracking => _isTracking;

  /// Start tracking for this user
  Future<void> startTracking(String userId) async {
    _userId = userId;

    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception("Location permission denied");
    }

    _isTracking = true;
    _lastMovementTime = DateTime.now();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // check every 50 meters
      ),
    ).listen((pos) => _handlePosition(pos));

    notifyListeners();
  }

  /// Stop tracking
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _isTracking = false;
    notifyListeners();
  }

  Future<void> _handlePosition(Position pos) async {
    if (_lastPosition == null) {
      _lastPosition = pos;
      _lastMovementTime = DateTime.now();
      await _saveLog(pos, "Movement start");
      return;
    }

    final distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      pos.latitude,
      pos.longitude,
    );

    print('➡️ lat ::${_lastPosition!.latitude} ');
    print('➡️ lng ::${_lastPosition!.longitude} ');
    final now = DateTime.now();

    if (distance >= 300 ||
        now.difference(_lastMovementTime!).inMinutes >= 2) {
      _lastMovementTime = now;
      _lastPosition = pos;
      await _saveLog(pos, "Periodic log (moved $distance m)");
    }

    // If no movement for 10 min
    if (distance < 50 &&
        now.difference(_lastMovementTime!).inMinutes >= 10) {
      await _saveLog(pos, "User idle, stop tracking");
      stopTracking();
    }
  }

  Future<void> _saveLog(Position pos, String note) async {
    if (_userId == null) return;

    String address = "Unknown";
    try {
      final placemarks =
      await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        address = "${p.street}, ${p.locality}, ${p.country}";
        print('address live tracking :: $address');
      }
    } catch (e) {
      log("Error fetching address: $e");
    }

    await FirebaseFirestore.instance
        .collection("users")
        .doc(_userId)
        .collection("location_track_history")
        .add({
      "lat": pos.latitude,
      "long": pos.longitude,
      "address": address,
      "time": DateTime.now().toIso8601String(),
      "note": note,
    });
  }
}
