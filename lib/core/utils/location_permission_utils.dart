import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'snackbar_utils.dart';

class LocationPermissionUtils {
  static bool _isRequestingPermission = false;

  static Future<bool> ensureLocationPermission(BuildContext context) async {
    if (_isRequestingPermission) return false;
    _isRequestingPermission = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          SnackBarUtils.showError(context, "Location Track and Auto attendance check will not work");
          _isRequestingPermission = false;
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        SnackBarUtils.showError(context, "Location Track and Auto attendance check will not work");
        _isRequestingPermission = false;
        return false;
      }
      _isRequestingPermission = false;
      return true;
    } catch (e) {
      SnackBarUtils.showError(context, "Location Track and Auto attendance check will not work");
      _isRequestingPermission = false;
      return false;
    }
  }
} 