import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nutanvij_electricals/core/utils/navigation_utils.dart';
import 'package:nutanvij_electricals/screens/hrms/all_user_attendance_screen.dart';
import 'package:nutanvij_electricals/screens/hrms/expense_request_list_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/constants/user_access.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import 'apply_leave_screen.dart';
import 'edit_attendance_request_list_screen.dart';
import 'holiday_calendar_screen.dart';
import 'leave_request_list_screen.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  const AttendanceSummaryScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Set<int> _presentDays = {};
  bool _isLoadingCalendar = false;
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoadingActivity = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAttendanceForMonth();
  }

  Future<void> _fetchAttendanceForMonth() async {
    setState(() {
      _isLoadingCalendar = true;
      _isLoadingActivity = true;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user == null) return;
      final startDate = DateFormat('yyyy-MM-01').format(_selectedMonth);
      final endDate = DateFormat('yyyy-MM-dd')
          .format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));
      // Fetch all pages for the month
      List<Map<String, dynamic>> allRecords = [];
      int page = 1;
      while (true) {
      final records = await ApiService().getAttendanceList(
          context: context,
          apiToken: user.data.apiToken,
          startDate: startDate,
          endDate: endDate,
          userId: user.data.id.toString(),
          page: page,
        );
        if (records.isEmpty) break;
        allRecords.addAll(records);
        if (records.length < 10) break;
        page++;
      }
      final present = <int>{};
      for (final rec in allRecords) {
        if (rec['in_time'] != null) {
          final date = DateTime.tryParse(rec['date'] ?? '');
          if (date != null && date.month == _selectedMonth.month) {
            present.add(date.day);
          }
        }
      }
      setState(() {
        _presentDays = present;
        _attendanceRecords = allRecords;
      });
    } catch (e) {
      // Optionally show error
    } finally {
      setState(() {
        _isLoadingCalendar = false;
        _isLoadingActivity = false;
      });
    }
  }

  Future<void> _requestEditAttendance({
    required String attendanceId,
    required String type,
    required String initialTime,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;
    DateTime? pickedDate;
    TimeOfDay? pickedTime;
    String reason = '';
    final formKey = GlobalKey<FormState>();
    final reasonController = TextEditingController();
    bool submitted = false;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Edit Attendance Request',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Select Date',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().subtract(const Duration(days: 1)),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              pickedDate = picked;
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Date',
                              labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                              suffixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            controller: TextEditingController(
                              text: pickedDate != null ? DateFormat('yyyy-MM-dd').format(pickedDate!) : '',
                            ),
                            validator: (val) => (pickedDate == null) ? 'Please select a date' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select Time',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              pickedTime = picked;
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Time',
                              labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                              suffixIcon: const Icon(Icons.access_time, color: AppColors.primary),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            controller: TextEditingController(
                              text: pickedTime != null ? pickedTime!.format(context) : '',
                            ),
                            validator: (val) => (pickedTime == null) ? 'Please select a time' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: reasonController,
                        decoration: InputDecoration(
                          labelText: 'Reason',
                          labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Please enter a reason'
                            : null,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            submitted = true;
                            if (formKey.currentState!.validate()) {
                              reason = reasonController.text.trim();
                              Navigator.of(ctx).pop();
                            }
                          },
                          child: Text(
                            'Submit',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
    if (!submitted || reason.trim().isEmpty || pickedDate == null || pickedTime == null) return;
    // Combine date and time
    final combinedDateTime = DateTime(
      pickedDate!.year,
      pickedDate!.month,
      pickedDate!.day,
      pickedTime!.hour,
      pickedTime!.minute,
    );
    final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(combinedDateTime);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await ApiService().requestForChangeTime(
        context: context,
        apiToken: user.data.apiToken,
        attendanceId: attendanceId,
        type: type,
        time: formattedDateTime,
        reason: reason,
      );
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, 'Edit request sent successfully');
      await _fetchAttendanceForMonth();
    } catch (e) {
      Navigator.of(context).pop();
      SnackBarUtils.showError(context, e.toString());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final designationId = user?.data.designationId;

    final isAdmin = UserAccess.hasAdminAccess(designationId) ||
        UserAccess.hasSeniorEngineerAccess(designationId) ||
        UserAccess.hasPartnerAccess(designationId);


    return Scaffold(
      appBar: CustomAppBar(
        onMenuPressed: () => NavigationUtils.pop(context),
        title: 'Attendance Summary',
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          if (isAdmin)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.responsiveValue(
                    context: context, mobile: 12, tablet: 32),
                vertical: Responsive.responsiveValue(
                    context: context, mobile: 12, tablet: 20),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.group, color: Colors.white),
                  label: const Text('All Users Requests'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (ctx) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.access_time,
                                    color: AppColors.primary),
                                title: const Text('View User Attendances'),
                                onTap: () {
                                  NavigationUtils.pop(ctx);
                                  NavigationUtils.push(
                                      context, const AllUserAttendanceScreen());
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.access_time,
                                    color: AppColors.primary),
                                title: const Text('Attendance Requests'),
                                onTap: () {
                                  NavigationUtils.pop(ctx);
                                  NavigationUtils.push(
                                      context,
                                      const EditAttendanceRequestListScreen(
                                          isAllUsers: true));
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.beach_access,
                                    color: AppColors.primary),
                                title: const Text('Leave Requests'),
                                onTap: () {
                                  NavigationUtils.pop(ctx);
                                  NavigationUtils.push(
                                      context,
                                      const LeaveRequestListScreen(isAllUsers: true));
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.attach_money,
                                    color: AppColors.primary),
                                title: const Text('Expenses Requests'),
                                onTap: () {
                                  NavigationUtils.pop(ctx);
                                  NavigationUtils.push(
                                      context,
                                      const ExpenseRequestListScreen(isAllUsers: true));
                                },
                              ),


                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: Responsive.responsiveValue(
                  context: context, mobile: 12, tablet: 32),
              vertical: Responsive.responsiveValue(
                  context: context, mobile: 8, tablet: 16),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Responsive.responsiveValue(
                  context: context, mobile: 16, tablet: 24)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.black,
              indicator: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Responsive.responsiveValue(
                    context: context, mobile: 12, tablet: 18)),
              ),
              isScrollable: false,
              tabs: const [
                SizedBox(
                  width: 120,
                  child: Tab(text: 'Attendance'),
                ),
                SizedBox(
                  width: 120,
                  child: Tab(text: 'Leave'),
                ),
                SizedBox(
                  width: 120,
                  child: Tab(text: 'All Payment'),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(context),
                // const HolidayCalendarScreen(),
                  const LeaveRequestListScreen(isAllUsers: false),

                const ExpenseRequestListScreen()

                // Center(
                //     child:
                //         Text('All Payment', style: AppTypography.titleLarge)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.responsiveValue(
              context: context, mobile: 12, tablet: 32),
          vertical: Responsive.responsiveValue(
              context: context, mobile: 8, tablet: 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendar(context),
            SizedBox(
                height: Responsive.responsiveValue(
                    context: context, mobile: 12, tablet: 24)),
            _buildSummaryBox(context),
            SizedBox(
                height: Responsive.responsiveValue(
                    context: context, mobile: 16, tablet: 32)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Activity',
                    style: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                GestureDetector(
                  onTap: () {
                    NavigationUtils.push(
                        context, const EditAttendanceRequestListScreen());
                  },
                  child: Text('View all request',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.primary)),
                ),
              ],
            ),
            SizedBox(
                height: Responsive.responsiveValue(
                    context: context, mobile: 8, tablet: 16)),
            _buildActivityList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday=0, Monday=1, ...
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth);
    final cellSize = Responsive.responsiveValue(context: context, mobile: 32, tablet: 48);
    final cellRadius = Responsive.responsiveValue(context: context, mobile: 8, tablet: 14);
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;
    final isPastMonth = _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month);
    final today = now.day;
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.responsiveValue(context: context, mobile: 16, tablet: 32)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Responsive.responsiveValue(context: context, mobile: 16, tablet: 24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(monthName,
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        iconSize: Responsive.getIconSize(context),
                        onPressed: () {
                          setState(() {
                            _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                          });
                          _fetchAttendanceForMonth();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        iconSize: Responsive.getIconSize(context),
                        onPressed: () {
                          setState(() {
                            _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                          });
                          _fetchAttendanceForMonth();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: Responsive.responsiveValue(context: context, mobile: 8, tablet: 16)),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sun'),
                  Text('Mon'),
                  Text('Tue'),
                  Text('Wed'),
                  Text('Thu'),
                  Text('Fri'),
                  Text('Sat'),
                ],
              ),
              SizedBox(height: Responsive.responsiveValue(context: context, mobile: 4, tablet: 8)),
              // Calendar grid
              Column(
                children: List.generate(
                  ((daysInMonth + firstWeekday) / 7).ceil(),
                  (week) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (day) {
                        int dayNum = week * 7 + day - firstWeekday + 1;
                        if (week == 0 && day < firstWeekday || dayNum < 1 || dayNum > daysInMonth) {
                          return SizedBox(width: cellSize);
                        }
                        final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNum);
                        final isWorkingDay = date.weekday != DateTime.sunday;
                        final shouldColor = (isCurrentMonth && dayNum <= today) || isPastMonth;
                        Color? bg;
                        if (shouldColor && _presentDays.contains(dayNum)) {
                          bg = Colors.green.shade200;
                        } else if (shouldColor && isWorkingDay && !_presentDays.contains(dayNum)) {
                          bg = Colors.red.shade200;
                        }
                        return GestureDetector(
                          onTap: () => _showAttendanceDetails(date),
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            margin: EdgeInsets.symmetric(vertical: Responsive.responsiveValue(context: context, mobile: 2, tablet: 4)),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(cellRadius),
                            ),
                            child: Center(
                              child: Text(
                                dayNum.toString(),
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.black,
                                  fontSize: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (_isLoadingCalendar)
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.7),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryBox(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;
    final isFutureMonth = _selectedMonth.year > now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month > now.month);
    final today = now.day;
    final totalDays = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);

    // Calculate working days (Mon-Sat, skipping Sunday)
    int workingDays = 0;
    for (int i = 1; i <= totalDays; i++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, i);
      if (date.weekday != DateTime.sunday) {
        workingDays++;
      }
    }

    int presentDays = 0;
    int absentDays = 0;
    if (isCurrentMonth) {
      // Only count up to today
      int workingDaysTillToday = 0;
      for (int i = 1; i <= today; i++) {
        final date = DateTime(_selectedMonth.year, _selectedMonth.month, i);
        if (date.weekday != DateTime.sunday) {
          workingDaysTillToday++;
        }
      }
      presentDays = _presentDays.where((d) => d <= today).length;
      absentDays = workingDaysTillToday - presentDays;
    } else if (isFutureMonth) {
      presentDays = 0;
      absentDays = 0;
      // workingDays already set to full month
    } else {
      // Past month: use full month
      presentDays = _presentDays.length;
      absentDays = workingDays - presentDays;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.responsiveValue(context: context, mobile: 16, tablet: 32),
        horizontal: Responsive.responsiveValue(context: context, mobile: 8, tablet: 24),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.responsiveValue(context: context, mobile: 16, tablet: 24)),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text('Working Days', style: AppTypography.bodySmall),
              const SizedBox(height: 4),
              Text('$workingDays', style: AppTypography.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            children: [
              Text('Present Days', style: AppTypography.bodySmall),
              const SizedBox(height: 4),
              Text('$presentDays', style: AppTypography.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            children: [
              Text('Absent Days', style: AppTypography.bodySmall),
              const SizedBox(height: 4),
              Text('$absentDays', style: AppTypography.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  void _showAttendanceDetails(DateTime selectedDate) {
    // Find attendance records for the selected date
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final dayRecords = _attendanceRecords.where((rec) => rec['date'] == dateStr).toList();
    
    if (dayRecords.isEmpty) {
      SnackBarUtils.showInfo(context, 'No attendance records for ${DateFormat('MMMM dd, yyyy').format(selectedDate)}');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AttendanceDetailsModal(
        date: selectedDate,
        records: dayRecords,
        userName: 'Your Attendance',
      ),
    );
  }

  Widget _buildActivityList(BuildContext context) {
    if (_isLoadingActivity) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_attendanceRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(Responsive.responsiveValue(
              context: context, mobile: 16, tablet: 32)),
          child: const Text('No attendance records found.'),
        ),
      );
    }
    final activities = <Map<String, dynamic>>[];
    for (final rec in _attendanceRecords) {
      final dateStr = rec['date'] ?? '';
      final dateFmt =
          dateStr.isNotEmpty ? DateFormat('yyyy-MM-dd').parse(dateStr) : null;
      final dateLabel =
          dateFmt != null ? DateFormat('MMMM dd, yyyy').format(dateFmt) : '';
      if (rec['in_time'] != null) {
        activities.add({
          'type': 'Check In',
          'date': dateLabel,
          'time': rec['in_time'],
        });
      }
      if (rec['out_time'] != null) {
        activities.add({
          'type': 'Check Out',
          'date': dateLabel,
          'time': rec['out_time'],
        });
      }
    }
    activities.sort((a, b) {
      final aDate = a['date'] ?? '';
      final bDate = b['date'] ?? '';
      final aTime = a['time'] ?? '';
      final bTime = b['time'] ?? '';
      final cmp = bDate.compareTo(aDate);
      if (cmp != 0) return cmp;
      return bTime.compareTo(aTime);
    });
    return Column(
      children: activities.map((activity) {
        final isCheckIn = activity['type'] == 'Check In';
        final record = _attendanceRecords.firstWhere(
          (rec) =>
              (rec['in_time'] == activity['time'] &&
                  activity['type'] == 'Check In') ||
              (rec['out_time'] == activity['time'] &&
                  activity['type'] == 'Check Out'),
          orElse: () => {},
        );
        final isPending =
            (record['status'] ?? '').toString().toLowerCase() == 'pending';
        final isApproved =
            (record['status'] ?? '').toString().toLowerCase() == 'approved';
        return Container(
          margin: EdgeInsets.only(
              bottom: Responsive.responsiveValue(
                  context: context, mobile: 10, tablet: 20)),
          padding: EdgeInsets.symmetric(
            vertical: Responsive.responsiveValue(
                context: context, mobile: 10, tablet: 18),
            horizontal: Responsive.responsiveValue(
                context: context, mobile: 12, tablet: 24),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Responsive.responsiveValue(
                context: context, mobile: 12, tablet: 20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: Responsive.responsiveValue(
                    context: context, mobile: 4, tablet: 8),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (isPending)
                Container(
                  width: Responsive.responsiveValue(
                      context: context, mobile: 12, tablet: 18),
                  height: Responsive.responsiveValue(
                      context: context, mobile: 12, tablet: 18),
                  margin: EdgeInsets.only(
                      right: Responsive.responsiveValue(
                          context: context, mobile: 8, tablet: 12)),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                ),
              if (isApproved)
                Container(
                  width: Responsive.responsiveValue(
                      context: context, mobile: 12, tablet: 18),
                  height: Responsive.responsiveValue(
                      context: context, mobile: 12, tablet: 18),
                  margin: EdgeInsets.only(
                      right: Responsive.responsiveValue(
                          context: context, mobile: 8, tablet: 12)),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                ),
              Container(
                padding: EdgeInsets.all(Responsive.responsiveValue(
                    context: context, mobile: 8, tablet: 14)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                      Responsive.responsiveValue(
                          context: context, mobile: 12, tablet: 20)),
                  color: isCheckIn
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.punchOut.withOpacity(0.1),
                ),
                child: SvgPicture.asset(
                  isCheckIn
                      ? "assets/svg/punchin.svg"
                      : "assets/svg/punchout.svg",
                  width: Responsive.responsiveValue(
                      context: context, mobile: 18, tablet: 30),
                  height: Responsive.responsiveValue(
                      context: context, mobile: 18, tablet: 30),
                  color: isCheckIn ? AppColors.primary : AppColors.punchOut,
                ),
              ),
              SizedBox(
                  width: Responsive.responsiveValue(
                      context: context, mobile: 12, tablet: 20)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity['type']!,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: Responsive.responsiveValue(
                              context: context, mobile: 13, tablet: 20),
                        )),
                    Text(activity['date']!,
                        style: AppTypography.bodySmall.copyWith(
                          color: const Color(0XFF696969),
                          fontSize: Responsive.responsiveValue(
                              context: context, mobile: 11, tablet: 16),
                        )),
                  ],
                ),
              ),
              Text(formatTime(activity['time']),
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: Responsive.responsiveValue(
                        context: context, mobile: 13, tablet: 20),
                  )),
              SizedBox(
                  width: Responsive.responsiveValue(
                      context: context, mobile: 8, tablet: 16)),
              GestureDetector(
                onTap: () async {
                  log("${activity['type']}");

                  final attendanceId = record['id']?.toString() ?? '';
                  final type = (activity['type'] == "Check In")
                      ? 'check_in'
                      : 'check_out';
                  final time = activity['time'] ?? '';
                  if (attendanceId.isNotEmpty && time.isNotEmpty) {
                    await _requestEditAttendance(
                      attendanceId: attendanceId,
                      type: type,
                      initialTime: time,
                    );
                  }
                },
                child:
                    const Icon(Icons.edit, color: AppColors.primary, size: 18),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String formatTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr == "0000-00-00 00:00:00") return "--:--:--";
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('HH:mm:ss').format(dateTime);
    } catch (e) {
      if (dateTimeStr.length >= 19) {
        return dateTimeStr.substring(11, 19);
      }
      return "--:--:--";
    }
  }

  // Helper to convert HH:mm:ss to full ISO timestamp (today's date + time)
  String toFullTimestamp(String timeStr) {
    // If already a full timestamp, return as is
    if (timeStr.contains('-') && timeStr.contains(':') && timeStr.length >= 19) return timeStr;
    // If only time (HH:mm:ss), add today's date
    final now = DateTime.now();
    final datePart = DateFormat('yyyy-MM-dd').format(now);
    return '$datePart $timeStr';
  }
}

class _AttendanceDetailsModal extends StatelessWidget {
  final DateTime date;
  final List<Map<String, dynamic>> records;
  final String userName;

  const _AttendanceDetailsModal({
    required this.date,
    required this.records,
    required this.userName,
  });

  String formatTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr == "0000-00-00 00:00:00") return "--:--:--";
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('HH:mm:ss').format(dateTime);
    } catch (e) {
      if (dateTimeStr.length >= 19) {
        return dateTimeStr.substring(11, 19);
      }
      return "--:--:--";
    }
  }

  String formatDate(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr == "0000-00-00 00:00:00") return "";
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.all(Responsive.responsiveValue(context: context, mobile: 16, tablet: 24)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMMM dd, yyyy').format(date),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Responsive.responsiveValue(context: context, mobile: 16, tablet: 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Details',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 16, tablet: 24)),
                  ...records.map((record) => _buildAttendanceRecord(context, record)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecord(BuildContext context, Map<String, dynamic> record) {
    final hasCheckIn = record['in_time'] != null;
    final hasCheckOut = record['out_time'] != null;
    
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.responsiveValue(context: context, mobile: 16, tablet: 24)),
      padding: EdgeInsets.all(Responsive.responsiveValue(context: context, mobile: 16, tablet: 20)),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(Responsive.responsiveValue(context: context, mobile: 12, tablet: 16)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasCheckIn) ...[
            _buildAttendanceEntry(
              context: context,
              type: 'Check In',
              time: record['in_time'],
              address: record['check_in_address'] ?? record['address'] ?? 'Not available',
              latitude: record['check_in_latitude'] ?? record['latitude'] ?? 'Not available',
              longitude: record['check_in_longitude'] ?? record['longitude'] ?? 'Not available',
              icon: 'assets/svg/punchin.svg',
              color: AppColors.primary,
              record: record,
            ),
            if (hasCheckOut) 
              SizedBox(height: Responsive.responsiveValue(context: context, mobile: 16, tablet: 24)),
          ],
          if (hasCheckOut) ...[
            _buildAttendanceEntry(
              context: context,
              type: 'Check Out',
              time: record['out_time'],
              address: record['check_out_address'] ?? record['address'] ?? 'Not available',
              latitude: record['check_out_latitude'] ?? record['latitude'] ?? 'Not available',
              longitude: record['check_out_longitude'] ?? record['longitude'] ?? 'Not available',
              icon: 'assets/svg/punchout.svg',
              color: AppColors.punchOut,
              record: record,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceEntry({
    required BuildContext context,
    required String type,
    required String? time,
    required String address,
    required String latitude,
    required String longitude,
    required String icon,
    required Color color,
    required Map<String, dynamic> record,
  }) {
    final imageField = type == 'Check In' ? 'image_in' : 'image_out';
    final imageUrl = record[imageField] ?? record['image'] ?? record['selfie'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.responsiveValue(context: context, mobile: 8, tablet: 12)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Responsive.responsiveValue(context: context, mobile: 8, tablet: 12)),
              ),
              child: SvgPicture.asset(
                icon,
                width: Responsive.responsiveValue(context: context, mobile: 16, tablet: 24),
                height: Responsive.responsiveValue(context: context, mobile: 16, tablet: 24),
                color: color,
              ),
            ),
            SizedBox(width: Responsive.responsiveValue(context: context, mobile: 12, tablet: 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    formatTime(time),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.responsiveValue(context: context, mobile: 12, tablet: 16)),
        _buildInfoRow(context, 'Address', address, Icons.location_on),
        SizedBox(height: Responsive.responsiveValue(context: context, mobile: 8, tablet: 12)),
        Row(
          children: [
            Expanded(
              child: _buildInfoRow(context, 'Latitude', latitude, Icons.gps_fixed),
            ),
            SizedBox(width: Responsive.responsiveValue(context: context, mobile: 12, tablet: 16)),
            Expanded(
              child: _buildInfoRow(context, 'Longitude', longitude, Icons.gps_fixed),
            ),
          ],
        ),
        if (imageUrl != null && imageUrl.toString().isNotEmpty) ...[
          SizedBox(height: Responsive.responsiveValue(context: context, mobile: 12, tablet: 16)),
          _buildViewImageButton(context, imageUrl.toString(), type, color),
        ],
      ],
    );
  }

  Widget _buildViewImageButton(BuildContext context, String imageUrl, String type, Color color) {
    return GestureDetector(
      onTap: () => _showImage(context, imageUrl, type),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.responsiveValue(context: context, mobile: 12, tablet: 16),
          vertical: Responsive.responsiveValue(context: context, mobile: 8, tablet: 12),
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(Responsive.responsiveValue(context: context, mobile: 8, tablet: 12)),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera,
              color: color,
              size: Responsive.responsiveValue(context: context, mobile: 16, tablet: 20),
            ),
            SizedBox(width: Responsive.responsiveValue(context: context, mobile: 8, tablet: 12)),
            Text(
              'View $type Image',
              style: AppTypography.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImage(BuildContext context, String imageUrl, String type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text('$type Image'),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image, color: Colors.white, size: 80),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: Responsive.responsiveValue(context: context, mobile: 16, tablet: 20),
          color: AppColors.textSecondary,
        ),
        SizedBox(width: Responsive.responsiveValue(context: context, mobile: 8, tablet: 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
