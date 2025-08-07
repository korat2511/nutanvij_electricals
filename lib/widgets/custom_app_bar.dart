import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive.dart';
import '../core/utils/navigation_utils.dart';
import '../providers/user_provider.dart';
import '../services/notification_storage_service.dart';
import '../screens/notifications_screen.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final bool showProfilePicture;
  final bool showNotification;
  final double height;
  final String? title;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.onMenuPressed,
    this.showProfilePicture = true,
    this.showNotification = true,
    this.height = kToolbarHeight + 32, // Added extra height for status bar
    this.title,
    this.actions,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

// Global key to access the app bar state
final GlobalKey<_CustomAppBarState> customAppBarKey = GlobalKey<_CustomAppBarState>();

class _CustomAppBarState extends State<CustomAppBar> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await NotificationStorageService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  void _onNotificationTap() {
    NavigationUtils.push(context, const NotificationsScreen()).then((_) {
      // Refresh unread count when returning from notifications screen
      _loadUnreadCount();
    });
  }

  // Method to refresh unread count from outside
  void refreshUnreadCount() {
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status bar placeholder
          SizedBox(height: MediaQuery.of(context).padding.top),

          // Actual app bar content
          Container(
            height: kToolbarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left side: Menu and Title/Logo
                Expanded(
                  child: Row(
                  children: [
                    GestureDetector(
                        onTap: widget.onMenuPressed,
                      child: Container(
                        height: Responsive.getIconSize(context),
                        width: Responsive.getIconSize(context),
                        padding: EdgeInsets.all(Responsive.spacingXS),
                        child: SvgPicture.asset(
                          "assets/svg/drawer.svg",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.spacingM,),
                      Expanded(
                        child: widget.title != null && widget.title!.isNotEmpty
                        ? Text(
                                widget.title!,
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                                overflow: TextOverflow.ellipsis,
                          )
                        : Image.asset(
                      'assets/images/NEPL_LOGO.png',
                      height: Responsive.getLogoHeight(context),
                        ),
                    ),
                  ],
                  ),
                ),

                // Right side: Actions, Notification, Profile
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.actions != null) ...widget.actions!,
                    if (widget.showNotification) ...[
                      Stack(
                        children: [
                          IconButton(
                            onPressed: _onNotificationTap,
                            icon: Icon(
                              Icons.notifications_outlined,
                              color: AppColors.textPrimary,
                              size: Responsive.getNotificationIconSize(context),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          if (_unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: EdgeInsets.all(Responsive.spacingXS),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontSize: Responsive.spacingXS * 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: Responsive.spacingM),
                    ],
                    if (widget.showProfilePicture)
                      GestureDetector(
                        onTap: () {
                          // Handle profile tap
                        },
                        child: Container(
                          width: Responsive.getProfileAvatarSize(context),
                          height: Responsive.getProfileAvatarSize(context),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              user?.data.name.isNotEmpty == true
                                  ? user!.data.name[0].toUpperCase()
                                  : 'U',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.primary,
                                fontSize: Responsive.getIconSize(context) * 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
