import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/constants/user_access.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_app_bar.dart';

class LeaveRequestListScreen extends StatefulWidget {
  final bool isAllUsers;
  const LeaveRequestListScreen({Key? key, this.isAllUsers = false}) : super(key: key);

  @override
  State<LeaveRequestListScreen> createState() => _LeaveRequestListScreenState();
}

class _LeaveRequestListScreenState extends State<LeaveRequestListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _selectedUser;
  String _selectedStatus = 'all';
  String _sortBy = 'time_desc';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
    if (widget.isAllUsers) _fetchUsers();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user == null) return;
      final leaves = await ApiService().getLeaveList(
        context: context,
        apiToken: user.data.apiToken,
        userId: widget.isAllUsers ? null : user.data.id.toString(),
      );
      setState(() {
        _requests = leaves;
      });
    } catch (e) {
      SnackBarUtils.showError(context, "$e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user == null) return;
      final users = await ApiService().getUserList(
        context: context,
        apiToken: user.data.apiToken,
        search: '',
      );
      setState(() {
        _users = users;
      });
    } catch (e) {
      SnackBarUtils.showError(context, "$e");
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    List<Map<String, dynamic>> filtered = _requests.where((req) {
      final status = (req['status'] ?? '').toString().toLowerCase();
      final userId = req['user']?['id']?.toString() ?? '';
      final matchesStatus = _selectedStatus == 'all' || status == _selectedStatus;
      final matchesUser = !widget.isAllUsers || _selectedUser == null || userId == (_selectedUser?['id']?.toString() ?? '');
      return matchesStatus && matchesUser;
    }).toList();
    // Sort
    if (_sortBy == 'time_desc') {
      filtered.sort((a, b) {
        final aTime = a['created_at'] ?? '';
        final bTime = b['created_at'] ?? '';
        return bTime.compareTo(aTime);
      });
    } else if (_sortBy == 'time_asc') {
      filtered.sort((a, b) {
        final aTime = a['created_at'] ?? '';
        final bTime = b['created_at'] ?? '';
        return aTime.compareTo(bTime);
      });
    } else if (_sortBy == 'status') {
      filtered.sort((a, b) => (a['status'] ?? '').toString().compareTo((b['status'] ?? '').toString()));
    }
    return filtered;
  }

  void _openFilterDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _resetFilters() {
    setState(() {
      _selectedStatus = 'all';
      _selectedUser = null;
      _sortBy = 'time_desc';
      _fromDate = null;
      _toDate = null;
    });
  }

  Future<void> _handleLeaveAction(String leaveId, String status) async {
    String? reason = await _showReasonDialog(context, status);
    if (reason == null) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await ApiService().leaveRequestAction(
        context: context,
        apiToken: user.data.apiToken,
        leaveId: leaveId,
        status: status,
        reason: reason,
      );
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, 'Leave $status successfully');
      await _fetchRequests();
    } catch (e) {
      Navigator.of(context).pop();
      SnackBarUtils.showError(context, e.toString());
    }
  }

  Future<String?> _showReasonDialog(BuildContext context, String action) async {
    final TextEditingController controller = TextEditingController();
    String? errorText;
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('$action Leave'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please enter a note (reason) for this action:'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      errorText: errorText,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) {
                      setState(() => errorText = 'Reason is required');
                    } else {
                      Navigator.of(ctx).pop(controller.text.trim());
                    }
                  },
                  child: Text(action),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: widget.isAllUsers ? 'Leave Requests' : 'My Leave Requests',
        onMenuPressed: () => Navigator.of(context).pop(),
        showProfilePicture: false,
        showNotification: false,
      ),
      endDrawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Filter & Sort', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    ...['all', 'pending', 'approved', 'rejected'].map((status) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: RadioListTile<String>(
                            value: status,
                            groupValue: _selectedStatus,
                            onChanged: (val) => setState(() => _selectedStatus = val!),
                            title: Text(status == 'all' ? 'All' : status[0].toUpperCase() + status.substring(1)),
                            activeColor: AppColors.primary,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )),
                  ],
                ),
              ),
              const Divider(height: 32),
              if (widget.isAllUsers) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User', style: AppTypography.bodyMedium),
                      GestureDetector(
                        onTap: () async {
                          final result = await showSearch<Map<String, dynamic>?>(
                            context: context,
                            delegate: _UserSearchDelegate(_users),
                          );
                          if (result != null) setState(() => _selectedUser = result);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          margin: const EdgeInsets.only(top: 8, bottom: 8),
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
                                  _selectedUser == null ? 'Filter by user...' : _selectedUser?['name'] ?? 'User',
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                                ),
                              ),
                              if (_selectedUser != null)
                                GestureDetector(
                                  onTap: () => setState(() => _selectedUser = null),
                                  child: const Icon(Icons.close, color: Colors.red, size: 18),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 32),
              ],
              Text('Sort By', style: AppTypography.bodyMedium),
              DropdownButton<String>(
                value: _sortBy,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'time_desc', child: Text('Time - New First')),
                  DropdownMenuItem(value: 'time_asc', child: Text('Time - Old First')),
                  DropdownMenuItem(value: 'status', child: Text('Status')),
                ],
                onChanged: (val) => setState(() => _sortBy = val ?? 'time_desc'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).maybePop();
                        _fetchRequests();
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _resetFilters();
                        Navigator.of(context).maybePop();
                        setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.filter_alt_outlined, color: AppColors.primary),
                    onPressed: _openFilterDrawer,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.responsiveValue(context: context, mobile: 16, tablet: 32),
                  ),
                  child: Text(
                    widget.isAllUsers ? 'All Users Leave Requests' : 'My Leave Requests',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _filteredRequests.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(Responsive.responsiveValue(context: context, mobile: 16, tablet: 32)),
                            child: Text('No leave requests found.', style: AppTypography.bodyMedium),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(
                              horizontal: Responsive.responsiveValue(context: context, mobile: 16, tablet: 32)),
                          itemCount: _filteredRequests.length,
                          separatorBuilder: (_, __) => SizedBox(height: Responsive.responsiveValue(context: context, mobile: 12, tablet: 24)),
                          itemBuilder: (context, i) {
                            final req = _filteredRequests[i];
                            final status = (req['status'] ?? '').toString();
                            final userInfo = req['user'] ?? {};
                            final reason = (req['reason'] ?? '').toString();
                            final adminReason = (req['admin_reason'] ?? '').toString();
                            final requestedDate = req['created_at'] != null
                                ? DateTime.parse(req['created_at']).toLocal()
                                : null;
                            final requestedDateLabel = requestedDate != null
                                ? DateFormat('dd MMM yyyy, hh:mm a').format(requestedDate)
                                : '';
                            final startDate = req['start_date'] != null && req['start_date'] != ''
                                ? DateTime.parse(req['start_date']).toLocal()
                                : null;
                            final endDate = req['end_date'] != null && req['end_date'] != ''
                                ? DateTime.parse(req['end_date']).toLocal()
                                : null;
                            final startDateLabel = startDate != null ? DateFormat('dd MMM yyyy').format(startDate) : (req['start_date'] ?? '-');
                            final endDateLabel = endDate != null ? DateFormat('dd MMM yyyy').format(endDate) : (req['end_date'] ?? '-');
                            Color statusColor = Colors.grey;
                            if (status.toLowerCase() == 'pending') {
                              statusColor = Colors.orange;
                            }
                            if (status.toLowerCase() == 'approved') {
                              statusColor = Colors.green;
                            }
                            if (status.toLowerCase() == 'rejected') {
                              statusColor = Colors.red;
                            }
                            final approvedBy = req['approved_by'] is Map ? req['approved_by']['name'] : req['approved_by'];
                            final showApprovedBy = status.toLowerCase() == 'approved' && approvedBy != null && approvedBy.isNotEmpty;
                            final showRejectedBy = status.toLowerCase() == 'rejected' && approvedBy != null && approvedBy.isNotEmpty;

                            final designationId = user?.data.designationId;
                            final loggedInUserId = user?.data.id.toString() ?? '';
                            final requestorId = userInfo['id']?.toString() ?? '';
                            final requestorDesignationId = userInfo['designation_id'];
                            bool canShowAction = false;
                            bool showCancel = false;

                            if (widget.isAllUsers) {
                              if (status.toLowerCase() == 'pending' && UserAccess.hasAdminAccess(designationId)) {
                                if (requestorId != loggedInUserId) {
                                  if (UserAccess.hasSeniorEngineerAccess(requestorDesignationId)) {
                                    canShowAction = designationId == UserAccess.admin;
                                  } else if (!UserAccess.hasAdminAccess(requestorDesignationId)) {
                                    canShowAction = true;
                                  }
                                }
                              }
                            } else {
                              canShowAction = status.toLowerCase() == 'pending' && UserAccess.hasAdminAccess(designationId);
                              showCancel = status.toLowerCase() == 'pending';
                            }

                            final showActions = canShowAction && widget.isAllUsers;

                            final approvedAt = req['approved_at'];
                            final approvedDateLabel = (approvedAt != null && (status.toLowerCase() == 'approved' || status.toLowerCase() == 'rejected'))
                                ? DateTime.parse(approvedAt).toLocal()
                                : null;
                            final approvedOnLabel = approvedDateLabel != null
                                ? DateFormat('dd MMM yyyy, hh:mm a').format(approvedDateLabel)
                                : '';
                            final isApproved = status.toLowerCase() == 'approved';
                            final isRejected = status.toLowerCase() == 'rejected';
                            final isCancelled = status.toLowerCase() == 'cancelled';
                            if (isCancelled) {
                              statusColor = Colors.grey;
                            }

                            return Container(
                              margin: EdgeInsets.only(bottom: Responsive.responsiveValue(context: context, mobile: 12, tablet: 24)),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(color: Colors.grey.withOpacity(0.15)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(widget.isAllUsers ? (userInfo['name'] ?? '-') : (req['leave_type'] ?? '-'), style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status[0].toUpperCase() + status.substring(1).toLowerCase(),
                                          style: AppTypography.bodySmall.copyWith(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (widget.isAllUsers)
                                    _infoRow('Leave Type', req['leave_type'] ?? '-'),
                                  _infoRow('Duration', req['duration'] ?? '-'),
                                  _infoRow('Start Date', startDateLabel),
                                  _infoRow('End Date', endDateLabel),
                                  _infoRow('Reason', reason),
                                  if (req['early_off_start_time'] != null)
                                    _infoRow('Early Off Start', req['early_off_start_time'] ?? '-'),
                                  if (req['early_off_end_time'] != null)
                                    _infoRow('Early Off End', req['early_off_end_time'] ?? '-'),
                                  _infoRow('Requested On', requestedDateLabel),
                                  if (isApproved && (approvedBy != null && approvedBy.isNotEmpty))
                                    _infoRow('Approved By', approvedBy, valueColor: Colors.green),
                                  if (isRejected && (approvedBy != null && approvedBy.isNotEmpty))
                                    _infoRow('Rejected By', approvedBy, valueColor: Colors.red),
                                  if (isApproved && approvedOnLabel.isNotEmpty)
                                    _infoRow('Approved On', approvedOnLabel, valueColor: Colors.green),
                                  if (isRejected && approvedOnLabel.isNotEmpty)
                                    _infoRow('Rejected On', approvedOnLabel, valueColor: Colors.red),
                                  if (isApproved && adminReason.isNotEmpty)
                                    _infoRow('Approved Note', adminReason, valueColor: Colors.green),
                                  if (isRejected && adminReason.isNotEmpty)
                                    _infoRow('Rejected Reason', adminReason, valueColor: Colors.red),
                                  if (isCancelled)
                                    _infoRow('Status', 'Cancelled', valueColor: Colors.grey),
                                  if (showActions) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red, size: 32),
                                          onPressed: () async {
                                            if (reason.isNotEmpty) {
                                              await _handleLeaveAction(req['id'].toString(), 'Rejected');
                                            }
                                          },
                                          tooltip: 'Reject',
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                                          onPressed: () async {
                                            if (reason.isNotEmpty) {
                                              await _handleLeaveAction(req['id'].toString(), 'Approved');
                                            }
                                          },
                                          tooltip: 'Approve',
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (showCancel) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red, size: 32),
                                          onPressed: (){},
                                          tooltip: 'Cancel',
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text('$label :', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500, color: valueColor))),
        ],
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
    final results = users.where((u) => (u['name'] ?? '').toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final user = results[index];
        return ListTile(
          title: Text(user['name'] ?? ''),
          onTap: () => close(context, user),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = users.where((u) => (u['name'] ?? '').toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final user = suggestions[index];
        return ListTile(
          title: Text(user['name'] ?? ''),
          onTap: () => close(context, user),
        );
      },
    );
  }
} 