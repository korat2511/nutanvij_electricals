import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/constants/user_access.dart';

class AllUserAttendanceScreen extends StatefulWidget {
  const AllUserAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AllUserAttendanceScreen> createState() => _AllUserAttendanceScreenState();
}

class _AllUserAttendanceScreenState extends State<AllUserAttendanceScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoadingUsers = false;
  bool _isLoadingAttendance = false;
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _selectedUser;
  Set<int> _presentDays = {};
  List<Map<String, dynamic>> _attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user == null) return;
      final response = await ApiService().getUserList(
        context: context,
        apiToken: user.data.apiToken,
        search: '',
      );
      final designationId = user.data.designationId;
      List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(response);
      // If not admin, filter users to only those with a lower designation
      if (!UserAccess.hasAdminAccess(designationId)) {
        users = users.where((u) => UserAccess.isBelow(designationId, u['designation_id'])).toList();
      }
      setState(() {
        _users = users;
      });
    } catch (e) {
      SnackBarUtils.showError(context, e.toString());
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _fetchAttendanceForUser() async {
    if (_selectedUser == null) return;
    setState(() => _isLoadingAttendance = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final admin = userProvider.user;
      if (admin == null) return;
      final startDate = DateFormat('yyyy-MM-01').format(_selectedMonth);
      final endDate = DateFormat('yyyy-MM-dd').format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));
      // Fetch all pages for the month
      List<Map<String, dynamic>> allRecords = [];
      int page = 1;
      while (true) {
      final records = await ApiService().getAttendanceList(
        context: context,
        apiToken: admin.data.apiToken,
        startDate: startDate,
        endDate: endDate,
        userId: _selectedUser!['id'].toString(),
          page: page,
        );
        if (records.isEmpty) break;
        allRecords.addAll(records);
        if (records.length < 10) break; // No more pages
        page++;
      }
      log("Attendance List For User \\${_selectedUser!['id']} \\${allRecords.length}");
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
      SnackBarUtils.showError(context, e.toString());
    } finally {
      setState(() => _isLoadingAttendance = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final designationId = user?.data.designationId;
    final isAdmin = UserAccess.hasAdminAccess(designationId) || UserAccess.hasSeniorEngineerAccess(designationId) || UserAccess.hasPartnerAccess(designationId);
    if (!isAdmin) {
      return  Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
            onMenuPressed: () => NavigationUtils.pop(context),
            title: 'All User Attendance'),
        body: const Center(child: Text('You do not have permission to view this page.')),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'All Users Attendance',
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
            _isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : GestureDetector(
                    onTap: () async {
                      final result = await showSearch<Map<String, dynamic>?>(

                        context: context,
                        delegate: _UserSearchDelegate(_users),
                      );
                      if (result != null) {
                        setState(() {
                          _selectedUser = result;
                        });
                        _fetchAttendanceForUser();
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
                              _selectedUser == null
                                  ? 'Select User'
                                  : _selectedUser?['name'] ?? 'User',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                          if (_selectedUser != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedUser = null;
                                  _attendanceRecords = [];
                                  _presentDays = {};
                                });
                              },
                              child: const Icon(Icons.close, color: Colors.red, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            if (_selectedUser != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCalendar(context),
                      const SizedBox(height: 16),
                      _buildLogwiseView(context),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final firstWeekday = firstDayOfMonth.weekday % 7;
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
                          _fetchAttendanceForUser();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        iconSize: Responsive.getIconSize(context),
                        onPressed: () {
                          setState(() {
                            _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                          });
                          _fetchAttendanceForUser();
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
                        return Container(
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
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (_isLoadingAttendance)
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.7),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildLogwiseView(BuildContext context) {
    if (_isLoadingAttendance) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_attendanceRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(Responsive.responsiveValue(context: context, mobile: 16, tablet: 32)),
          child: const Text('No attendance records found.'),
        ),
      );
    }
    final activities = <Map<String, dynamic>>[];
    for (final rec in _attendanceRecords) {
      final dateStr = rec['date'] ?? '';
      final dateFmt = dateStr.isNotEmpty ? DateFormat('yyyy-MM-dd').parse(dateStr) : null;
      final dateLabel = dateFmt != null ? DateFormat('MMMM dd, yyyy').format(dateFmt) : '';
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attendance Log', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...activities.map((activity) {
          final isCheckIn = activity['type'] == 'Check In';
          return Container(
            margin: EdgeInsets.only(bottom: Responsive.responsiveValue(context: context, mobile: 10, tablet: 20)),
            padding: EdgeInsets.symmetric(
              vertical: Responsive.responsiveValue(context: context, mobile: 10, tablet: 18),
              horizontal: Responsive.responsiveValue(context: context, mobile: 12, tablet: 24),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Responsive.responsiveValue(context: context, mobile: 12, tablet: 20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: Responsive.responsiveValue(context: context, mobile: 4, tablet: 8),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.responsiveValue(context: context, mobile: 8, tablet: 14)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Responsive.responsiveValue(context: context, mobile: 12, tablet: 20)),
                    color: isCheckIn
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.punchOut.withOpacity(0.1),
                  ),
                  child: SvgPicture.asset(
                    isCheckIn
                        ? "assets/svg/punchin.svg"
                        : "assets/svg/punchout.svg",
                    width: Responsive.responsiveValue(context: context, mobile: 18, tablet: 30),
                    height: Responsive.responsiveValue(context: context, mobile: 18, tablet: 30),
                    color: isCheckIn ? AppColors.primary : AppColors.punchOut,
                  ),
                ),
                SizedBox(width: Responsive.responsiveValue(context: context, mobile: 12, tablet: 20)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity['type']!,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: Responsive.responsiveValue(context: context, mobile: 13, tablet: 20),
                          )),
                      Text(activity['date']!,
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0XFF696969),
                            fontSize: Responsive.responsiveValue(context: context, mobile: 11, tablet: 16),
                          )),
                    ],
                  ),
                ),
                Text(formatTime(activity['time']),
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: Responsive.responsiveValue(context: context, mobile: 13, tablet: 20),
                    )),
              ],
            ),
          );
        }).toList(),
      ],
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
              title: Text(user['name'] ?? 'User'),
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
            title: Text(user['name'] ?? 'User'),
            onTap: () => close(context, user),
          );
        },
      ),
    );
  }
} 