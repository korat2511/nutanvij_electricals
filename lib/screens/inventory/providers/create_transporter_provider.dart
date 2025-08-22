import 'package:flutter/material.dart';

import '../../../core/utils/snackbar_utils.dart';
import '../../../services/api_service.dart';

class CreateTransporterProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> createTransporter({
    required BuildContext context,
    required String apiToken,
    required String name,
    required String email,
    required String phone,
    required String address,
    required String pancard,
    required String fair,
    required String vehicleType,
    required String company,
    List<String>? imagePaths,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService().createTransporter(
        context: context,
        apiToken: apiToken,
        name: name,
        email: email,
        phone: phone,
        address: address,
        pancard: pancard,
        fair: fair,
        vehicleType: vehicleType,
        company: company,
      );

      if (context.mounted) {
        SnackBarUtils.showSuccess(context, "Transporter created successfully!");
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, e.toString());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
