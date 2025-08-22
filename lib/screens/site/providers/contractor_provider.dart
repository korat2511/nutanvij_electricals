import 'package:flutter/material.dart';
import '../../../models/contractor.dart';
import '../../../providers/user_provider.dart';
import '../../../services/api_service.dart';

class ContractorProvider with ChangeNotifier {
  List<Contractor> _contractors = [];
  bool _isLoading = false;
  String? _error;

  List<Contractor> get contractors => _contractors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchContractors({
    required BuildContext context,
    required String siteId,
    required UserProvider userProvider,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService().getContractorList(
        context: context,
        apiToken: userProvider.user?.data.apiToken ?? '',
        siteId: siteId,
      );

      _contractors = result;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
}
