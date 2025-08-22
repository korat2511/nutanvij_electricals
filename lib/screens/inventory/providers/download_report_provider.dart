import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:nutanvij_electricals/providers/user_provider.dart';
import '../../../models/fair_report_response.dart';
import '../../../models/transporter_fair.dart';
import '../../../services/api_service.dart';

class DownloadReportProvider with ChangeNotifier {
  bool _loading = false;
  List<TransporterFair> _transporterFairs = [];
  String? _errorMessage;

  bool get loading => _loading;
  List<TransporterFair> get transporterFairs => _transporterFairs;
  String? get errorMessage => _errorMessage;

  Future<FairReportResponse> getFairReport({
    required BuildContext context,
    required int transporterId,
    required String startDate,
    required String endDate,
    required UserProvider userProvider,
  }) async {
    _loading = true;
    try {

      final apiToken = userProvider.user?.data.apiToken ?? '';

      final response = await ApiService().getFairReport(
        context: context,
        apiToken: apiToken,
        transporterId : transporterId.toString(),
        startDate: startDate,
        endDate: endDate,
      );
      return response;
    } finally {
      _loading = false;
    }
  }

}
