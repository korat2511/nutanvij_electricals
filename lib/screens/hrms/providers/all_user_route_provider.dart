import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/user_access.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../providers/user_provider.dart';
import '../../../services/api_service.dart';

class AllUserRouteProvider with ChangeNotifier {
  bool _isLoadingUsers = false;
  bool _isLoadingLogs = false;

  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _selectedUser;
  List<Map<String, dynamic>> _locationLogs = [];

  bool get isLoadingUsers => _isLoadingUsers;
  bool get isLoadingLogs => _isLoadingLogs;
  List<Map<String, dynamic>> get users => _users;
  Map<String, dynamic>? get selectedUser => _selectedUser;
  List<Map<String, dynamic>> get locationLogs => _locationLogs;

  /// Fetch Users
  Future<void> fetchUsers(BuildContext context, UserProvider userProvider) async {
    _isLoadingUsers = true;
    if (hasListeners) notifyListeners();

    try {
      final user = userProvider.user;
      if (user == null) return;

      final response = await ApiService().getUserList(
        context: context,
        apiToken: user.data.apiToken,
        search: '',
      );

      final designationId = user.data.designationId;
      List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(response);

      if (!UserAccess.hasAdminAccess(designationId)) {
        users = users.where((u) => UserAccess.isBelow(designationId, u['designation_id'])).toList();
      }

      _users = users;
    } catch (e) {
      SnackBarUtils.showError(context, e.toString());
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  /// Select a user and fetch logs
  Future<void> selectUser(BuildContext context, Map<String, dynamic> user) async {
    _selectedUser = user;
    _locationLogs = [];
    notifyListeners();
    await fetchLocationLogs(context, user['id'].toString());
  }

  /// Clear selected user
  void clearSelectedUser() {
    _selectedUser = null;
    _locationLogs = [];
    notifyListeners();
  }

  /// Fetch location logs from Firestore
  Future<void> fetchLocationLogs(BuildContext context, String userId) async {
    _isLoadingLogs = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("location_track_history")
          .orderBy("time", descending: true)
          .get();

      final logs = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "lat": data["lat"],
          "long": data["long"],
          "address": data["address"],
          "time": data["time"],
          "note": data["note"],
        };
      }).toList();

      _locationLogs = logs;
    } catch (e) {
      SnackBarUtils.showError(context, "Error fetching logs: $e");
    } finally {
      _isLoadingLogs = false;
      notifyListeners();
    }
  }

  /// Format log time
  String formatLogTime(String rawTime) {
    try {
      final dateTime = DateTime.parse(rawTime);
      return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
    } catch (e) {
      return rawTime;
    }
  }
}

