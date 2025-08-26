import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import 'package:geolocator/geolocator.dart' as geo;

import '../../../core/utils/snackbar_utils.dart';

class LocationProvider with ChangeNotifier {
  geo.Position? _lastPosition;
  DateTime? _lastMovementTime;
  StreamSubscription<geo.Position>? _positionStream;

  bool _isTracking = false;
  String? _userId;

  bool get isTracking => _isTracking;

  /// Start tracking for this user
  Future<void> startTracking(String userId,BuildContext context) async {
    _userId = userId;

    final permission = await geo.Geolocator.requestPermission();
    if (permission == geo.LocationPermission.denied ||
        permission == geo.LocationPermission.deniedForever) {
      throw Exception("Location permission denied");
    }

    _isTracking = true;
    _lastMovementTime = DateTime.now();

    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 50, // check every 50 meters
      ),
    ).listen((pos) => _handlePosition(pos, context));

    notifyListeners();
  }

  /// Stop tracking
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _isTracking = false;
    notifyListeners();
  }

  Future<void> _handlePosition(geo.Position pos, BuildContext context) async {
    if (_lastPosition == null) {
      _lastPosition = pos;
      _lastMovementTime = DateTime.now();
      await _saveLog(pos, "Movement start", context);
      return;
    }

    final distance = geo.Geolocator.distanceBetween(
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
      await _saveLog(pos, "Periodic log (moved $distance m)",context);
    }

    // If no movement for 10 min
    if (distance < 50 &&
        now.difference(_lastMovementTime!).inMinutes >= 10) {
      await _saveLog(pos, "User idle, stop tracking", context);
      stopTracking();
    }
  }

  Future<void> _saveLog(geo.Position pos, String note, BuildContext context) async {
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

    SnackBarUtils.showSuccess(context, 'note :: $note Address :: $address');

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


