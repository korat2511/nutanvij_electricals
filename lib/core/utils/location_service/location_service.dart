import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class LocationService {
  static Future<void> initializeService(String userId) async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'App is running',
        initialNotificationContent: 'Tracking location in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
    service.invoke("setUserId", {"userId": userId});

  }

  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  geo.Geolocator.requestPermission();

  geo.Position? lastPosition;
  DateTime? lastMovementTime;
  bool isStopped = false;
  String? userId;

  // Listen for dynamic userId
  service.on("setUserId").listen((event) {
    userId = event?["userId"];
    log("✅ UserId set in background: $userId");
  });

  geo.Geolocator.getPositionStream(
    locationSettings: const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 0,
    ),
  ).listen((pos) async {
    if (userId == null) {
      log("⚠️ Skipping log because userId is null");
      return;
    }

    final now = DateTime.now();

    if (lastPosition == null) {
      lastPosition = pos;
      lastMovementTime = now;
      isStopped = false;
      await _saveLog(pos, "start", userId!);
      return;
    }

    final distance = geo.Geolocator.distanceBetween(
      lastPosition!.latitude,
      lastPosition!.longitude,
      pos.latitude,
      pos.longitude,
    );

    if (distance >= 300) {
      lastPosition = pos;
      lastMovementTime = now;

      if (isStopped) {
        isStopped = false;
        await _saveLog(pos, "start", userId!);
      } else {
        await _saveLog(pos, "moving", userId!);
      }
    }

    if (!isStopped && now.difference(lastMovementTime!).inMinutes >= 10) {
      isStopped = true;
      await _saveLog(pos, "stop", userId!);
    }
  });
}

Future<void> _saveLog(geo.Position pos, String note, String userId) async {
  String address = "Unknown";
  try {
    final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      address = "${p.street}, ${p.locality}, ${p.country}";
    }
  } catch (e) {
    log("Error fetching address: $e");
  }

/*  Fluttertoast.showToast(
    msg: "[$note] Lat: ${pos.latitude}, Lng: ${pos.longitude}\n$address",
    toastLength: Toast.LENGTH_SHORT,
  );*/

  await FirebaseFirestore.instance
      .collection("user_location_history")
      .doc(userId) // ✅ dynamic now
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
