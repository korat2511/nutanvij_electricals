import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/responsive.dart';
import '../../../services/api_service.dart';
import '../../../providers/user_provider.dart';
import '../../../models/site.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_search_field.dart';
import 'assigned_users_screen.dart';
import 'create_site_screen.dart';
import 'edit_site_screen.dart';
import 'manpower_management_screen.dart';
import '../../core/utils/navigation_utils.dart';
import '../../../core/utils/site_validation_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../screens/task/task_list_screen.dart';

class SiteListScreen extends StatefulWidget {
  const SiteListScreen({Key? key}) : super(key: key);

  @override
  State<SiteListScreen> createState() => _SiteListScreenState();
}

class _SiteListScreenState extends State<SiteListScreen> {
  List<Site> _sites = [];
  List<Site> _filteredSites = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Pagination variables
  int _currentPage = 1;
  bool _hasMoreData = true;

  Future<void> _loadSites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      // 1. Fetch all sites
      final sites = await ApiService().getSiteList(
        context: context,
        apiToken: userProvider.user?.data.apiToken ?? '',
        page: 1,
      );
      setState(() {
        _sites = sites; // Show sites immediately
        _filteredSites = sites; // Initialize filtered sites
        _currentPage = 1;
        _hasMoreData = sites.isNotEmpty;
        _isLoading = false;
      });

      // 2. Fetch users for all sites in parallel
      final futures = sites.map((site) async {
        final siteWithUsers = await ApiService().getUserBySite(
          context: context,
          apiToken: userProvider.user?.data.apiToken ?? '',
          siteId: site.id,
        );
        return MapEntry(site.id, siteWithUsers.users);
      }).toList();

      final results = await Future.wait(futures);

