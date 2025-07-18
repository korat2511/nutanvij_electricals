// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import '../../core/theme/app_typography.dart';
// import '../../providers/user_provider.dart';
// import 'package:timeline_tile/timeline_tile.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
//
// class RouteScreen extends StatefulWidget {
//   const RouteScreen({Key? key}) : super(key: key);
//
//   @override
//   State<RouteScreen> createState() => _RouteScreenState();
// }
//
// class _RouteScreenState extends State<RouteScreen> {
//   GoogleMapController? _mapController;
//   Set<Marker> _markers = {};
//   final Set<Polyline> _polylines = {};
//   List<Map<String, dynamic>> _locationHistory = [];
//
//   List<Map<String, dynamic>> get _validLocationHistory =>
//       _locationHistory.where((loc) {
//         try {
//           final lat = loc['latitude'];
//           final lng = loc['longitude'];
//           final latDouble = _parseDouble(lat);
//           final lngDouble = _parseDouble(lng);
//           return latDouble != null && lngDouble != null;
//         } catch (_) {
//           return false;
//         }
//       }).toList();
//   bool _isLoading = true;
//   String _selectedView = 'map'; // 'map' or 'timeline'
//   static const double defaultLat = 23.0225;
//   static const double defaultLng = 72.5714;
//   DateTime? _selectedDate;
//
//   // Add a cache to avoid repeated lookups
//   final Map<String, String> _addressCache = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchLocationHistory();
//   }
//
//   Future<void> _fetchLocationHistory() async {
//     setState(() => _isLoading = true);
//     try {
//       final userProvider = Provider.of<UserProvider>(context, listen: false);
//       final userId = userProvider.user?.data.id.toString();
//       if (userId == null) return;
//
//       final snapshot = await FirebaseFirestore.instance
//           .collection('user_location_history')
//           .doc(userId)
//           .collection('routes')
//           .orderBy('timestamp', descending: true)
//           .get();
//
//       final locations = snapshot.docs.map((doc) {
//         final data = doc.data();
//         return {
//           ...data,
//           'id': doc.id,
//         };
//       }).toList();
//
//       setState(() {
//         _locationHistory = locations;
//         _updateMapMarkers();
//       });
//     } catch (e) {
//       print('Error fetching location history: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   void _updateMapMarkers() {
//     final validLocations = _validLocationHistory;
//     if (validLocations.isEmpty) {
//       setState(() {
//         _markers = {};
//         _polylines.clear();
//       });
//       return;
//     }
//     final markers = <Marker>{};
//     final points = <LatLng>[];
//     final dateFormat = DateFormat('dd MMM yyyy');
//     _polylines.clear();
//     final locationsByDate = <String, List<Map<String, dynamic>>>{};
//     for (var location in validLocations) {
//       final timestamp = location['timestamp'];
//       if (timestamp == null) continue;
//       final date = DateTime.fromMillisecondsSinceEpoch(timestamp is int
//           ? timestamp
//           : int.tryParse(timestamp.toString()) ?? 0);
//       final dateKey = dateFormat.format(date);
//       if (!locationsByDate.containsKey(dateKey)) {
//         locationsByDate[dateKey] = [];
//       }
//       locationsByDate[dateKey]!.add(location);
//     }
//     locationsByDate.forEach((date, locations) {
//       final color = _getColorForDate(date);
//       for (var i = 0; i < locations.length; i++) {
//         final location = locations[i];
//         try {
//           final lat = _parseDouble(location['latitude']) ?? defaultLat;
//           final lng = _parseDouble(location['longitude']) ?? defaultLng;
//           final position = LatLng(lat, lng);
//           points.add(position);
//           markers.add(
//             Marker(
//               markerId: MarkerId('${location['id']}'),
//               position: position,
//               infoWindow: InfoWindow(
//                 title: '${location['event_type']}',
//                 snippet: DateFormat('hh:mm a').format(
//                   DateTime.fromMillisecondsSinceEpoch(location['timestamp']
//                           is int
//                       ? location['timestamp']
//                       : int.tryParse(location['timestamp'].toString()) ?? 0),
//                 ),
//               ),
//             ),
//           );
//         } catch (_) {
//           continue;
//         }
//       }
//       if (points.length > 1) {
//         _polylines.add(
//           Polyline(
//             polylineId: PolylineId(date),
//             points: List<LatLng>.from(points),
//             color: color,
//             width: 3,
//           ),
//         );
//       }
//     });
//     setState(() {
//       _markers = markers;
//     });
//     if (points.isNotEmpty && _mapController != null) {
//       _mapController!.animateCamera(
//         CameraUpdate.newLatLngBounds(
//           _getBoundsForPoints(points),
//           50.0,
//         ),
//       );
//     }
//   }
//
//   Color _getColorForDate(String date) {
//     // Generate a consistent color for each date
//     final hash = date.hashCode;
//     return Color.fromRGBO(
//       (hash & 0xFF0000) >> 16,
//       (hash & 0x00FF00) >> 8,
//       hash & 0x0000FF,
//       0.8,
//     );
//   }
//
//   LatLngBounds _getBoundsForPoints(List<LatLng> points) {
//     double? minLat, maxLat, minLng, maxLng;
//
//     for (var point in points) {
//       if (minLat == null || point.latitude < minLat) minLat = point.latitude;
//       if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
//       if (minLng == null || point.longitude < minLng) minLng = point.longitude;
//       if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
//     }
//
//     return LatLngBounds(
//       southwest: LatLng(minLat!, minLng!),
//       northeast: LatLng(maxLat!, maxLng!),
//     );
//   }
//
//   List<Map<String, dynamic>> _getFilteredLocations() {
//     final validLocations = _validLocationHistory;
//     if (_selectedDate == null) return validLocations;
//     final dateFormat = DateFormat('dd MMM yyyy');
//     final selectedKey = dateFormat.format(_selectedDate!);
//     return validLocations.where((loc) {
//       final timestamp = loc['timestamp'];
//       if (timestamp == null) return false;
//       final date = DateTime.fromMillisecondsSinceEpoch(timestamp is int
//           ? timestamp
//           : int.tryParse(timestamp.toString()) ?? 0);
//       return dateFormat.format(date) == selectedKey;
//     }).toList();
//   }
//
//   Set<Marker> _getMarkersForLocations(List<Map<String, dynamic>> locations) {
//     final markers = <Marker>{};
//     for (var location in locations) {
//       try {
//         final lat = _parseDouble(location['latitude']) ?? defaultLat;
//         final lng = _parseDouble(location['longitude']) ?? defaultLng;
//         final eventType =
//             (location['event_type'] ?? '').toString().toLowerCase();
//         final markerColor = _getMarkerColorForEvent(eventType);
//         final markerIcon = BitmapDescriptor.defaultMarkerWithHue(markerColor);
//         markers.add(
//           Marker(
//             markerId: MarkerId('${location['id']}'),
//             position: LatLng(lat, lng),
//             icon: markerIcon,
//             infoWindow: InfoWindow(
//               title: eventType,
//               snippet: DateFormat('hh:mm a').format(
//                 DateTime.fromMillisecondsSinceEpoch(location['timestamp'] is int
//                     ? location['timestamp']
//                     : int.tryParse(location['timestamp'].toString()) ?? 0),
//               ),
//             ),
//           ),
//         );
//       } catch (_) {
//         continue;
//       }
//     }
//     return markers;
//   }
//
//   double _getMarkerColorForEvent(String eventType) {
//     switch (eventType) {
//       case 'start':
//         return BitmapDescriptor.hueGreen;
//       case 'stop':
//         return BitmapDescriptor.hueRed;
//       case 'moving':
//         return BitmapDescriptor.hueAzure;
//       case 'stationary':
//         return BitmapDescriptor.hueOrange;
//       default:
//         return BitmapDescriptor.hueViolet;
//     }
//   }
//
//   Set<Polyline> _getPolylinesForLocations(
//       List<Map<String, dynamic>> locations) {
//     final points = <LatLng>[];
//     for (var location in locations) {
//       try {
//         final lat = _parseDouble(location['latitude']) ?? defaultLat;
//         final lng = _parseDouble(location['longitude']) ?? defaultLng;
//         points.add(LatLng(lat, lng));
//       } catch (_) {
//         continue;
//       }
//     }
//     if (points.length > 1) {
//       return {
//         Polyline(
//           polylineId: const PolylineId('route'),
//           points: points,
//           color: Colors.blue,
//           width: 3,
//         ),
//       };
//     }
//     return {};
//   }
//
//   Widget _buildDatePicker(List<Map<String, dynamic>> validLocations) {
//     final dateFormat = DateFormat('dd MMM yyyy');
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Row(
//         children: [
//           TextButton(
//             onPressed: () async {
//               final picked = await showDatePicker(
//                 context: context,
//                 initialDate: _selectedDate ?? DateTime.now(),
//                 firstDate: DateTime(2020),
//                 lastDate: DateTime.now(),
//               );
//               if (picked != null) {
//                 setState(() {
//                   _selectedDate = picked;
//                 });
//               }
//             },
//             child: Text(
//               _selectedDate == null
//                   ? 'Select Date'
//                   : dateFormat.format(_selectedDate!),
//               style: const TextStyle(fontSize: 16),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLegend() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           _legendItem('Start', Colors.green),
//           const SizedBox(width: 12),
//           _legendItem('Stop', Colors.red),
//           const SizedBox(width: 12),
//           _legendItem('Moving', Colors.blue),
//           const SizedBox(width: 12),
//           _legendItem('Stationary', Colors.orange[700]!),
//         ],
//       ),
//     );
//   }
//
//   Widget _legendItem(String label, Color color) {
//     return Row(
//       children: [
//         Icon(Icons.location_on, color: color, size: 20),
//         const SizedBox(width: 4),
//         Text(label, style: const TextStyle(fontSize: 12)),
//       ],
//     );
//   }
//
//   Map<String, double> _calculateDistanceByMode(List<Map<String, dynamic>> locations) {
//     double walk = 0.0, bike = 0.0, car = 0.0;
//     for (int i = 1; i < locations.length; i++) {
//       final prev = locations[i - 1];
//       final curr = locations[i];
//       final lat1 = _parseDouble(prev['latitude']) ?? defaultLat;
//       final lng1 = _parseDouble(prev['longitude']) ?? defaultLng;
//       final lat2 = _parseDouble(curr['latitude']) ?? defaultLat;
//       final lng2 = _parseDouble(curr['longitude']) ?? defaultLng;
//       final t1 = prev['timestamp'];
//       final t2 = curr['timestamp'];
//       if (t1 == null || t2 == null) continue;
//       final dt1 = DateTime.fromMillisecondsSinceEpoch(t1 is int ? t1 : int.tryParse(t1.toString()) ?? 0);
//       final dt2 = DateTime.fromMillisecondsSinceEpoch(t2 is int ? t2 : int.tryParse(t2.toString()) ?? 0);
//       final seconds = (dt2.difference(dt1).inSeconds).abs();
//       if (seconds == 0) continue;
//       final distance = Geolocator.distanceBetween(lat1, lng1, lat2, lng2); // meters
//       final speedKmh = (distance / seconds) * 3.6; // m/s to km/h
//       if (speedKmh < 6) {
//         walk += distance;
//       } else if (speedKmh < 25) {
//         bike += distance;
//       } else {
//         car += distance;
//       }
//     }
//     return {
//       'walk': walk / 1000.0,
//       'bike': bike / 1000.0,
//       'car': car / 1000.0,
//     };
//   }
//
//   Widget _buildStatsSummary(List<Map<String, dynamic>> filteredLocations) {
//     // Distance
//     double totalDistance = 0.0;
//     for (int i = 1; i < filteredLocations.length; i++) {
//       final prev = filteredLocations[i - 1];
//       final curr = filteredLocations[i];
//       final lat1 = _parseDouble(prev['latitude']) ?? defaultLat;
//       final lng1 = _parseDouble(prev['longitude']) ?? defaultLng;
//       final lat2 = _parseDouble(curr['latitude']) ?? defaultLat;
//       final lng2 = _parseDouble(curr['longitude']) ?? defaultLng;
//       totalDistance += Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
//     }
//     final km = (totalDistance / 1000.0);
//
//     // Number of stops
//     final numStops = filteredLocations.where((loc) {
//       final type = (loc['event_type'] ?? '').toString().toLowerCase();
//       return type == 'stop';
//     }).length;
//
//     // Total time
//     String totalTimeStr = '--';
//     double totalHours = 0.0;
//     if (filteredLocations.length > 1) {
//       final first = filteredLocations.last; // because list is descending
//       final last = filteredLocations.first;
//       final t1 = first['timestamp'];
//       final t2 = last['timestamp'];
//       if (t1 != null && t2 != null) {
//         final dt1 = DateTime.fromMillisecondsSinceEpoch(t1 is int ? t1 : int.tryParse(t1.toString()) ?? 0);
//         final dt2 = DateTime.fromMillisecondsSinceEpoch(t2 is int ? t2 : int.tryParse(t2.toString()) ?? 0);
//         final diff = dt2.difference(dt1);
//         totalHours = diff.inSeconds / 3600.0;
//         final hours = diff.inHours;
//         final minutes = diff.inMinutes % 60;
//         totalTimeStr = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
//       }
//     }
//
//     // Average speed
//     String avgSpeedStr = '--';
//     if (totalHours > 0) {
//       final avgSpeed = km / totalHours;
//       avgSpeedStr = avgSpeed.toStringAsFixed(2);
//     }
//
//     // Distance by mode
//     final modeDistances = _calculateDistanceByMode(filteredLocations);
//     final walkKm = modeDistances['walk']!.toStringAsFixed(2);
//     final bikeKm = modeDistances['bike']!.toStringAsFixed(2);
//     final carKm = modeDistances['car']!.toStringAsFixed(2);
//
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _statItem('Walk', '$walkKm km'),
//               _statItem('Bike', '$bikeKm km'),
//               _statItem('Car', '$carKm km'),
//             ],
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _statItem('Distance', '${km.toStringAsFixed(2)} km'),
//               _statItem('Stops', '$numStops'),
//               _statItem('Time', totalTimeStr),
//               _statItem('Avg Speed', avgSpeedStr == '--' ? '--' : '$avgSpeedStr km/h'),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _statItem(String label, String value) {
//     return Column(
//       children: [
//         Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//         const SizedBox(height: 2),
//         Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
//       ],
//     );
//   }
//
//   Widget _buildMapView() {
//     final filteredLocations = _getFilteredLocations();
//     if (filteredLocations.isEmpty) {
//       return const Center(
//         child: Text('No valid location history available'),
//       );
//     }
//     final first = filteredLocations.first;
//     final lat = _parseDouble(first['latitude']) ?? defaultLat;
//     final lng = _parseDouble(first['longitude']) ?? defaultLng;
//     final initialPosition = LatLng(lat, lng);
//     return Column(
//       children: [
//         _buildLegend(),
//         Expanded(
//           child: GoogleMap(
//             initialCameraPosition: CameraPosition(
//               target: initialPosition,
//               zoom: 15,
//             ),
//             onMapCreated: (controller) {
//               _mapController = controller;
//             },
//             markers: _getMarkersForLocations(filteredLocations),
//             polylines: _getPolylinesForLocations(filteredLocations),
//             myLocationEnabled: true,
//             myLocationButtonEnabled: true,
//             zoomControlsEnabled: true,
//             mapToolbarEnabled: true,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTimelineView() {
//     final filteredLocations = _getFilteredLocations();
//     if (filteredLocations.isEmpty) {
//       return const Center(
//         child: Text('No valid location history available'),
//       );
//     }
//     final dateFormat = DateFormat('dd MMM yyyy');
//     final locationsByDate = <String, List<Map<String, dynamic>>>{};
//     for (var location in filteredLocations) {
//       final timestamp = location['timestamp'];
//       if (timestamp == null) continue;
//       final date = DateTime.fromMillisecondsSinceEpoch(timestamp is int
//           ? timestamp
//           : int.tryParse(timestamp.toString()) ?? 0);
//       final dateKey = dateFormat.format(date);
//       if (!locationsByDate.containsKey(dateKey)) {
//         locationsByDate[dateKey] = [];
//       }
//       locationsByDate[dateKey]!.add(location);
//     }
//     return ListView.builder(
//       itemCount: locationsByDate.length,
//       itemBuilder: (context, index) {
//         final date = locationsByDate.keys.elementAt(index);
//         final locations = locationsByDate[date]!;
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Text(
//                 date,
//                 style: AppTypography.titleMedium.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             ListView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: locations.length,
//               itemBuilder: (context, locationIndex) {
//                 final location = locations[locationIndex];
//                 try {
//                   final timestamp = location['timestamp'];
//                   final time = DateFormat('hh:mm a').format(
//                     DateTime.fromMillisecondsSinceEpoch(timestamp is int
//                         ? timestamp
//                         : int.tryParse(timestamp.toString()) ?? 0),
//                   );
//                   final lat = _parseDouble(location['latitude']) ?? defaultLat;
//                   final lng = _parseDouble(location['longitude']) ?? defaultLng;
//                   final eventType =
//                       (location['event_type'] ?? '').toString().toLowerCase();
//                   final color = _getMarkerColorForEvent(eventType);
//                   return TimelineTile(
//                     alignment: TimelineAlign.manual,
//                     lineXY: 0.2,
//                     isFirst: locationIndex == 0,
//                     isLast: locationIndex == locations.length - 1,
//                     indicatorStyle: IndicatorStyle(
//                       width: 20,
//                       color: HSVColor.fromAHSV(1, color, 1, 1).toColor(),
//                       iconStyle: IconStyle(
//                         color: Colors.white,
//                         iconData: _getIconForEventType(location['event_type']),
//                       ),
//                     ),
//                     beforeLineStyle: LineStyle(
//                       color: HSVColor.fromAHSV(1, color, 1, 1).toColor(),
//                     ),
//                     endChild: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             time,
//                             style: AppTypography.bodyMedium.copyWith(
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '${location['event_type']}',
//                             style: AppTypography.bodySmall,
//                           ),
//                           const SizedBox(height: 4),
//                           FutureBuilder<String>(
//                             future: _getAddress(lat, lng),
//                             builder: (context, snapshot) {
//                               if (snapshot.connectionState ==
//                                   ConnectionState.waiting) {
//                                 return const Text('Loading address...');
//                               }
//                               return Text(
//                                 snapshot.data ?? 'Address not found',
//                                 style: AppTypography.bodySmall,
//                               );
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 } catch (_) {
//                   return const SizedBox.shrink();
//                 }
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   IconData _getIconForEventType(String eventType) {
//     switch (eventType.toLowerCase()) {
//       case 'start':
//         return Icons.play_arrow;
//       case 'stop':
//         return Icons.stop;
//       case 'moving':
//         return Icons.directions_walk;
//       case 'stationary':
//         return Icons.access_time;
//       default:
//         return Icons.location_on;
//     }
//   }
//
//   static double? _parseDouble(dynamic value) {
//     if (value == null) return null;
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is String) return double.tryParse(value);
//     return null;
//   }
//
//   Future<String> _getAddress(double lat, double lng) async {
//     final key = '$lat,$lng';
//     if (_addressCache.containsKey(key)) return _addressCache[key]!;
//     try {
//       final placemarks = await placemarkFromCoordinates(lat, lng);
//       if (placemarks.isNotEmpty) {
//         final place = placemarks.first;
//         final address =
//             '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
//         _addressCache[key] = address;
//         return address;
//       }
//       return 'Address not found';
//     } catch (e) {
//       return 'Address not found';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final validLocations = _validLocationHistory;
//     final filteredLocations = _getFilteredLocations();
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Route History'),
//         actions: [
//           IconButton(
//             icon: Icon(
//               _selectedView == 'map' ? Icons.timeline : Icons.map,
//             ),
//             onPressed: () {
//               setState(() {
//                 _selectedView = _selectedView == 'map' ? 'timeline' : 'map';
//               });
//             },
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//
//                 _buildStatsSummary(filteredLocations),
//                 _buildDatePicker(validLocations),
//                 Expanded(
//                   child: _selectedView == 'map'
//                       ? _buildMapView()
//                       : _buildTimelineView(),
//                 ),
//               ],
//             ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _mapController?.dispose();
//     super.dispose();
//   }
// }
