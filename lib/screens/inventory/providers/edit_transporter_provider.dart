import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/navigation_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../providers/user_provider.dart';
import '../../../services/api_service.dart';


class EditTransporterProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> updateTransporter({
    required BuildContext context,
    required int transporterId,
    required String name,
    required String email,
    required String phone,
    required String address,
    required String pancard,
    required String fair,
    required String vehicleType,
    required String company,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final apiToken = userProvider.user?.data.apiToken ?? '';

    _setLoading(true);

    try {
      await ApiService().updateTransporter(
        context: context,
        apiToken: apiToken,
        transporterId: transporterId,
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
        SnackBarUtils.showSuccess(context, 'Transporter updated successfully!');
        NavigationUtils.pop(context, true);
      }
    } on ApiException catch (e) {
      SnackBarUtils.showError(context, e.message);
    } catch (e) {
      SnackBarUtils.showError(context, 'Something went wrong.');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
