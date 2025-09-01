import 'package:flutter/material.dart';
import 'package:nutanvij_electricals/screens/hrms/providers/all_user_route_provider.dart';
import 'package:provider/provider.dart';

import '../../core/constants/user_access.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/responsive.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../route/route_screen.dart';

class AllUserRouteScreen extends StatefulWidget {
  const AllUserRouteScreen({Key? key}) : super(key: key);

  @override
  State<AllUserRouteScreen> createState() => _AllUserRouteScreenState();
}

class _AllUserRouteScreenState extends State<AllUserRouteScreen> {
  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final allUserProvider = Provider.of<AllUserRouteProvider>(context, listen: false);
    allUserProvider.fetchUsers(context, userProvider);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final allUserProvider = Provider.of<AllUserRouteProvider>(context);

    final designationId = userProvider.user?.data.designationId;
    final isAdmin = UserAccess.hasAdminAccess(designationId) ||
        UserAccess.hasSeniorEngineerAccess(designationId) ||
        UserAccess.hasPartnerAccess(designationId);

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          onMenuPressed: () => NavigationUtils.pop(context),
          title: 'All User Routes',
        ),
        body: const Center(
            child: Text('You do not have permission to view this page.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'All Users Routes',
        onMenuPressed: () => NavigationUtils.pop(context),
        showProfilePicture: false,
        showNotification: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.responsiveValue(context: context, mobile: 12, tablet: 32),
          vertical: Responsive.responsiveValue(context: context, mobile: 8, tablet: 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            allUserProvider.isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : GestureDetector(
              onTap: () async {
                final result = await showSearch<Map<String, dynamic>?>(
                  context: context,
                  delegate: _UserSearchDelegate(allUserProvider.users),
                );
                if (result != null) {
                  allUserProvider.selectUser(context, result);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        allUserProvider.selectedUser == null
                            ? 'Select User'
                            : allUserProvider.selectedUser?['name'] ?? 'User',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    if (allUserProvider.selectedUser != null)
                      GestureDetector(
                        onTap: () => allUserProvider.clearSelectedUser(),
                        child: const Icon(Icons.close, color: Colors.red, size: 18),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (allUserProvider.selectedUser != null)
              Expanded(
                child: allUserProvider.isLoadingLogs
                    ? const Center(child: CircularProgressIndicator())
                    : allUserProvider.locationLogs.isEmpty
                    ? const Center(child: Text("No location logs found"))
                    : ListView.builder(
                  itemCount: allUserProvider.locationLogs.length,
                  itemBuilder: (context, index) {
                    final log = allUserProvider.locationLogs[index];
                    return GestureDetector(
                      onTap: (){
                        //go to map screen
                        NavigationUtils.push(
                            context,
                            const RouteScreen());
                      },
                      child: Card(
                        color: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Lat: ${log['lat']}, Lng: ${log['long']}",
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Address: ${log['address']}",
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Note: ${log['note']}",
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      allUserProvider.formatLogTime(log['time']),
                                      style: AppTypography.bodySmall.copyWith(
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
          ],
        ),
      ),
    );
  }
}

class _UserSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  final List<Map<String, dynamic>> users;

  _UserSearchDelegate(this.users);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Container(
        color: Colors.white,
        child: ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, i) {
            final user = users[i];
            return ListTile(
              title: Text(user['name']),

              subtitle: Text(user['email'] ?? ''),
              onTap: () => close(context, user),
            );
          },
        ),
      );
    }

    final filteredUsers = users.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final searchQuery = query.toLowerCase();
      return name.contains(searchQuery) || email.contains(searchQuery);
    }).toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No users found matching "$query"',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: ListView.builder(
        itemCount: filteredUsers.length,
        itemBuilder: (context, i) {
          final user = filteredUsers[i];
          return ListTile(
            title: Text(user['name']),
            onTap: () => close(context, user),
          );
        },
      ),
    );
  }
}

