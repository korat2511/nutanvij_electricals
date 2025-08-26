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

  Timer? _testTimer; // 🔹 new timer

  bool _isTracking = false;
  String? _userId;
  bool _isIdle = false; // Track idle state

  bool get isTracking => _isTracking;

  /// Start tracking
  Future<void> startTracking(String userId, BuildContext context) async {
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

/*    // 🔹 TEST MODE: show log every 5 seconds
    _testTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_lastPosition != null) {
        await _saveLog(_lastPosition!, "5-sec test log", context);
      }
    });*/

    notifyListeners();
  }

  /// Stop tracking
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _isTracking = false;
    _isIdle = false;
    notifyListeners();
  }

  Future<void> _handlePosition(
      geo.Position pos, BuildContext context) async {
    final now = DateTime.now();

    if (_lastPosition == null) {
      _lastPosition = pos;
      _lastMovementTime = now;
      await _saveLog(pos, "Movement start", context);
      return;
    }

    final distance = geo.Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      pos.latitude,
      pos.longitude,
    );

    // 🔹 If user was idle but now moved 300m → resume logging
    if (_isIdle && distance >= 300) {
      _isIdle = false;
      _lastPosition = pos;
      _lastMovementTime = now;
      await _saveLog(pos, "Movement resumed after idle", context);
      return;
    }

    // 🔹 Every 2 min OR 300m log
    if (distance >= 300 ||
        now.difference(_lastMovementTime!).inMinutes >= 2) {
      _lastMovementTime = now;
      _lastPosition = pos;
      await _saveLog(pos, "Periodic log (moved $distance m)", context);
    }

    // 🔹 If idle for 10 min
    if (!_isIdle &&
        distance < 50 &&
        now.difference(_lastMovementTime!).inMinutes >= 10) {
      _isIdle = true;
      await _saveLog(pos, "User idle for 10 min → stop logging", context);
    }
  }

  Future<void> _saveLog(
      geo.Position pos, String note, BuildContext context) async {
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

    // ✅ Snackbar every log
    SnackBarUtils.showSuccess(context, 'Note: $note\nAddress: $address');

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


