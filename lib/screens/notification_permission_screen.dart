import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/navigation_utils.dart';
import '../services/notification_permission_service.dart';
import '../core/utils/snackbar_utils.dart';
import 'home/home_screen.dart';

class NotificationPermissionScreen extends StatefulWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;
  final bool isSkippable;
  final bool shouldNavigateToHome;

  const NotificationPermissionScreen({
    Key? key,
    this.onPermissionGranted,
    this.onPermissionDenied,
    this.isSkippable = true,
    this.shouldNavigateToHome = true,
  }) : super(key: key);

  @override
  State<NotificationPermissionScreen> createState() => _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState extends State<NotificationPermissionScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Stay Updated',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Enable notifications to receive important updates about:\n\n'
                '• Attendance reminders\n'
                '• Task assignments\n'
                '• Leave approvals\n'
                '• Important announcements',
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Allow Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Allow Notifications',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Skip Button (if skippable)
              if (widget.isSkippable)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _skipPermission,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Skip for Now',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);

    try {
      bool granted = await NotificationPermissionService.requestNotificationPermission(context);
      
      if (!mounted) return;
      
      if (granted) {
        SnackBarUtils.showSuccess(context, 'Notification permission granted!');
        
        if (mounted) {
          print('DEBUG: Permission granted, navigating immediately');
          
          // Call callback first
          widget.onPermissionGranted?.call();
          
          // Immediate direct navigation
          if (widget.shouldNavigateToHome) {
            print('DEBUG: Direct navigation to HomeScreen');
            NavigationUtils.pushAndRemoveUntil(context, const HomeScreen());
          }
        }
      } else {
        SnackBarUtils.showError(context, 'Notification permission denied');
        
        if (mounted) {
          print('DEBUG: Permission denied, navigating immediately');
          
          // Call callback first
          widget.onPermissionDenied?.call();
          
          // Immediate direct navigation
          if (widget.shouldNavigateToHome) {
            print('DEBUG: Direct navigation to HomeScreen');
            NavigationUtils.pushAndRemoveUntil(context, const HomeScreen());
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to request permission: $e');
      }
      
      // Add a small delay before navigation
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        widget.onPermissionDenied?.call();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _skipPermission() {
    SnackBarUtils.showInfo(context, 'You can enable notifications later in settings');
    widget.onPermissionDenied?.call();
    
    // Direct navigation as fallback
    if (widget.shouldNavigateToHome) {
      print('DEBUG: Skip - Direct navigation to HomeScreen');
      NavigationUtils.pushAndRemoveUntil(context, const HomeScreen());
    }
  }
} 