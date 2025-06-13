// import 'dart:async';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class Location {
//   final double lat;
//   final double lng;
//
//   Location({
//     required this.lat,
//     required this.lng,
//   });
//
// }
//
// class User {
//   final String name;
//   final Location location;
//   User({
//     required this.name,
//     required this.location,
//   });
//
//   static User fromMap(Map<String, dynamic> map) {
//     return User(
//       name: map['name'] as String,
//       location: Location(
//         lat: map['location']['lat'] as double,
//         lng: map['location']['lng'] as double,
//       ),
//     );
//   }
// }
//
// class FirestoreService {
//   static final _firestore = FirebaseFirestore.instance;
//
//   static Future<void> updateUserLocation(String userId, LatLng location) async {
//     try {
//       await _firestore.collection('users').doc(userId).update({
//         'location': {'lat': location.latitude, 'lng': location.longitude},
//       });
//     } on FirebaseException catch (e) {
//       print('Ann error due to firebase occured $e');
//     } catch (err) {
//       print('Ann error occured $err');
//     }
//   }
//
//   static Stream<List<User>> userCollectionStream() {
//     return _firestore.collection('users').snapshots().map((snapshot) =>
//         snapshot.docs.map((doc) => User.fromMap(doc.data())).toList());
//   }
// }
//
// class StreamLocationService {
//
//   static const LocationSettings _locationSettings =
//   LocationSettings(distanceFilter: 1);
//   static bool _isLocationGranted = false;
//
//   static  Stream<Position>? get onLocationChanged  {
//     if (_isLocationGranted) {
//       return Geolocator.getPositionStream(locationSettings: _locationSettings);
//     }
//     return null;
//   }
//
//   static Future<bool> askLocationPermission() async {
//     _isLocationGranted = await Permission.location.request().isGranted;
//     return _isLocationGranted;
//   }
//
// }
//
//
// class MapScreen extends StatefulWidget {
//   const MapScreen({super.key});
//
//   @override
//   State<MapScreen> createState() => MapScreenState();
// }
//
// class MapScreenState extends State<MapScreen> {
//   final Completer<GoogleMapController> _controller =
//   Completer<GoogleMapController>();
//
//   static const CameraPosition _initialPosition = CameraPosition(
//     target: LatLng(-18.9216855, 47.5725194),// Antananarivo, Madagascar LatLng 🇲🇬
//     zoom: 14.4746,
//   );
//
//   late StreamSubscription<Position>? locationStreamSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     locationStreamSubscription =
//         StreamLocationService.onLocationChanged?.listen(
//               (position) async {
//             await FirestoreService.updateUserLocation(
//              "9",
//               LatLng(position.latitude, position.longitude),
//             );
//           },
//         );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StreamBuilder<List<User>>(
//         stream: FirestoreService.userCollectionStream(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }
//           final Set<Marker> markers = {};
//           for (var i = 0; i < snapshot.data!.length; i++) {
//             final user = snapshot.data![i];
//             markers.add(
//               Marker(
//                 markerId: MarkerId('${user.name} position $i'),
//                 icon: user.name == 'stephano'
//                     ? BitmapDescriptor.defaultMarkerWithHue(
//                   BitmapDescriptor.hueRed,
//                 )
//                     : BitmapDescriptor.defaultMarkerWithHue(
//                   BitmapDescriptor.hueYellow,
//                 ),
//                 position: LatLng(user.location.lat, user.location.lng),
//                 onTap: () => {},
//               ),
//             );
//           }
//           return GoogleMap(
//             initialCameraPosition: _initialPosition,
//             markers: markers,
//             onMapCreated: (GoogleMapController controller) {
//               _controller.complete(controller);
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     locationStreamSubscription?.cancel();
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> uploadSampleRoute(String userId) async {
  final routePoints = [
    // Kamrej GSRTC Bus Station
    {
      'latitude': 21.2677421,
      'longitude': 72.9548785,
      'timestamp': DateTime.now().millisecondsSinceEpoch - 3600 * 1000,
      'event_type': 'start',
    },
    // Midpoint 1
    {
      'latitude': 21.255,
      'longitude': 72.940,
      'timestamp': DateTime.now().millisecondsSinceEpoch - 2700 * 1000,
      'event_type': 'moving',
    },
    // Midpoint 2
    {
      'latitude': 21.245,
      'longitude': 72.920,
      'timestamp': DateTime.now().millisecondsSinceEpoch - 1800 * 1000,
      'event_type': 'moving',
    },
    // Midpoint 3
    {
      'latitude': 21.240,
      'longitude': 72.900,
      'timestamp': DateTime.now().millisecondsSinceEpoch - 900 * 1000,
      'event_type': 'moving',
    },
    // Shayona Plaza
    {
      'latitude': 21.2343359,
      'longitude': 72.881859,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'event_type': 'stop',
    },
  ];

  final batch = FirebaseFirestore.instance.batch();
  final routesRef = FirebaseFirestore.instance
      .collection('user_location_history')
      .doc(userId)
      .collection('routes');

  for (final point in routePoints) {
    batch.set(routesRef.doc(), {
      ...point,
      'device_time': DateTime.now().toIso8601String(),
    });
          }

  await batch.commit();
  print('Sample route uploaded for user: $userId');
}