import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../models/contractor.dart';
import '../../../providers/user_provider.dart';
import '../../../services/api_service.dart';

class ContractorProvider with ChangeNotifier {
  List<Contractor> _contractors = [];

  List<Contractor> _contractorsFiltered = [];

  bool _isLoading = false;
  String? _error;

  List<Contractor> get contractors => _contractors;
  List<Contractor> get contractorsFiltered => _contractorsFiltered;
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
      _contractorsFiltered = result;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 👇 New Method
  Future<void> addContractor({
    required BuildContext context,
    required String apiToken,
    required String siteId,
    required String name,
    required String mobile,
    required String email,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService().saveContractor(
        context: context,
        apiToken: apiToken,
        siteId: siteId,
        name: name,
        mobile: mobile,
        email: email,
      );

      // After successful save, refresh the contractor list
      await fetchContractors(
        context: context,
        siteId: siteId,
        userProvider: Provider.of<UserProvider>(context, listen: false),
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