      // 3. Update each site with its users as soon as all are fetched
      setState(() {
        for (final entry in results) {
          final idx = _sites.indexWhere((s) => s.id == entry.key);
          if (idx != -1) {
            _sites[idx] = _sites[idx].copyWith(users: entry.value);
          }
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreSites() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final sites = await ApiService().getSiteList(
        context: context,
        apiToken: userProvider.user?.data.apiToken ?? '',
        page: _currentPage + 1,
      );

      // Fetch users for new sites in parallel
      final futures = sites.map((site) async {
        final siteWithUsers = await ApiService().getUserBySite(
          context: context,
          apiToken: userProvider.user?.data.apiToken ?? '',
          siteId: site.id,
        );
        return site.copyWith(users: siteWithUsers.users);
      }).toList();

      final sitesWithUsers = await Future.wait(futures);

      setState(() {
        // Check for duplicates before adding
        int addedCount = 0;
        for (final newSite in sitesWithUsers) {
          if (!_sites.any((existingSite) => existingSite.id == newSite.id)) {
            _sites.add(newSite);
            _filteredSites.add(newSite);
            addedCount++;
          }
        }
        _currentPage++;
        // Only continue pagination if we actually added new sites
        _hasMoreData = addedCount > 0 && sites.isNotEmpty;
        _isLoadingMore = false;
      });
    } catch (e) {
      print('Error loading more sites: $e');
      setState(() {
        _isLoadingMore = false;
      });
      SnackBarUtils.showError(context, e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSites();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreSites();
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSites = _sites;
      } else {
        _filteredSites = _sites.where((site) {
          return site.name.toLowerCase().contains(query) ||
                 site.company.toLowerCase().contains(query) ||
                 site.address.toLowerCase().contains(query) ||
                 site.status.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canCreateSite = SiteValidationUtils.canCreateSite(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        onMenuPressed: () => NavigationUtils.pop(context),
        title: 'Sites',
      ),
      body: GestureDetector(
        onTap: () {
          // Close keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // Search Bar
            Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomSearchField(
              controller: _searchController,
              hintText: 'Search sites by name or status...',
              onChanged: (value) {
                // Search is handled by the listener
              },
              onClear: () {
                setState(() {
                  _filteredSites = _sites;
                });
              },
            ),
          ),
          // Sites List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadSites,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                          ),
                        )
                      : _filteredSites.isEmpty
                          ? Center(
                              child: Text(
                                _sites.isEmpty ? 'No sites found.' : 'No sites match your search.',
                                style: AppTypography.bodyMedium,
                              ),
                            )
                          : Builder(
                        builder: (context) {
                          final isTablet = Responsive.responsiveValue(context: context, mobile: 1, tablet: 2).toInt() > 1;
                          if (isTablet) {
                            return GridView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.all(Responsive.responsiveValue(context: context, mobile: 12, tablet: 32)),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: Responsive.responsiveValue(context: context, mobile: 1, tablet: 2).toInt(),
                                childAspectRatio: 2.0,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _filteredSites.length + (_isLoadingMore ? 1 : 0) + (!_hasMoreData && _filteredSites.isNotEmpty ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Handle loading indicator
                                if (_isLoadingMore && index == _filteredSites.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                
                                // Handle end message
                                if (!_hasMoreData && _filteredSites.isNotEmpty && index == _filteredSites.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'No more sites to load',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                
                                final site = _filteredSites[index];
                                return _SiteCard(
                                  site: site,
                                  onUsersChanged: (newUsers) {
                                    setState(() {
                                      final originalIndex = _sites.indexWhere((s) => s.id == site.id);
                                      if (originalIndex != -1) {
                                        _sites[originalIndex] = _sites[originalIndex].copyWith(users: newUsers);
                                        // Update filtered sites as well
                                        final filteredIndex = _filteredSites.indexWhere((s) => s.id == site.id);
                                        if (filteredIndex != -1) {
                                          _filteredSites[filteredIndex] = _filteredSites[filteredIndex].copyWith(users: newUsers);
                                        }
                                      }
                                    });
                                  },
                                );
                              },
                            );
                          } else {
                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: _filteredSites.length + (_isLoadingMore ? 1 : 0) + (!_hasMoreData && _filteredSites.isNotEmpty ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Handle loading indicator
                                if (_isLoadingMore && index == _filteredSites.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                
                                // Handle end message
                                if (!_hasMoreData && _filteredSites.isNotEmpty && index == _filteredSites.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: Text(
                                        'No more sites to load',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                
                                final site = _filteredSites[index];
                                return _SiteCard(
                                  site: site,
                                  onUsersChanged: (newUsers) {
                                    setState(() {
                                      final originalIndex = _sites.indexWhere((s) => s.id == site.id);
                                      if (originalIndex != -1) {
                                        _sites[originalIndex] = _sites[originalIndex].copyWith(users: newUsers);
                                        // Update filtered sites as well
                                        final filteredIndex = _filteredSites.indexWhere((s) => s.id == site.id);
                                        if (filteredIndex != -1) {
                                          _filteredSites[filteredIndex] = _filteredSites[filteredIndex].copyWith(users: newUsers);
                                        }
                                      }
                                    });
                                  },
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),


        floatingActionButton: canCreateSite
            ? Padding(
                padding: const EdgeInsets.only(bottom: 16.0, right: 8.0),
                child: CustomButton(
                  text: 'Create Site',
                  width: 160,
                  height: 48,
                  onPressed: () async {
                    final shouldRefresh = await NavigationUtils.push(context, CreateSiteScreen());
                    if (shouldRefresh == true) {
                      _loadSites();
                    }
                  },
                ),
              )
            : null,
      );
  }
}

class _SiteCard extends StatefulWidget {
  final Site site;
  final void Function(List<UserInSite>) onUsersChanged;
  const _SiteCard({required this.site, required this.onUsersChanged});

  @override
  State<_SiteCard> createState() => _SiteCardState();
}

class _SiteCardState extends State<_SiteCard> {
  bool _isPinning = false;

  @override
  Widget build(BuildContext context) {
    final site = widget.site;
    return GestureDetector(
      onTap: (){
        NavigationUtils.push(context, TaskListScreen(siteId: site.id));
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.background,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: site.siteImages.isNotEmpty
                            ? Image.network(site.siteImages.first.imageUrl, width: 56, height: 56, fit: BoxFit.cover)
                            : Container(
                                width: 56,
                                height: 56,
                                color: AppColors.primary.withOpacity(0.1),
                                child: const Icon(Icons.location_on, color: AppColors.primary, size: 28),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    site.name,
                                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (site.pinned == 1) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.push_pin, color: AppColors.primary, size: 18),
                                ],
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: site.status.toLowerCase() == 'pending'
                                        ? Colors.orange.shade100
                                        : site.status.toLowerCase() == 'active'
                                            ? Colors.green.shade100
                                            : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    site.status,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: site.status.toLowerCase() == 'pending'
                                          ? Colors.orange
                                          : site.status.toLowerCase() == 'active'
                                              ? Colors.green
                                              : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (site.company.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(site.company, style: AppTypography.bodySmall.copyWith(color: AppColors.primary)),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              site.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(color: Colors.black87),
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: InkWell(
                          onTap: () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AssignedUsersScreen(siteId: site.id),
                              ),
                            );
                          },
                          child: Text(
                            site.users.length == 1 ? '1 User' : '${site.users.length} Users',
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500, color: AppColors.primary, decoration: TextDecoration.underline),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text('Start: ${site.startDate ?? 'NA'}', style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.event, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text('End: ${site.endDate ?? 'NA'}', style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (SiteValidationUtils.canEditSite(context))
              Positioned(
                bottom: 8,
                right: 8,
                child: _isPinning
                    ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2))
                    : PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppColors.primary),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            final shouldRefresh = await NavigationUtils.push(
                              context,
                              EditSiteScreen(site: site),
                            );
                            if (shouldRefresh == true) {
                              final parentState = context.findAncestorStateOfType<_SiteListScreenState>();
                              parentState?._loadSites();
                            }
                          } else if (value == 'manpower') {
                            NavigationUtils.push(
                              context,
                              ManpowerManagementScreen(site: site),
                            );
                          } else if (value == 'details') {
                            // TODO: Implement view details
                          } else if (value == 'pin') {
                            setState(() => _isPinning = true);
                            final userProvider = Provider.of<UserProvider>(context, listen: false);
                            try {
                              await ApiService().pinSite(
                                context: context,
                                apiToken: userProvider.user?.data.apiToken ?? '',
                                siteId: site.id,
                              );
                              final parentState = context.findAncestorStateOfType<_SiteListScreenState>();
                              parentState?._loadSites();
                            } on ApiException catch (e) {
                              SnackBarUtils.showError(context, e.message);
                            } catch (e) {
                              SnackBarUtils.showError(context, 'Failed to pin/unpin site.');
                            } finally {
                              if (mounted) setState(() => _isPinning = false);
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Site'),
                          ),
                          const PopupMenuItem(
                            value: 'manpower',
                            child: Text('Manage Manpower'),
                          ),
                          const PopupMenuItem(
                            value: 'details',
                            child: Text('View Details'),
                          ),
                          PopupMenuItem(
                            value: 'pin',
                            child: Text(site.pinned == 1 ? 'Unpin Site' : 'Pin Site'),
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }
} 