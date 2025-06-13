import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/user_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/attendance_card.dart';
import '../../widgets/custom_app_bar.dart';
import '../auth/login_screen.dart';
import '../../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../hrms/attendance_summary_screen.dart';
import '../../core/utils/responsive.dart';
import '../auth/change_password_screen.dart';
import '../site/site_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _checkInTime;
  String? _checkOutTime;
  String? _attendanceFlag; // 'check_in' or 'check_out'
  bool _isMarkingAttendance = false;

  @override
  void initState() {
    super.initState();
    _autoAttendanceCheck();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _autoAttendanceCheck() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;
    try {
      final apiService = ApiService();
      final data =
          await apiService.attendanceCheck(context, user.data.apiToken);
      String? flag;
      String? inTime;
      String? outTime;
      if (data != null) {
        flag = data['flag'] as String?;
        if (data['data'] != null && data['data']['in_time'] != null) {
          inTime = data['data']['in_time'] as String?;
          outTime = data['data']['out_time'] as String?;
        }
      }
      setState(() {
        _attendanceFlag = flag;
        _checkInTime = inTime;
        _checkOutTime = outTime;
      });
    } catch (e) {
      SnackBarUtils.showError(context, "$e");
    }
  }

  void _handleLogout() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.logout();

    if (mounted) {
      SnackBarUtils.showSuccess(context, 'Logged out successfully');
      NavigationUtils.pushAndRemoveUntil(context, const LoginScreen());
    }
  }

  Future<void> _markAttendance(String type) async {
    setState(() => _isMarkingAttendance = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;
    try {
      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isMarkingAttendance = false);
          SnackBarUtils.showError(context, 'Location permission is required for attendance');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isMarkingAttendance = false);
        SnackBarUtils.showError(context, 'Location permission is permanently denied. Please enable it in settings.');
        return;
      }

      // Pick image
      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (pickedFile == null) {
        setState(() => _isMarkingAttendance = false);
        SnackBarUtils.showError(context, 'Selfie is required');
        return;
      }

      // Get location
      Position position;
      try {
        position = await LocationService.getCurrentPosition();
      } catch (e) {
        setState(() => _isMarkingAttendance = false);
        SnackBarUtils.showError(context, 'Failed to get location. Please try again.');
        return;
      }

      // Get address
      String address;
      try {
        address = await LocationService.getCurrentAddress();
      } catch (e) {
        address = 'Address not available';
      }

      // Call API
      await ApiService().saveAttendance(
        context: context,
        apiToken: user.data.apiToken,
        type: type,
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
        address: address,
        imagePath: pickedFile.path,
      );

      SnackBarUtils.showSuccess(context, 'Attendance marked successfully');
      await _autoAttendanceCheck(); // Refresh flag and button state
    } catch (e) {
      String errorMessage = 'Failed to mark attendance';
      if (e.toString().contains('Network error')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('Session expired')) {
        errorMessage = 'Session expired. Please login again.';
      }
      SnackBarUtils.showError(context, errorMessage);
    } finally {
      setState(() => _isMarkingAttendance = false);
    }
  }

  Widget _buildQuickActionButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Responsive.responsiveValue(context: context, mobile: 16, tablet: 24)),
      child: Container(
        padding: EdgeInsets.all(Responsive.responsiveValue(context: context, mobile: 16, tablet: 24)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Responsive.responsiveValue(context: context, mobile: 16, tablet: 24)),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              icon,
              width: Responsive.responsiveValue(context: context, mobile: 45, tablet: 64),
              height: Responsive.responsiveValue(context: context, mobile: 45, tablet: 64),
            ),
            SizedBox(height: Responsive.responsiveValue(context: context, mobile: 8, tablet: 16)),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  String? formatTime(String? timeStr) {
    if (timeStr == null || timeStr == "0000-00-00 00:00:00") return "--:--";
    try {
      final dateTime = DateTime.parse(timeStr);
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      if (timeStr.length >= 8) {
        return timeStr.substring(11, 16);
      }
      return "--:--";
    }
  }

  String? formatDate(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr == "0000-00-00 00:00:00") return "--/--/----";
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      if (dateTimeStr.length >= 10) {
        return dateTimeStr.substring(0, 10);
      }
      return "--/--/----";
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Morning'
        : now.hour < 17
            ? 'Afternoon'
            : 'Evening';

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final designationId = userProvider.user?.data.designationId;

    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: CustomAppBar(
            onMenuPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: Responsive.responsiveValue(context: context, mobile: 30, tablet: 48),
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: Text(
                          user?.data.name.isNotEmpty == true
                              ? user!.data.name[0].toUpperCase()
                              : 'U',
                          style: AppTypography.headlineMedium.copyWith(
                            color: AppColors.primary,
                            fontSize: Responsive.responsiveValue(context: context, mobile: 24, tablet: 36),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.responsiveValue(context: context, mobile: 8, tablet: 16)),
                      Text(
                        user?.data.name ?? 'User',
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontSize: Responsive.responsiveValue(context: context, mobile: 18, tablet: 28),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.data.email ?? '',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // if (user?.data.designation.name != null && user!.data.designation.name.isNotEmpty)
                      //   Text(
                      //     user.data.designation.name,
                      //     style: AppTypography.bodyMedium.copyWith(
                      //       color: Colors.white.withOpacity(0.9),
                      //       fontSize: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20),
                      //       fontWeight: FontWeight.w600,
                      //     ),
                      //     maxLines: 1,
                      //     overflow: TextOverflow.ellipsis,
                      //   ),
                      // Text(
                      //   '-',
                      //   style: AppTypography.bodyMedium.copyWith(
                      //     color: Colors.white.withOpacity(0.9),
                      //     fontSize: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20),
                      //   ),
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      // ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Profile'),
                  onTap: () {
                    NavigationUtils.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  onTap: () {
                    NavigationUtils.pop(context);
                    NavigationUtils.push(context, const ChangePasswordScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  onTap: () {
                    NavigationUtils.pop(context);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    NavigationUtils.pop(context);
                    _handleLogout();
                  },
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Responsive.responsiveValue(context: context, mobile: 14, tablet: 32)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$greeting, ',
                        style: AppTypography.headlineMedium
                            .copyWith(color: AppColors.textSecondary, fontSize: Responsive.responsiveValue(context: context, mobile: 18, tablet: 28)),
                      ),
                      Text(
                        user?.data.name.split(' ')[0] ?? 'User',
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.primary,
                          fontSize: Responsive.responsiveValue(context: context, mobile: 18, tablet: 28),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('dd MMMM yyyy, EEEE').format(now),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: Responsive.responsiveValue(context: context, mobile: 12, tablet: 17),
                    ),
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 20, tablet: 40)),
                  AttendanceCard(
                    checkInTime: formatTime(_checkInTime),
                    checkOutTime: formatTime(_checkOutTime),
                    checkInDate: formatDate(_checkInTime),
                    checkOutDate: formatDate(_checkOutTime),
                    onPunchIn: () => _markAttendance('check_in'),
                    onPunchOut: () => _markAttendance('check_out'),
                    isPunchedIn: _attendanceFlag == 'check_out',
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 24, tablet: 40)),
                  Text(
                    'Quick Action',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.responsiveValue(context: context, mobile: 16, tablet: 24),
                    ),
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 16, tablet: 24)),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: Responsive.isTablet(context) ? 3 : 2,
                    mainAxisSpacing: Responsive.responsiveValue(context: context, mobile: 16, tablet: 24),
                    crossAxisSpacing: Responsive.responsiveValue(context: context, mobile: 16, tablet: 24),
                    childAspectRatio: 1.2,
                    children: [
                      _buildQuickActionButton(
                        icon: 'assets/images/hrms.png',
                        label: 'HRMS',
                        onTap: () {
                          NavigationUtils.push(context, const AttendanceSummaryScreen());
                        },
                      ),
                      _buildQuickActionButton(
                        icon: 'assets/images/site.png',
                        label: 'Sites & Tasks',
                        onTap: () {
                          NavigationUtils.push(context, const SiteListScreen());
                        },
                      ),
                      _buildQuickActionButton(
                        icon: 'assets/images/accounting.png',
                        label: 'Accounting',
                        onTap: () {},
                      ),
                      _buildQuickActionButton(
                        icon: 'assets/images/inventory.png',
                        label: 'Inventory',
                        onTap: () {},
                      ),
                      _buildQuickActionButton(
                        icon: 'assets/images/setting.png',
                        label: 'Settings',
                        onTap: () {},
                      ),
                      _buildQuickActionButton(
                        icon: 'assets/images/marketing.png',
                        label: 'Marketing',
                        onTap: () {},
                      ),

                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isMarkingAttendance)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
