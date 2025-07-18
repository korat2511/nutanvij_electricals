import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';
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
import '../../models/site.dart';
import '../auth/signup_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../profile_screen.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

class _SiteSelectionDialog extends StatefulWidget {
  final List<Site> sites;
  final Position currentPosition;

  const _SiteSelectionDialog({
    required this.sites,
    required this.currentPosition,
  });

  @override
  State<_SiteSelectionDialog> createState() => _SiteSelectionDialogState();
}

class _SiteSelectionDialogState extends State<_SiteSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Site> _filteredSites = [];
  final Map<int, double> _siteDistances = {};
  final Map<int, bool> _siteWithinRange = {};

  @override
  void initState() {
    super.initState();
    _filteredSites = widget.sites;
    _calculateDistances();
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
      if (query.isEmpty) {
        _filteredSites = widget.sites;
      } else {
        _filteredSites = widget.sites.where((site) {
          return site.name.toLowerCase().contains(query) ||
                 site.company.toLowerCase().contains(query) ||
                 site.address.toLowerCase().contains(query) ||
                 site.status.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _calculateDistances() async {
    for (final site in widget.sites) {
      try {
        final distance = Geolocator.distanceBetween(
          widget.currentPosition.latitude,
          widget.currentPosition.longitude,
          double.parse(site.latitude),
          double.parse(site.longitude),
        );
        
        final minRange = site.minRange ?? 500; // Default to 500 if not set
        final isWithinRange = distance <= minRange;
        
        setState(() {
          _siteDistances[site.id] = distance;
          _siteWithinRange[site.id] = isWithinRange;
        });
      } catch (e) {
        setState(() {
          _siteDistances[site.id] = -1; // Error
          _siteWithinRange[site.id] = false;
        });
      }
    }
  }

  String _getDistanceText(int siteId) {
    final distance = _siteDistances[siteId];
    if (distance == null || distance < 0) return 'Distance unavailable';
    
    if (distance < 1000) {
      return '${distance.round()}m away';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km away';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Site',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search sites...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            // Sites List
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredSites.length,
                itemBuilder: (context, index) {
                  final site = _filteredSites[index];
                  final isWithinRange = _siteWithinRange[site.id] ?? false;
                  final distanceText = _getDistanceText(site.id);
                  
                  return Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isWithinRange 
                                ? AppColors.primary.withOpacity(0.1) 
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: isWithinRange ? AppColors.primary : Colors.grey,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          site.name,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              site.address,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isWithinRange ? 'You\'re at site' : distanceText,
                              style: AppTypography.bodySmall.copyWith(
                                color: isWithinRange ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        onTap: isWithinRange ? () => Navigator.of(context).pop(site) : null,
                      ),
                      if (index < _filteredSites.length - 1) const Divider(),
                    ],
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
  List<Site> _assignedSites = [];
  Position? _currentPosition;
  bool _isLoadingSites = false;
  String appVersion = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    getAppVersion();
    _autoAttendanceCheck();
    _loadAssignedSites();

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

  Future<void> _loadAssignedSites() async {
    if (_isLoadingSites) return;
    setState(() => _isLoadingSites = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user == null) return;
      _assignedSites = await ApiService().getSiteList(
        context: context,
        apiToken: user.data.apiToken,
      );
    } catch (e) {
      // Handle error silently as this is a background operation
    } finally {
      setState(() => _isLoadingSites = false);
    }
  }

  Future<void> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission is required for attendance');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is permanently denied. Please enable it in settings.');
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_currentPosition != null) {
      // Check if the cached position is less than 30 seconds old
      final now = DateTime.now();
      final positionTime = DateTime.fromMillisecondsSinceEpoch(_currentPosition!.timestamp.millisecondsSinceEpoch);
      if (now.difference(positionTime).inSeconds < 30) {
        return;
      }
    }

    try {
      _currentPosition = await LocationService.getCurrentPosition();
    } catch (e) {
      throw Exception('Failed to get location. Please try again.');
    }
  }

  Future<void> _refreshCurrentLocation() async {
    try {
      _currentPosition = await LocationService.getCurrentPosition();
    } catch (e) {
      throw Exception('Failed to get location. Please try again.');
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
      // Ensure we have location permission and current location
      await _ensureLocationPermission();
      await _getCurrentLocation();

      // For punch-in, show site selection with distance check
      Site? selectedSite;
      if (type == 'check_in') {
        if (_assignedSites.isEmpty) {
          await _loadAssignedSites();
          if (_assignedSites.isEmpty) {
            SnackBarUtils.showError(context, 'You are not assigned to any site');
            return;
          }
        }

        // Show site selection dialog with distance check
        selectedSite = await showDialog<Site>(
          context: context,
          builder: (context) => _SiteSelectionDialog(
            sites: _assignedSites,
            currentPosition: _currentPosition!,
          ),
        );

        if (selectedSite == null) {
          setState(() => _isMarkingAttendance = false);
          return;
        }
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

      // Compress image to <= 300KB
      String compressedPath = pickedFile.path;
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      if (fileSize > 300 * 1024) {
        final dir = await Directory.systemTemp.createTemp();
        final targetPath = '${dir.path}/compressed_attendance.jpg';
        final result = await FlutterImageCompress.compressAndGetFile(
          pickedFile.path,
          targetPath,
          quality: 80,
          minWidth: 600,
          minHeight: 600,
          format: CompressFormat.jpeg,
        );
        if (result != null && await result.length() <= 300 * 1024) {
          compressedPath = result.path;
        } else if (result != null) {
          // Try further compression if still too large
          final result2 = await FlutterImageCompress.compressAndGetFile(
            pickedFile.path,
            targetPath,
            quality: 50,
            minWidth: 400,
            minHeight: 400,
            format: CompressFormat.jpeg,
          );
          if (result2 != null && await result2.length() <= 300 * 1024) {
            compressedPath = result2.path;
          } else {
            SnackBarUtils.showError(context, 'Could not compress image below 300KB. Please try again.');
            setState(() => _isMarkingAttendance = false);
            return;
          }
        } else {
          SnackBarUtils.showError(context, 'Image compression failed.');
          setState(() => _isMarkingAttendance = false);
          return;
      }
      }

      // Get address with retry functionality
      String address = await _getAddressWithRetry();

      // Call API
      await ApiService().saveAttendance(
        context: context,
        apiToken: user.data.apiToken,
        type: type,
        latitude: _currentPosition!.latitude.toString(),
        longitude: _currentPosition!.longitude.toString(),
        address: address,
        imagePath: compressedPath,
        siteId: type == 'check_in' && selectedSite != null ? selectedSite.id : null,
      );

      SnackBarUtils.showSuccess(context, 'Attendance marked successfully');
      await _autoAttendanceCheck(); // Refresh flag and button state
    } catch (e) {
      String errorMessage = 'Failed to mark attendance';
      if (e.toString().contains('Network error')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('Session expired')) {
        errorMessage = 'Session expired. Please login again.';
      } else if (e is Exception) {
        errorMessage = e.toString();
      }
      SnackBarUtils.showError(context, errorMessage);
    } finally {
      setState(() => _isMarkingAttendance = false);
    }
  }

  Future<String> _getAddressWithRetry() async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        final result = await LocationService.getCurrentAddressWithRetry();
        
        if (result.isSuccess) {
          return result.address!;
        } else if (result.hasError) {
          // Show error dialog with retry option
          bool shouldRetry = await _showLocationErrorDialog(result.errorType!, result.errorMessage!);
          if (!shouldRetry) {
            return 'Address not available';
          }
          retryCount++;
          continue;
        } else {
          return result.address ?? 'Address not available';
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          return 'Address not available';
        }
        // Wait a bit before retrying
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
    
    return 'Address not available';
  }

  Future<bool> _showLocationErrorDialog(LocationErrorType errorType, String errorMessage) async {
    String title = 'Location Error';
    String message = errorMessage;
    String primaryButtonText = 'Retry';
    String secondaryButtonText = 'Continue without location';
    
    switch (errorType) {
      case LocationErrorType.permissionDenied:
        title = 'Location Permission Required';
        message = 'Location permission is required for attendance. Would you like to grant permission?';
        primaryButtonText = 'Grant Permission';
        break;
      case LocationErrorType.permissionDeniedForever:
        title = 'Location Permission Denied';
        message = 'Location permission is permanently denied. Please enable it in device settings to continue.';
        primaryButtonText = 'Open Settings';
        secondaryButtonText = 'Continue without location';
        break;
      case LocationErrorType.locationServiceDisabled:
        title = 'Location Services Disabled';
        message = 'Location services are disabled. Please enable location services in your device settings and try again.';
        primaryButtonText = 'Check & Retry';
        secondaryButtonText = 'Continue without location';
        break;
      case LocationErrorType.timeout:
      case LocationErrorType.networkError:
      case LocationErrorType.unknown:
        title = 'Location Error';
        message = '$errorMessage\n\nWould you like to try again?';
        break;
    }

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(secondaryButtonText),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              
              // Handle special cases for settings
              if (errorType == LocationErrorType.permissionDeniedForever || 
                  errorType == LocationErrorType.locationServiceDisabled) {
                try {
                  if (errorType == LocationErrorType.locationServiceDisabled) {
                    // For location service disabled, check if it's now enabled
                    final isEnabled = await LocationService.isLocationServiceEnabled();
                    if (!isEnabled) {
                      await AppSettings.openAppSettings();
                    } else {
                      // Location service is now enabled, refresh position
                      await _refreshCurrentLocation();
                    }
                  } else {
                    await AppSettings.openAppSettings();
                  }
                } catch (e) {
                  SnackBarUtils.showError(context, 'Could not open settings. Please open settings manually.');
                }
              }
            },
            child: Text(primaryButtonText),
          ),
        ],
      ),
    ) ?? false;
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

  Future<void> getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });


    log("appVersion == $appVersion");
    log("buildNumber == $buildNumber");


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
            child: Column(
              children: [
                Expanded(
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
                          ],
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Profile'),
                        onTap: () {
                          NavigationUtils.pop(context);
                          NavigationUtils.push(context, const ProfileScreen());
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
                        leading: const Icon(Icons.person_add_outlined),
                        title: const Text('Create User'),
                        onTap: () {
                          NavigationUtils.pop(context);
                          NavigationUtils.push(context, const SignupScreen(isFromCreateUser: true));
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Text(
                    'Version $appVersion ($buildNumber)',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
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
