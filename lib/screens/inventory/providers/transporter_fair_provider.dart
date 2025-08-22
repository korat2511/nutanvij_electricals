import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:nutanvij_electricals/providers/user_provider.dart';
import '../../../models/fair_report_response.dart';
import '../../../models/transporter_fair.dart';
import '../../../services/api_service.dart';

class TransporterFairProvider with ChangeNotifier {
  bool _loading = false;
  List<TransporterFair> _transporterFairs = [];
  String? _errorMessage;

  bool get loading => _loading;
  List<TransporterFair> get transporterFairs => _transporterFairs;
  String? get errorMessage => _errorMessage;

  Future<void> fetchTransporterFairs(
      BuildContext context,
      int transporterId,
      UserProvider userProvider,
      ) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final apiToken = userProvider.user?.data.apiToken ?? '';

      final fairs = await ApiService().getTransporterFairList(
        context: context,
        apiToken: apiToken,
        transporterId: transporterId,
      );
      _transporterFairs = fairs;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> storeTransporterFair({
    required BuildContext context,
    required UserProvider userProvider,
    required int transporterId,
    required String fair,
    required String date,
    required String toLocation,
    required String fromLocation,
  }) async {
    try {
      _loading = true;
      notifyListeners();

      final apiToken = userProvider.user?.data.apiToken ?? '';

      await ApiService().storeTransporterFair(
        context: context,
        apiToken: apiToken,
        transporterId: transporterId,
        fair: fair,
        date: date,
        toLocation: toLocation,
        fromLocation: fromLocation,
      );

      // ✅ After success, refresh list
      await fetchTransporterFairs(context, transporterId, userProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fair stored successfully")),
      );
    } catch (e) {
      log("Error storing fair: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }


}
