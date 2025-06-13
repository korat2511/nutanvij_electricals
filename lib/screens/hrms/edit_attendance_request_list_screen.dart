import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutanvij_electricals/core/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/navigation_utils.dart';
import '../../services/api_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/constants/user_access.dart';

class EditAttendanceRequestListScreen extends StatefulWidget {
  final bool isAllUsers;

  const EditAttendanceRequestListScreen({Key? key, this.isAllUsers = false})
      : super(key: key);

  @override
  State<EditAttendanceRequestListScreen> createState() =>
      _EditAttendanceRequestListScreenState();
}

class _EditAttendanceRequestListScreenState
    extends State<EditAttendanceRequestListScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _selectedUser;
  String _selectedStatus = 'all';
  String? _approvedBy;
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
      final now = DateTime.now();
      final startDate = _fromDate != null
          ? DateFormat('yyyy-MM-dd').format(_fromDate!)
          : DateFormat('yyyy-MM-01').format(now);
      final endDate = _toDate != null
          ? DateFormat('yyyy-MM-dd').format(_toDate!)
          : DateFormat('yyyy-MM-dd')
              .format(DateTime(now.year, now.month + 1, 0));
      // Fetch time change requests
      final timeChangeRequests =
          await ApiService().getEditAttendanceRequestList(
        context: context,
        apiToken: user.data.apiToken,
        startDate: startDate,
        endDate: endDate,
        status: '',
        userId: widget.isAllUsers ? '' : user.data.id.toString(),
      );
      // Fetch attendance change requests
      final attendanceChangeRequests =
          await ApiService().getAttendanceRequestList(
        context: context,
        apiToken: user.data.apiToken,
        startDate: startDate,
        endDate: endDate,
        userId: widget.isAllUsers ? '' : user.data.id.toString(),
      );
      // Mark type for each
      final labeledTimeChange = timeChangeRequests
          .map((r) => {...r, '_requestType': 'Time Change Request'})
          .toList();
      final labeledAttendanceChange = attendanceChangeRequests
          .map((r) => {...r, '_requestType': 'Multi Attendance Request'})
          .toList();
      // Combine: time change first, then attendance change
      setState(() {
        _requests = [...labeledTimeChange, ...labeledAttendanceChange];
      });
    } catch (e) {
      SnackBarUtils.showError(context, "$e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user == null) return;
      final users = await ApiService().getUserList(
        context: context,
        apiToken: user.data.apiToken,
        search: '',
      );
      final designationId = user.data.designationId;
      List<Map<String, dynamic>> filteredUsers =
          List<Map<String, dynamic>>.from(users);
      if (!UserAccess.hasAdminAccess(designationId)) {
        filteredUsers = filteredUsers
            .where(
                (u) => UserAccess.isBelow(designationId, u['designation_id']))
            .toList();
      }
      setState(() {
        _users = filteredUsers;
      });
    } catch (e) {
      SnackBarUtils.showError(context, "$e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    final designationId = user?.data.designationId;
    List<Map<String, dynamic>> filtered = _requests.where((req) {
      final status = (req['status'] ?? '').toString().toLowerCase();
      final userId = widget.isAllUsers
          ? (req['attendance']?['user']?['id']?.toString() ??
              req['user']?['id']?.toString() ??
              '')
          : '';
      final approvedByValue = req['approved_by'];
      final approvedByName =
          (approvedByValue is Map && approvedByValue['name'] != null)
              ? approvedByValue['name'].toString().toLowerCase()
              : approvedByValue?.toString().toLowerCase() ?? '';
      final matchesStatus = _selectedStatus == 'all' ||
          _selectedStatus.isEmpty ||
          status == _selectedStatus;
      final matchesUser = !widget.isAllUsers ||
          _selectedUser == null ||
          userId == (_selectedUser?['id']?.toString() ?? '');
      final matchesApprovedBy = !widget.isAllUsers ||
          _approvedBy == null ||
          _approvedBy!.isEmpty ||
          approvedByName.contains(_approvedBy!.toLowerCase());
      // Only show requests from users with a lower designation for non-admins
      if (widget.isAllUsers && !UserAccess.hasAdminAccess(designationId)) {
        final requestorDesignationId = req['attendance']?['user']
                ?['designation_id'] ??
            req['user']?['designation_id'];
        if (!UserAccess.isBelow(designationId, requestorDesignationId)) {
          return false;
        }
      }
      return matchesStatus && matchesUser && matchesApprovedBy;
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
      filtered.sort((a, b) => (a['status'] ?? '')
          .toString()
          .compareTo((b['status'] ?? '').toString()));
    } else if (_sortBy == 'approved_by') {
      filtered.sort((a, b) => (a['approved_by']?['name'] ?? '')
          .toString()
          .compareTo((b['approved_by']?['name'] ?? '').toString()));
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
      _approvedBy = null;
      _sortBy = 'time_desc';
      _fromDate = null;
      _toDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final designationId = user?.data.designationId;
    final isAllUsers = widget.isAllUsers;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Edit Attendance Requests',
        onMenuPressed: () => NavigationUtils.pop(context),
        showProfilePicture: false,
        showNotification: false,
      ),
      endDrawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Filter & Sort',
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Status section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status',
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.bold)),
                    ...['all', 'pending', 'approved', 'rejected']
                        .map((status) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: RadioListTile<String>(
                                value: status,
                                groupValue: _selectedStatus,
                                onChanged: (val) =>
                                    setState(() => _selectedStatus = val!),
                                title: Text(status == 'all'
                                    ? 'All'
                                    : status[0].toUpperCase() +
                                        status.substring(1)),
                                activeColor: AppColors.primary,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            )),
                  ],
                ),
              ),
              const Divider(height: 32),
              // Date Range section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date Range',
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isTablet = constraints.maxWidth > 400;
                        return isTablet
                            ? Row(
                                children: [
                                  Expanded(
                                    child: _DatePickerCard(
                                      label: 'From',
                                      date: _fromDate,
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _fromDate ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          setState(() => _fromDate = picked);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _DatePickerCard(
                                      label: 'To',
                                      date: _toDate,
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _toDate ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          setState(() => _toDate = picked);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _DatePickerCard(
                                    label: 'From',
                                    date: _fromDate,
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            _fromDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        setState(() => _fromDate = picked);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  _DatePickerCard(
                                    label: 'To',
                                    date: _toDate,
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _toDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        setState(() => _toDate = picked);
                                      }
                                    },
                                  ),
                                ],
                              );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),
              if (isAllUsers) ...[
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedUser == null
                                ? 'Filter by user...'
                                : _selectedUser?['name'] ?? 'User',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                        if (_selectedUser != null)
                          GestureDetector(
                            onTap: () => setState(() => _selectedUser = null),
                            child: const Icon(Icons.close,
                                color: Colors.red, size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Approved By', style: AppTypography.bodyMedium),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Enter approver name',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textPrimary),
                          onChanged: (val) => setState(() => _approvedBy = val),
                          controller:
                              TextEditingController(text: _approvedBy ?? ''),
                        ),
                      ),
                      if ((_approvedBy ?? '').isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _approvedBy = ''),
                          child: const Icon(Icons.close,
                              color: Colors.red, size: 18),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text('Sort By', style: AppTypography.bodyMedium),
              DropdownButton<String>(
                value: _sortBy,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'time_desc', child: Text('Time - New First')),
                  DropdownMenuItem(
                      value: 'time_asc', child: Text('Time - Old First')),
                ],
                onChanged: (val) =>
                    setState(() => _sortBy = val ?? 'time_desc'),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTypography.titleMedium
                            .copyWith(fontWeight: FontWeight.bold),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTypography.titleMedium
                            .copyWith(fontWeight: FontWeight.bold),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.responsiveValue(
                            context: context, mobile: 16, tablet: 32),
                      ),
                      child: Text(
                        isAllUsers ? 'All User\'s Requests' : 'My Requests',
                        style: AppTypography.titleMedium
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.filter_alt_outlined,
                            color: AppColors.primary),
                        onPressed: _openFilterDrawer,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: _filteredRequests.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(Responsive.responsiveValue(
                                context: context, mobile: 16, tablet: 32)),
                            child: Text('No edit attendance requests found.',
                                style: AppTypography.bodyMedium),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchRequests,
                          child: ListView.separated(
                          padding: EdgeInsets.symmetric(
                              horizontal: Responsive.responsiveValue(
                                  context: context, mobile: 16, tablet: 32)),
                          itemCount: _filteredRequests.length,
                          separatorBuilder: (_, __) => SizedBox(
                              height: Responsive.responsiveValue(
                                  context: context, mobile: 12, tablet: 24)),
                          itemBuilder: (context, i) {
                            final req = _filteredRequests[i];
                            final status = (req['status'] ?? '').toString();
                            final type = (req['type'] ?? '').toString();
                            final requestedTime =
                                (req['time'] ?? '').toString();
                            final reason = (req['reason'] ??
                                    req['check_in_description'] ??
                                    '')
                                .toString();
                            final requestedDate = req['created_at'] != null
                                ? DateFormat('yyyy-MM-ddTHH:mm:ss')
                                    .parse(req['created_at'], true)
                                    .toLocal()
                                : null;
                            final attendanceDate = req['attendance'] != null &&
                                    req['attendance']['date'] != null
                                ? DateFormat('yyyy-MM-dd')
                                    .parse(req['attendance']['date'], true)
                                    .toLocal()
                                : null;

                            final approvedDate = req['approved_at'] != null &&
                                    (status.toLowerCase() == 'approved' ||
                                        status.toLowerCase() == 'rejected')
                                ? _parseApprovedDate(req['approved_at'])
                                : null;

                            final adminReason = (req['admin_reason'] ??
                                    req['admin_reason'] ??
                                    '')
                                .toString();

                            final requestedDateLabel = requestedDate != null
                                ? DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(requestedDate)
                                : '';
                            final attendanceDateLabel = attendanceDate != null
                                ? DateFormat('dd MMM yyyy')
                                    .format(attendanceDate)
                                : (req['date'] != null
                                    ? DateFormat('dd MMM yyyy').format(
                                        DateFormat('yyyy-MM-dd')
                                            .parse(req['date'], true)
                                            .toLocal())
                                    : '-');
                            final approvedDateLabel = approvedDate != null
                                ? DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(approvedDate)
                                : '';
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

                            final actualTime =
                                (req['actual_time'] ?? '').toString();

                            // Extract user name and designation for all users screen
                            String userName = '';
                            int requestorDesignationId = 0;
                            String requestorId = '';
                            if (isAllUsers) {
                              userName = req['attendance']?['user']?['name'] ??
                                  req['user']?['name'] ??
                                  req['user_name'] ??
                                  'User';
                              requestorDesignationId = req['attendance']
                                      ?['user']?['designation_id'] is int
                                  ? req['attendance']['user']['designation_id']
                                  : int.tryParse(req['attendance']?['user']
                                                  ?['designation_id']
                                              ?.toString() ??
                                          req['user']?['designation_id']
                                              ?.toString() ??
                                          '0') ??
                                      0;
                              requestorId = req['attendance']?['user']?['id']
                                      ?.toString() ??
                                  req['user']?['id']?.toString() ??
                                  '';
                            }
                            final loggedInUserId =
                                user?.data.id.toString() ?? '';
                            bool canShowAction = false;
                            if (isAllUsers) {
                              if (status.toLowerCase() == 'pending' &&
                                  UserAccess.hasAdminAccess(designationId)) {
                                if (requestorId != loggedInUserId) {
                                  if (UserAccess.hasSeniorEngineerAccess(
                                      requestorDesignationId)) {
                                    canShowAction =
                                        designationId == UserAccess.admin;
                                  } else if (!UserAccess.hasAdminAccess(
                                      requestorDesignationId)) {
                                    canShowAction = true;
                                  }
                                }
                              }
                            } else {
                              canShowAction =
                                  status.toLowerCase() == 'pending' &&
                                      UserAccess.hasAdminAccess(designationId);
                            }

                            final requestType =
                                (req['_requestType'] ?? '') as String;
                            // Show approve/reject for both request types
                            final showActionButtons = canShowAction &&
                                (requestType == 'Time Change Request' ||
                                    requestType ==
                                        'Multi Attendance Request') &&
                                isAllUsers;

                            final inTime =
                                req['attendance']?['in_time']?.toString() ??
                                    req['in_time']?.toString() ??
                                    '-';
                            final outTime =
                                req['attendance']?['out_time']?.toString() ??
                                    req['out_time']?.toString() ??
                                    '-';

                            // Show cancel button for own pending requests
                            final isOwnRequest =
                                !isAllUsers || (requestorId == loggedInUserId);
                            final isPending = status.toLowerCase() == 'pending';

                            return AttendanceRequestCard(
                              name: userName,
                              designation: UserAccess.getRoleName(
                                  requestorDesignationId),
                              status: status,
                              statusColor: statusColor,
                              attendanceDate: attendanceDateLabel,
                              actualTime: requestType == 'Time Change Request'
                                  ? (actualTime.isNotEmpty ? actualTime : '-')
                                  : null,
                              requestedTime:
                                  requestType == 'Time Change Request'
                                      ? (requestedTime.isNotEmpty
                                          ? requestedTime
                                          : '-')
                                      : null,
                              inTime: requestType == 'Multi Attendance Request'
                                  ? inTime
                                  : null,
                              outTime: requestType == 'Multi Attendance Request'
                                  ? outTime
                                  : null,
                              requestedOn: requestedDateLabel,
                              reason: reason.isNotEmpty ? reason : '-',
                              adminReason:
                                  adminReason.isNotEmpty ? adminReason : '-',
                              requestType: requestType,
                              approvedBy: (req['approved_by'] is Map &&
                                      req['approved_by']?['name'] != null)
                                  ? req['approved_by']['name'].toString()
                                  : req['approved_by']?.toString() ?? '-',
                              approvedOn: approvedDateLabel,
                              attendanceType: (type == 'check_in')
                                  ? 'CHECK IN'
                                  : (type == 'check_out')
                                      ? 'CHECK OUT'
                                      : '',
                              showActions: showActionButtons,
                              showCancel: isOwnRequest && isPending,
                              onCancel: isOwnRequest && isPending
                                  ? () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Cancel Request'),
                                          content: const Text(
                                              'Are you sure you want to cancel this request?'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    NavigationUtils.pop(ctx, false),
                                                child: const Text('No')),
                                            ElevatedButton(
                                                onPressed: () =>
                                                    NavigationUtils.pop(ctx, true),
                                                child: const Text('Yes')),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _cancelRequest(
                                            req['id'].toString());
                                      }
                                    }
                                  : null,
                              onApprove: showActionButtons
                                  ? () async {
                                      final reason = await _showReasonDialog(
                                          context, 'Approve');
                                      if (reason != null && reason.isNotEmpty) {
                                        await _handleAttendanceAction(
                                            req['id'].toString(),
                                            'Approved',
                                            requestType,
                                            reason);
                                      }
                                    }
                                  : null,
                              onReject: showActionButtons
                                  ? () async {
                                      final reason = await _showReasonDialog(
                                          context, 'Reject');
                                      if (reason != null && reason.isNotEmpty) {
                                        await _handleAttendanceAction(
                                            req['id'].toString(),
                                            'Rejected',
                                            requestType,
                                            reason);
                                      }
                                    }
                                  : null,
                            );
                          },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _handleAttendanceAction(String requestId, String status,
      String requestType, String reason) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      if (requestType == 'Time Change Request') {
        await ApiService().attendanceChangeTimeAction(
          context: context,
          apiToken: user.data.apiToken,
          attendanceUpdateRequestId: requestId,
          status: status,
          reason: reason,
        );
      } else if (requestType == 'Multi Attendance Request') {
        await ApiService().attendanceRequestAction(
          context: context,
          apiToken: user.data.apiToken,
          attendanceId: requestId,
          status: status,
          reason: reason,
        );
      }
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, 'Request $status successfully');
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
              title: Text('$action Request'),
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

  Future<void> _cancelRequest(String requestId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await ApiService().cancelChangeTimeRequest(
        context: context,
        apiToken: user.data.apiToken,
        attendanceUpdateRequestId: requestId,
      );
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, 'Request cancelled successfully');
      await _fetchRequests();
    } catch (e) {
      Navigator.of(context).pop();
      SnackBarUtils.showError(context, e.toString());
    }
  }

  DateTime? _parseApprovedDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      // Try parsing with ISO format first
      if (dateStr.contains('T')) {
        return DateTime.parse(dateStr).toLocal();
      }
      // Try parsing with yyyy-MM-dd HH:mm:ss format
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateStr).toLocal();
    } catch (e) {
      print('Error parsing approved date: $dateStr - $e');
      return null;
    }
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
    final results = users
        .where((u) =>
            (u['name'] ?? '').toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) {
        final user = results[i];
        return ListTile(
          title: Text(user['name'] ?? 'User'),
          onTap: () => close(context, user),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = users
        .where((u) =>
            (u['name'] ?? '').toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, i) {
        final user = suggestions[i];
        return ListTile(
          title: Text(user['name'] ?? 'User'),
          onTap: () => close(context, user),
        );
      },
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerCard(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 4)
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                date != null ? DateFormat('dd MMM yyyy').format(date!) : label,
                style:
                    AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceRequestCard extends StatelessWidget {
  final String name;
  final String designation;
  final String status;
  final Color statusColor;
  final String attendanceDate;
  final String? actualTime;
  final String? requestedTime;
  final String? inTime;
  final String? outTime;
  final String requestedOn;
  final String reason;
  final String? adminReason;
  final String requestType;
  final String? approvedBy;
  final String? approvedOn;
  final String? attendanceType;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool showActions;
  final bool showCancel;
  final VoidCallback? onCancel;

  const AttendanceRequestCard({
    super.key,
    required this.name,
    required this.designation,
    required this.status,
    required this.statusColor,
    required this.attendanceDate,
    this.actualTime,
    this.requestedTime,
    this.inTime,
    this.outTime,
    required this.requestedOn,
    required this.reason,
    this.adminReason,
    required this.requestType,
    this.approvedBy,
    this.approvedOn,
    this.attendanceType,
    this.onApprove,
    this.onReject,
    this.showActions = false,
    this.showCancel = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isApproved = status.toLowerCase() == 'approved';
    final isRejected = status.toLowerCase() == 'rejected';
    return Container(
      padding: const EdgeInsets.all(0),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 150,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            Text(
              '${attendanceType ?? ''} ${requestType.toUpperCase().replaceAll('_', '')}',
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),
            const SizedBox(height: 5),
            _infoRow('Attendance Date', attendanceDate),
            if (requestType == 'Time Change Request') ...[
              _infoRow('Actual Time', actualTime ?? '-'),
              _infoRow('Requested Time', requestedTime ?? '-'),
            ] else if (requestType == 'Multi Attendance Request') ...[
              _infoRow('In Time', inTime ?? '-'),
              _infoRow('Out Time', outTime ?? '-'),
            ],
            _infoRow('Reason', reason),
            _infoRow('Requested On', requestedOn),
            if (isApproved && (approvedBy != null && approvedBy!.isNotEmpty))
              _infoRow('Approved By', approvedBy!, valueColor: Colors.green),
            if (isRejected && (approvedBy != null && approvedBy!.isNotEmpty))
              _infoRow('Rejected By', approvedBy!, valueColor: Colors.red),
            if (isApproved && (approvedOn != null && approvedOn!.isNotEmpty))
              _infoRow('Approved On', approvedOn!, valueColor: Colors.green),
            if (isRejected && (approvedOn != null && approvedOn!.isNotEmpty))
              _infoRow('Rejected On', approvedOn!, valueColor: Colors.red),
            if (isApproved && (adminReason != null && adminReason!.isNotEmpty))
              _infoRow('Approved Note', adminReason!, valueColor: Colors.green),
            if (isRejected && (adminReason != null && adminReason!.isNotEmpty))
              _infoRow('Rejected Reason', adminReason!, valueColor: Colors.red),
            if (showActions) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 32),
                    onPressed: onReject,
                    tooltip: 'Reject',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.check_circle,
                        color: Colors.green, size: 32),
                    onPressed: onApprove,
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
                    onPressed: onCancel,
                    tooltip: 'Cancel',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
              width: 120,
              child: Text('$label :',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary))),
          Expanded(
              child: Text(value,
                  style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500, color: valueColor))),
        ],
      ),
    );
  }
}
