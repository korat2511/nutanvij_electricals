import 'package:flutter/material.dart';
import 'package:nutanvij_electricals/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../../core/utils/navigation_utils.dart';
import '../../services/api_service.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/user_provider.dart';
import '../../widgets/user_card.dart';
import '../../models/site.dart';
import '../../core/utils/site_validation_utils.dart';

class AssignUsersScreen extends StatefulWidget {
  final int siteId;
  final List<UserInSite> assignedUsers;
  final void Function(List<UserInSite>)? onUsersChanged;

  const AssignUsersScreen({Key? key, required this.siteId, required this.assignedUsers, this.onUsersChanged}) : super(key: key);

  @override
  State<AssignUsersScreen> createState() => _AssignUsersScreenState();
}

class _AssignUsersScreenState extends State<AssignUsersScreen> {
  late Future<List<Map<String, dynamic>>> _futureUsers;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _loadingUserIds = {};

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _futureUsers = ApiService().getUserList(
      context: context,
      apiToken: userProvider.user?.data.apiToken ?? '',
    );
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final designation = (user['designation']?['name'] ?? '').toString().toLowerCase();
        final department = (user['department']?['name'] ?? '').toString().toLowerCase();
        return name.contains(query) || designation.contains(query) || department.contains(query);
      }).toList();
    });
  }

  bool _isAssigned(int userId) {
    return widget.assignedUsers.any((u) => u.id == userId);
  }

  Future<void> _assignUser(int userId) async {
    setState(() => _loadingUserIds.add(userId));
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await ApiService().assignUserToSite(
        context: context,
        apiToken: userProvider.user?.data.apiToken ?? '',
        siteId: widget.siteId,
        userId: userId,
      );
      SnackBarUtils.showSuccess(context, 'User assigned successfully!');
      final assignedUser = _allUsers.firstWhere((u) => u['id'] == userId, orElse: () => {});
      if (assignedUser.isNotEmpty) {
        setState(() {
          widget.assignedUsers.add(
            UserInSite(
              id: assignedUser['id'],
              name: assignedUser['name'] ?? '',
              imagePath: assignedUser['image_path'],
              // add other fields if needed
            ),
          );
        });
      }
      widget.onUsersChanged?.call(List<UserInSite>.from(widget.assignedUsers));
    } on ApiException catch (e) {
      SnackBarUtils.showError(context, e.message);
    } catch (e) {
      SnackBarUtils.showError(context, 'Something went wrong.');
    } finally {
      setState(() => _loadingUserIds.remove(userId));
    }
  }

  Future<void> _removeUser(int userId) async {
    if (!SiteValidationUtils.validateUserManagement(context, userIdToRemove: userId)) {
      return;
    }

    setState(() => _loadingUserIds.add(userId));
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await ApiService().removeUserFromSite(
        context: context,
        apiToken: userProvider.user?.data.apiToken ?? '',
        siteId: widget.siteId,
        userId: userId,
      );
      SnackBarUtils.showSuccess(context, 'User removed successfully!');
      setState(() {
        widget.assignedUsers.removeWhere((u) => u.id == userId);
      });
      widget.onUsersChanged?.call(List<UserInSite>.from(widget.assignedUsers));
    } on ApiException catch (e) {
      SnackBarUtils.showError(context, e.message);
    } catch (e) {
      SnackBarUtils.showError(context, 'Something went wrong.');
    } finally {
      setState(() => _loadingUserIds.remove(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    final currentDesignationId = currentUser?.data.designationId ?? 99;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        showNotification: false,
        showProfilePicture: false,
        onMenuPressed: () => NavigationUtils.pop(context),
        title: "Assign/Remove Users",
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(List<UserInSite>.from(widget.assignedUsers));
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }

          if (_allUsers.isEmpty && snapshot.hasData) {
            _allUsers = snapshot.data!;
            _filteredUsers = _allUsers;
          }

          final users = _filteredUsers;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, designation, or department',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (users.isEmpty)
                const Expanded(
                  child: Center(child: Text('No users found.')),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final userId = user['id'] as int;
                      final isAssigned = _isAssigned(userId);
                      final userDesignationId = user['designation']?['id'] is int
                          ? user['designation']['id']
                          : int.tryParse(user['designation']?['id']?.toString() ?? '99') ?? 99;
                      final isHigherAuthority = userDesignationId < currentDesignationId;
                      return UserCard(
                        name: user['name'] ?? '',
                        imageUrl: user['image_path'],
                        designation: user['designation']?['name'] ?? '',
                        department: user['department']?['name'] ?? '',
                        actionButton: isHigherAuthority
                            ? const Tooltip(
                                message: "You can't manage higher authority",
                                child: Icon(Icons.block, color: Colors.grey),
                              )
                            : _loadingUserIds.contains(userId)
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : isAssigned
                                    ? IconButton(
                                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                                        onPressed: () => _removeUser(userId),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.add_circle, color: Colors.green),
                                        onPressed: () => _assignUser(userId),
                                      ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
} 