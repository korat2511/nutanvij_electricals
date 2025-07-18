import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutanvij_electricals/screens/hrms/apply_expense_screen.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/constants/user_access.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';

class ExpenseRequestListScreen extends StatefulWidget {
  final bool isAllUsers;

  const ExpenseRequestListScreen({Key? key, this.isAllUsers = false})
      : super(key: key);

  @override
  State<ExpenseRequestListScreen> createState() =>
      _ExpenseRequestListScreenState();
}

class _ExpenseRequestListScreenState extends State<ExpenseRequestListScreen> {
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
      final expenses = await ApiService().getEmployeeExpenseList(
        context: context,
        apiToken: user.data.apiToken,
        userId: widget.isAllUsers ? null : user.data.id.toString(),
      );
      setState(() {
        _requests = expenses;
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
      final approvedByValue = req['approved_by'];
      final approvedByName =
          (approvedByValue is Map && approvedByValue['name'] != null)
              ? approvedByValue['name'].toString().toLowerCase()
              : approvedByValue?.toString().toLowerCase() ?? '';
      final matchesStatus =
          _selectedStatus == 'all' || status == _selectedStatus;
      final matchesUser = !widget.isAllUsers ||
          _selectedUser == null ||
          userId == (_selectedUser?['id']?.toString() ?? '');
      final matchesApprovedBy = !widget.isAllUsers ||
          _approvedBy == null ||
          _approvedBy!.isEmpty ||
          approvedByName.contains(_approvedBy!.toLowerCase());
      if (_fromDate != null || _toDate != null) {
        final requestDate = req['expense_date'] != null
            ? DateTime.parse(req['expense_date'])
            : null;
        if (requestDate == null) return false;
        if (_fromDate != null && requestDate.isBefore(_fromDate!)) {
          return false;
        }
        if (_toDate != null && requestDate.isAfter(_toDate!)) {
          return false;
        }
      }
      return matchesStatus && matchesUser && matchesApprovedBy;
    }).toList();
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
      filtered.sort((a, b) => (a['approved_by'] ?? '')
          .toString()
          .compareTo((b['approved_by'] ?? '').toString()));
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

