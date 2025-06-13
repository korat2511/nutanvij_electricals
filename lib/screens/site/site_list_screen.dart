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
import 'create_site_screen.dart';
import '../../core/utils/navigation_utils.dart';
import '../../../widgets/user_card.dart';
import 'assign_users_screen.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/site_validation_utils.dart';

class SiteListScreen extends StatefulWidget {
  const SiteListScreen({Key? key}) : super(key: key);

  @override
  State<SiteListScreen> createState() => _SiteListScreenState();
}

class _SiteListScreenState extends State<SiteListScreen> {
  List<Site> _sites = [];
  bool _isLoading = true;
  String? _error;

  Future<void> _loadSites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _sites = await ApiService().getSiteList(
        context: context,
        apiToken: userProvider.user?.data.apiToken ?? '',
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  @override
  Widget build(BuildContext context) {
    final canCreateSite = SiteValidationUtils.canCreateSite(context);
    return Scaffold(
      appBar: CustomAppBar(
        onMenuPressed: () => NavigationUtils.pop(context),
        title: 'Sites',
      ),
      body: RefreshIndicator(
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
                : _sites.isEmpty
                    ? Center(
              child: Text(
                'No sites found.',
                style: AppTypography.bodyMedium,
              ),
                      )
                    : Builder(
                        builder: (context) {
                          final isTablet = Responsive.responsiveValue(context: context, mobile: 1, tablet: 2).toInt() > 1;
                          if (isTablet) {
                            return GridView.builder(
                              padding: EdgeInsets.all(Responsive.responsiveValue(context: context, mobile: 12, tablet: 32)),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: Responsive.responsiveValue(context: context, mobile: 1, tablet: 2).toInt(),
                                childAspectRatio: 2.0,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _sites.length,
                              itemBuilder: (context, index) {
                                final site = _sites[index];
                                return _SiteCard(
                                  site: site,
                                  onUsersChanged: (newUsers) {
                                    setState(() {
                                      _sites[index] = _sites[index].copyWith(users: newUsers);
                                    });
                                  },
                                );
                              },
                            );
                          } else {
                            return ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _sites.length,
                              itemBuilder: (context, index) {
                                final site = _sites[index];
                                return _SiteCard(
                                  site: site,
                                  onUsersChanged: (newUsers) {
                                    setState(() {
                                      _sites[index] = _sites[index].copyWith(users: newUsers);
                                    });
                                  },
                                );
                              },
                            );
                          }
                        },
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

class _SiteCard extends StatelessWidget {
  final Site site;
  final void Function(List<UserInSite>) onUsersChanged;
  const _SiteCard({required this.site, required this.onUsersChanged});

  @override
  Widget build(BuildContext context) {
              return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.background,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
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
                      if (site.users.isNotEmpty) {
                        final result = await showModalBottomSheet<List<UserInSite>>(
                          backgroundColor: Colors.white,
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (context) {
                            List<UserInSite> localUsers = List<UserInSite>.from(site.users);
                            return StatefulBuilder(
                              builder: (context, setModalState) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                    top: 20,
                                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 4,
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[400],
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Assigned Users', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                          TextButton.icon(
                                            icon: const Icon(Icons.add_circle),
                                            label: const Text('Assign User'),
                                            onPressed: () async {
                                              if (!SiteValidationUtils.validateUserManagement(context)) {
                                                return;
                                              }
                                              final assignResult = await showModalBottomSheet<List<UserInSite>>(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor: Colors.white,
                                                shape: const RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                                ),
                                                builder: (context) => SizedBox(
                                                  height: MediaQuery.of(context).size.height * 0.85,
                                                  child: AssignUsersScreen(
                                                    siteId: site.id,
                                                    assignedUsers: List<UserInSite>.from(localUsers),
                                                  ),
                                                ),
                                              );
                                              if (assignResult is List<UserInSite>) {
                                                setModalState(() {
                                                  localUsers = List<UserInSite>.from(assignResult);
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ...localUsers.map((user) => UserCard(
                                            name: user.name,
                                            imageUrl: user.imagePath,
                                            actionButton: IconButton(
                                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                                              onPressed: () async {
                                                if (!SiteValidationUtils.validateUserManagement(context, userIdToRemove: user.id)) {
                                                  return;
                                                }
                                                try {
                                                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                                                  await ApiService().removeUserFromSite(
                                                    context: context,
                                                    apiToken: userProvider.user?.data.apiToken ?? '',
                                                    siteId: site.id,
                                                    userId: user.id,
                                                  );
                                                  SnackBarUtils.showSuccess(context, 'User removed successfully!');
                                                  setModalState(() {
                                                    localUsers.removeWhere((u) => u.id == user.id);
                                                  });
                                                } on ApiException catch (e) {
                                                  SnackBarUtils.showError(context, e.message);
                                                } catch (e) {
                                                  SnackBarUtils.showError(context, 'Something went wrong.');
                                                }
                                              },
                                            ),
                                          )),
                                      const SizedBox(height: 16),
                                      Center(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(List<UserInSite>.from(localUsers));
                                          },
                                          child: const Text('Done'),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                        if (result != null) {
                          onUsersChanged(result);
                        }
                      }
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
    );
  }
} 