import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:fluttertoast/fluttertoast.dart';

class LocationService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: true,
        notificationChannelId: 'location_tracking',
        initialNotificationTitle: 'Location Service Running',
        initialNotificationContent: 'Tracking in background...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }

  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  geo.Geolocator.requestPermission();

  geo.Geolocator.getPositionStream(
    locationSettings: const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 50,
    ),
  ).listen((pos) async {
    String address = "Unknown";
    try {
      final placemarks =
      await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        address = "${p.street}, ${p.locality}, ${p.country}";
      }
    } catch (e) {
      log("Address error: $e");
    }

    // ✅ Toast works in background
    Fluttertoast.showToast(
      msg: "BG Log: ${pos.latitude}, ${pos.longitude}\n$address",
      toastLength: Toast.LENGTH_SHORT,
    );

    // ✅ Firestore logging
    await FirebaseFirestore.instance
        .collection("users")
        .doc("test_user") // replace with actual userId
        .collection("location_track_history")
        .add({
      "lat": pos.latitude,
      "long": pos.longitude,
      "address": address,
      "time": DateTime.now().toIso8601String(),
      "note": "Background log",
    });
  });
}

