import 'package:flutter/material.dart';
import '../../../models/transporter.dart';
import '../../../providers/user_provider.dart';
import '../../../services/api_service.dart';

class InventoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Transporter> _transporters = [];
  List<Transporter> get transporters => _transporters;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _error;
  String? get error => _error;

  int _currentPage = 1;
  bool _hasMoreData = true;

  bool get hasMoreData => _hasMoreData;

  /// Load first page
  Future<void> loadTransporters(BuildContext context, UserProvider userProvider) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = userProvider.user?.data.apiToken ?? '';
      final sites = await _apiService.getTransporterList(
        context: context,
        apiToken: token,
        page: 1,
      );
      _transporters = sites;
      _currentPage = 1;
      _hasMoreData = sites.isNotEmpty;
      _isLoading = false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  /// Load next page
  Future<void> loadMoreTransporters(BuildContext context, UserProvider userProvider) async {
    if (_isLoadingMore || !_hasMoreData) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final token = userProvider.user?.data.apiToken ?? '';
      final transporters = await _apiService.getTransporterList(
        context: context,
        apiToken: token,
        page: _currentPage + 1,
      );

      //TODO
      // Fetch users for each site
/*
      final futures = transporters.map((site) async {
        final siteWithUsers = await _apiService.getUserBySite(
          context: context,
          apiToken: token,
          siteId: site.id,
        );
        return site.copyWith(users: siteWithUsers.users);
      }).toList();
*/

      // final sitesWithUsers = await Future.wait(futures);

      int addedCount = 0;

      //TODO
/*      for (final newSite in sitesWithUsers) {
        if (!_sites.any((s) => s.id == newSite.id)) {
          _sites.add(newSite);
          addedCount++;
        }
      }*/

      _currentPage++;
      _hasMoreData = addedCount > 0 && transporters.isNotEmpty;
      _isLoadingMore = false;
    } catch (e) {
      _error = e.toString();
      _isLoadingMore = false;
    }
    notifyListeners();
  }
}
