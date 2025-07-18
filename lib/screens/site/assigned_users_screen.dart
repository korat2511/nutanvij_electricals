import 'package:flutter/material.dart';
import 'package:nutanvij_electricals/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../../models/site.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/user_card.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/snackbar_utils.dart';
import 'assign_users_screen.dart';
import '../../models/designation.dart';

class AssignedUsersScreen extends StatefulWidget {
  final int siteId;
  const AssignedUsersScreen({Key? key, required this.siteId}) : super(key: key);

  @override
  State<AssignedUsersScreen> createState() => _AssignedUsersScreenState();
}

class _AssignedUsersScreenState extends State<AssignedUsersScreen> {
  List<UserInSite> users = [];
  bool isLoading = true;
  String? error;
  String searchText = '';
  int? _selectedDesignationId;
  int? _selectedHasKeypadMobile;
  List<Designation> _designations = [];

  @override
  void initState() {
    super.initState();
    _fetchDesignations();
    _fetchUsers();
  }

  Future<void> _fetchDesignations() async {
    try {
      final designations = await ApiService().getDesignations();
      setState(() {
        _designations = designations;
      });
    } catch (e) {
      // ignore error for now
    }
  }

  Future<void> _fetchUsers() async {
    setState(() { isLoading = true; error = null; });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final site = await ApiService().getUserBySite(
        context: context,
        apiToken: userProvider.user?.data.apiToken ?? '',
        siteId: widget.siteId,
        designationId: _selectedDesignationId,
        hasKeypadMobile: _selectedHasKeypadMobile,
      );
      setState(() {
        users = site.users;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _handlePunch(UserInSite user) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final apiToken = userProvider.user?.data.apiToken ?? '';
    final isCheckedIn = user.lastStatus == 'check_in';
    final type = isCheckedIn ? 'check_out' : 'check_in';
    try {
      var response = await ApiService().attendanceForOtherUser(
        context: context,
        apiToken: apiToken,
        type: type,
        userIds: [user.id],
        latitude: '', // Provide actual latitude if available
        longitude: '', // Provide actual longitude if available
        address: '', // Provide actual address if available
        checkInDescription: null,
        siteId: widget.siteId,
      );
      // TODO: Parse response for updated status if available
      setState(() {
        final idx = users.indexWhere((u) => u.id == user.id);
        if (idx != -1) {
          users[idx] = users[idx].copyWith(lastStatus: isCheckedIn ? 'check_out' : 'check_in');
        }
      });
      SnackBarUtils.showSuccess(context, 'Attendance ${type == 'check_in' ? 'punched in' : 'punched out'} successfully!');
    } on ApiException catch (e) {
      SnackBarUtils.showError(context, e.message);
    } catch (e) {
      SnackBarUtils.showError(context, 'Something went wrong.');
    }
  }

  Future<void> _handleRemoveUser(UserInSite user) async {
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if(user.id == userProvider.user!.data.id){
      SnackBarUtils.showError(context, "You can't remove yourself");
      return;
    }

    try {
      await ApiService().removeUserFromSite(
        context: context,
        apiToken: userProvider.user?.data.apiToken ?? '',
        siteId: widget.siteId,
        userId: user.id,
      );
      setState(() {
        users.removeWhere((u) => u.id == user.id);
      });
      SnackBarUtils.showSuccess(context, 'User removed successfully!');
    } on ApiException catch (e) {
      SnackBarUtils.showError(context, e.message);
    } catch (e) {
      SnackBarUtils.showError(context, 'Something went wrong.');
    }
  }

  List<UserInSite> get filteredUsers => users.where((user) => user.name.toLowerCase().contains(searchText.toLowerCase())).toList();

  Widget _buildFilterDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filters', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              // Designation Section
              Text('Designation', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _selectedDesignationId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _designations.map((d) => DropdownMenuItem(
                  value: d.id,
                  child: Text(d.name, style: AppTypography.bodyMedium),
                )).toList(),
                onChanged: (val) {
                  setState(() => _selectedDesignationId = val);
                  _fetchUsers();
                },
              ),
              const SizedBox(height: 30),

              // Keypad Mobile Section
              Text('Keypad Mobile', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Radio<int>(
                    value: 1,
                    groupValue: _selectedHasKeypadMobile,
                    onChanged: (val) {
                      setState(() => _selectedHasKeypadMobile = val);
                      _fetchUsers();
                    },
                    activeColor: AppColors.primary,
                  ),
                  Text('Yes', style: AppTypography.bodyMedium),
                  Radio<int>(
                    value: 0,
                    groupValue: _selectedHasKeypadMobile,
                    onChanged: (val) {
                      setState(() => _selectedHasKeypadMobile = val);
                      _fetchUsers();
                    },
                    activeColor: AppColors.primary,
                  ),
                  Text('No', style: AppTypography.bodyMedium),
                ],
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: IconButton(
                  icon: Icon(Icons.clear, color: AppColors.primary),
                  tooltip: 'Clear Filters',
                  onPressed: () {
                    setState(() {
                      _selectedDesignationId = null;
                      _selectedHasKeypadMobile = null;
                    });
                    _fetchUsers();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Assigned Users',
        onMenuPressed: () => Navigator.of(context).pop(),
        showProfilePicture: false,
        showNotification: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.filter_alt_outlined),
              tooltip: 'Filters',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () async {
              final assignResult = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssignUsersScreen(
                    siteId: widget.siteId,
                    assignedUsers: List<UserInSite>.from(users),
                  ),
                ),
              );
              if (assignResult is List<UserInSite>) {
                setState(() {
                  users = List<UserInSite>.from(assignResult);
                });
              }
            },
          ),
        ],
      ),
      endDrawer: _buildFilterDrawer(context),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: AppTypography.bodyMedium.copyWith(color: AppColors.error)))
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: AppTypography.bodyMedium,
                        onChanged: (value) {
                          setState(() {
                            searchText = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, idx) {
                            final user = filteredUsers[idx];
                            Widget? punchStatusIcon;
                            if (user.hasKeypadMobile == 1) {
                              final isCheckedIn = user.lastStatus == 'check_in';
                              punchStatusIcon = GestureDetector(
                                onTap: () => _handlePunch(user),
                                child: Icon(
                                  isCheckedIn ? Icons.logout : Icons.login,
                                  color: isCheckedIn ? Colors.red : Colors.green,
                                  size: 20,
                                ),
                              );
                            }
                            return UserCard(
                              name: user.name,
                              imageUrl: user.imagePath,
                              punchStatusIcon: punchStatusIcon,
                              actionButton: IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => _handleRemoveUser(user),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
} 