  Future<void> _handleExpenseAction(String expenseId, String status, double requestedAmount) async {
    Map<String, dynamic>? result = await _showApprovalDialog(context, status, requestedAmount);
    if (result == null) return;


    log("RESULT == $result");


    final reason = result['reason'] as String;
    final approvedAmount = result['approvedAmount'] as int;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      var data = await ApiService().employeeExpenseRequestAction(
        context: context,
        apiToken: user.data.apiToken,
        expenseId: expenseId,
        approvedAmount: approvedAmount,
        status: status,
        reason: reason,
      );


      log("Data == $data");

      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, 'Expense $status successfully');
      await _fetchRequests();
    } catch (e) {
      Navigator.of(context).pop();
      SnackBarUtils.showError(context, e.toString());
    }
  }

  Future<bool> _showCancelConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Cancel Expense Request'),
          content: const Text(
            'Are you sure you want to cancel this expense request? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No, Keep It'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _cancelRequest(String expenseId) async {
    // Show confirmation dialog first
    final shouldCancel = await _showCancelConfirmationDialog(context);
    if (!shouldCancel) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await ApiService().employeeExpenseCancel(
        context: context,
        apiToken: user.data.apiToken,
        expenseId: expenseId,
      );
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, 'Request cancelled successfully');
      await _fetchRequests();
    } catch (e) {
      Navigator.of(context).pop();
      SnackBarUtils.showError(context, e.toString());
    }
  }

  Future<Map<String, dynamic>?> _showApprovalDialog(BuildContext context, String action, double requestedAmount) async {
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    String? reasonErrorText;
    String? amountErrorText;
    
    return await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('$action Expense'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (action.toLowerCase() == 'approved') ...[
                    Text('Requested Amount: ₹${requestedAmount.toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Approved Amount (₹)',
                        errorText: amountErrorText,
                        border: const OutlineInputBorder(),
                        prefixText: '₹',
                      ),
                      onChanged: (value) {
                        if (amountErrorText != null) {
                          setState(() => amountErrorText = null);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text('Please enter a note (reason) for this action:'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      errorText: reasonErrorText,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (reasonErrorText != null) {
                        setState(() => reasonErrorText = null);
                      }
                    },
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
                    bool isValid = true;
                    
                    // Validate reason
                    if (reasonController.text.trim().isEmpty) {
                      setState(() => reasonErrorText = 'Reason is required');
                      isValid = false;
                    }
                    
                    // Validate approved amount for approval action
                    if (action.toLowerCase() == 'approved') {
                      if (amountController.text.trim().isEmpty) {
                        setState(() => amountErrorText = 'Approved amount is required');
                        isValid = false;
                      } else {
                        try {
                          final approvedAmount = double.parse(amountController.text.trim());
                          if (approvedAmount <= 0) {
                            setState(() => amountErrorText = 'Approved amount must be greater than 0. Use reject if you want to reject the expense.');
                            isValid = false;
                          } else if (approvedAmount > requestedAmount) {
                            setState(() => amountErrorText = 'Approved amount cannot be greater than requested amount (₹${requestedAmount.toStringAsFixed(2)})');
                            isValid = false;
                          }
                        } catch (e) {
                          setState(() => amountErrorText = 'Please enter a valid amount');
                          isValid = false;
                        }
                      }
                    }
                    
                    if (isValid) {
                      final result = {
                        'reason': reasonController.text.trim(),
                        'approvedAmount': action.toLowerCase() == 'approved' 
                            ? int.parse(amountController.text.trim())
                            : 0,
                      };
                      Navigator.of(ctx).pop(result);
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
      appBar: widget.isAllUsers
          ? CustomAppBar(
              title: widget.isAllUsers
                  ? 'Expense Requests'
                  : 'My Expense Requests',
              onMenuPressed: () => Navigator.of(context).pop(),
              showProfilePicture: false,
              showNotification: false,
            )
          : null,
      endDrawer: _buildFilterDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
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
                            widget.isAllUsers
                                ? 'All Users Expense Requests'
                                : 'My Expense Requests',
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
                    const SizedBox(height: 10),
                    Expanded(
                      child: _filteredRequests.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(
                                    Responsive.responsiveValue(
                                        context: context,
                                        mobile: 16,
                                        tablet: 32)),
                                child: Text('No expense requests found.',
                                    style: AppTypography.bodyMedium),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchRequests,
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(
                                    horizontal: Responsive.responsiveValue(
                                        context: context,
                                        mobile: 16,
                                        tablet: 32)),
                                itemCount: _filteredRequests.length,
                                separatorBuilder: (_, __) => SizedBox(
                                    height: Responsive.responsiveValue(
                                        context: context,
                                        mobile: 12,
                                        tablet: 24)),
                                itemBuilder: (context, i) {
                                  final req = _filteredRequests[i];
                                  final status =
                                      (req['status'] ?? '').toString();
                                  final userInfo = req['user'] ?? {};
                                  final reason =
                                      (req['description'] ?? '').toString();
                                  final adminReason =
                                      (req['admin_reason'] ?? '').toString();
                                  final requestedDate =
                                      req['created_at'] != null
                                          ? DateTime.parse(req['created_at'])
                                              .toLocal()
                                          : null;
                                  final requestedDateLabel =
                                      requestedDate != null
                                          ? DateFormat('dd MMM yyyy, hh:mm a')
                                              .format(requestedDate)
                                          : '';
                                  final expenseDate =
                                      req['expense_date'] != null &&
                                              req['expense_date'] != ''
                                          ? DateTime.parse(req['expense_date'])
                                              .toLocal()
                                          : null;
                                  final expenseDateLabel = expenseDate != null
                                      ? DateFormat('dd MMM yyyy')
                                          .format(expenseDate)
                                      : (req['expense_date'] ?? '-');
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
                                  if (status.toLowerCase() == 'cancelled') {
                                    statusColor = Colors.grey;
                                  }
                                  final approvedBy = req['approved_by'] is Map
                                      ? req['approved_by']['name']
                                      : req['approved_by'];
                                  final designationId =
                                      user?.data.designationId;
                                  final loggedInUserId =
                                      user?.data.id.toString() ?? '';
                                  final requestorId =
                                      userInfo['id']?.toString() ?? '';
                                  final requestorDesignationId =
                                      userInfo['designation_id'];

                                  final approvedAt = req['approved_at'];
                                  final approvedDateLabel = (approvedAt !=
                                              null &&
                                          (status.toLowerCase() == 'approved' ||
                                              status.toLowerCase() ==
                                                  'rejected'))
                                      ? DateTime.parse(approvedAt).toLocal()
                                      : null;
                                  final approvedOnLabel =
                                      approvedDateLabel != null
                                          ? DateFormat('dd MMM yyyy, hh:mm a')
                                              .format(approvedDateLabel)
                                          : '';
                                  final isApproved =
                                      status.toLowerCase() == 'approved';
                                  final isRejected =
                                      status.toLowerCase() == 'rejected';
                                  final isCancelled =
                                      status.toLowerCase() == 'cancelled';
                                  if (isCancelled) {
                                    statusColor = Colors.grey;
                                  }

                                  bool canShowAction = false;
                                  bool showCancel = false;
                                  if (widget.isAllUsers) {
                                    if (status.toLowerCase() == 'pending' &&
                                        UserAccess.hasAdminAccess(
                                            designationId)) {
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
                                            UserAccess.hasAdminAccess(
                                                designationId);
                                    showCancel =
                                        status.toLowerCase() == 'pending';
                                  }
                                  final showActions =
                                      canShowAction && widget.isAllUsers;
                                  return Container(
                                    margin: EdgeInsets.only(bottom: (i == _filteredRequests.length - 1) ? 240 : 0),
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
                                      border: Border.all(
                                          color: Colors.grey.withOpacity(0.15)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              width: 230,
                                              child: Text(
                                                  widget.isAllUsers
                                                      ? (userInfo['name'] ?? '-')
                                                      : (req['title'] ?? '-'),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppTypography.titleMedium
                                                      .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                status[0].toUpperCase() +
                                                    status
                                                        .substring(1)
                                                        .toLowerCase(),
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (widget.isAllUsers)
                                          _infoRow(
                                              'Title', req['title'] ?? '-'),
                                        _infoRow(
                                            'Amount', req['amount'] ?? '-'),
                                        if (isApproved && req['approved_amount'] != null)
                                          _infoRow(
                                            'Approved Amount', 
                                            req['approved_amount'].toString(),
                                            valueColor: Colors.green),
                                        _infoRow('Description', reason),
                                        _infoRow(
                                            'Expense Date', expenseDateLabel),
                                        _infoRow(
                                            'Requested On', requestedDateLabel),
                                        if (req[
                                                    'employee_expense_images'] !=
                                                null &&
                                            req['employee_expense_images']
                                                is List &&
                                            req['employee_expense_images']
                                                .isNotEmpty)
                                          _infoRow(
                                            'Image',
                                            'View Image',
                                            valueColor: AppColors.primary,
                                            valueStyle: AppTypography.bodySmall
                                                .copyWith(
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            onTap: () {
                                              final url =
                                                  req['employee_expense_images']
                                                          [0]['image_path'] ??
                                                      '';
                                              if (url.isNotEmpty) {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) =>
                                                      _FullScreenImageViewer(
                                                          imageUrl: url),
                                                );
                                              }
                                            },
                                          ),
                                        // if (adminReason.isNotEmpty)
                                        //   _infoRow('Admin Reason', adminReason, valueColor: Colors.red),
                                        if (isApproved &&
                                            (approvedBy != null &&
                                                approvedBy.isNotEmpty))
                                          _infoRow('Approved By', approvedBy,
                                              valueColor: Colors.green),
                                        if (isRejected &&
                                            (approvedBy != null &&
                                                approvedBy.isNotEmpty))
                                          _infoRow('Rejected By', approvedBy,
                                              valueColor: Colors.red),
                                        if (isApproved &&
                                            approvedOnLabel.isNotEmpty)
                                          _infoRow(
                                              'Approved On', approvedOnLabel,
                                              valueColor: Colors.green),
                                        if (isRejected &&
                                            approvedOnLabel.isNotEmpty)
                                          _infoRow(
                                              'Rejected On', approvedOnLabel,
                                              valueColor: Colors.red),
                                        if (isApproved &&
                                            adminReason.isNotEmpty)
                                          _infoRow('Approved Note', adminReason,
                                              valueColor: Colors.green),
                                        if (isRejected &&
                                            adminReason.isNotEmpty)
                                          _infoRow(
                                              'Rejected Reason', adminReason,
                                              valueColor: Colors.red),
                                        if (isCancelled)
                                          _infoRow('Status', 'Cancelled',
                                              valueColor: Colors.grey),

                                        if (showActions) ...[
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.close,
                                                    color: Colors.red,
                                                    size: 32),
                                                onPressed: () async {
                                                  if (reason.isNotEmpty) {
                                                    final requestedAmount = double.tryParse((req['amount'] ?? '0').toString()) ?? 0.0;
                                                    await _handleExpenseAction(
                                                        req['id'].toString(),
                                                        'Rejected',
                                                        requestedAmount);
                                                  }
                                                },
                                                tooltip: 'Reject',
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                    size: 32),
                                                onPressed: () async {
                                                  if (reason.isNotEmpty) {
                                                    final requestedAmount = double.tryParse((req['amount'] ?? '0').toString()) ?? 0.0;
                                                    await _handleExpenseAction(
                                                        req['id'].toString(),
                                                        'Approved',
                                                        requestedAmount);
                                                  }
                                                },
                                                tooltip: 'Approve',
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (showCancel) ...[
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.close,
                                                    color: Colors.red,
                                                    size: 32),
                                                onPressed: () => _cancelRequest(
                                                    req['id'].toString()),
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
                    ),
                  ],
                ),
                if (!widget.isAllUsers)
                  Padding(
                    padding: EdgeInsets.only(
                      left: Responsive.responsiveValue(
                          context: context, mobile: 14, tablet: 32),
                      right: Responsive.responsiveValue(
                          context: context, mobile: 14, tablet: 32),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CustomButton(
                            text: "View Payments",
                            onPressed: () {
                              SnackBarUtils.showSuccess(context, "Coming soon...");
                            }),
                        SizedBox(
                          height: Responsive.spacingM,
                        ),
                        // CustomButton(
                        //     text: "View Routes",
                        //     onPressed: () {
                        //       NavigationUtils.push(
                        //           context, const RouteScreen());
                        //     }),
                        // SizedBox(
                        //   height: Responsive.spacingM,
                        // ),
                        CustomButton(
                            text: "Add Expenses",
                            onPressed: () {
                              NavigationUtils.push(
                                  context, const ApplyExpenseScreen());
                            }),
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom +
                              Responsive.spacingM,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _infoRow(String label, String value,
      {Color? valueColor, TextStyle? valueStyle, VoidCallback? onTap}) {
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
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: valueStyle ??
                    AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: valueColor,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Filter & Sort',
                style: AppTypography.titleMedium
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status',
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold)),
                  ...[
                    'all',
                    'pending',
                    'approved',
                    'rejected'
                  ].map((status) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: RadioListTile<String>(
                          value: status,
                          groupValue: _selectedStatus,
                          onChanged: (val) =>
                              setState(() => _selectedStatus = val!),
                          title: Text(status == 'all'
                              ? 'All'
                              : status[0].toUpperCase() + status.substring(1)),
                          activeColor: AppColors.primary,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )),
                ],
              ),
            ),
            const Divider(height: 32),
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
                                        initialDate: _toDate ?? DateTime.now(),
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
                                      initialDate: _fromDate ?? DateTime.now(),
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
            if (widget.isAllUsers) ...[
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
                  border: Border.all(color: AppColors.primary.withOpacity(0.5)),
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
    final results = users
        .where((u) =>
            (u['name'] ?? '').toLowerCase().contains(query.toLowerCase()))
        .toList();
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
    final suggestions = users
        .where((u) =>
            (u['name'] ?? '').toLowerCase().contains(query.toLowerCase()))
        .toList();
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

class _DatePickerCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerCard({
    required this.label,
    required this.date,
    required this.onTap,
  });

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

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Hero(
          tag: imageUrl,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, color: Colors.white, size: 80),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            },
          ),
        ),
      ),
    );
  }
}
