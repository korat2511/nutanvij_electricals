import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:intl/intl.dart';

class LocationProvider with ChangeNotifier {
  geo.Position? _lastPosition;
  DateTime? _lastLogTime;
  StreamSubscription<geo.Position>? _positionStream;

  bool _isTracking = false;
  String? _userId;

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
    _lastLogTime = DateTime.now();

    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 10, // 🔹 small so we can detect 300m properly
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
    final now = DateTime.now();

    if (_lastPosition == null) {
      _lastPosition = pos;
      _lastLogTime = now;
      await _saveLog(pos, "start", context);
      return;
    }

    final distance = geo.Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      pos.latitude,
      pos.longitude,
    );

    // 🔹 log if moved 300m
    if (distance >= 300) {
      _lastPosition = pos;
      _lastLogTime = now;
      // await _saveLog(pos, "Moved ${distance.toStringAsFixed(1)} m", context);
      await _saveLog(pos, "moving", context);
      return;
    }

    // 🔹 log if 2 min passed
    if (now.difference(_lastLogTime!).inMinutes >= 2) {
      _lastPosition = pos;
      _lastLogTime = now;
      // await _saveLog(pos, "Periodic log (2 min)", context);
      await _saveLog(pos, "stationary", context);
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
      }
    } catch (e) {
      log("Error fetching address: $e");
    }

    // ✅ Toast every log
    Fluttertoast.showToast(
      msg: "Log: $note\nLat: ${pos.latitude}, Lng: ${pos.longitude}\n$address",
      toastLength: Toast.LENGTH_SHORT,
    );

    // ✅ Firestore logging
    await FirebaseFirestore.instance
        .collection("user_location_history")
        .doc("1")
        .collection("routes")
        .add({
      "added": formatDateTime(DateTime.now()),
      "device_time": DateTime.now().toIso8601String(),
      "latitude": pos.latitude,
      "longitude": pos.longitude,
      "status": "active",
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "address": address,
      "note": note,
    });
  }

  String formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('MMMM d, y');
    final timeFormat = DateFormat('h:mm:ss a');

    String formattedDate = dateFormat.format(dateTime);
    String formattedTime = timeFormat.format(dateTime);

    String timeZone = dateTime.timeZoneOffset.isNegative ? '-' : '+';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(dateTime.timeZoneOffset.inHours.abs());
    final minutes = twoDigits(dateTime.timeZoneOffset.inMinutes.remainder(60));

    return '$formattedDate at $formattedTime UTC$timeZone$hours:$minutes';
  }
}
