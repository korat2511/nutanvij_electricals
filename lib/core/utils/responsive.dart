import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
  }

  // Base sizes for different device types
  static const double _baseMobileWidth = 375.0; // iPhone X width
  static const double _baseTabletWidth = 768.0; // iPad width

  // Icon sizes
  static double get menuIconMobile => 28.0;
  static double get menuIconTablet => 32.0;
  static double get logoHeightMobile => 32.0;
  static double get logoHeightTablet => 48.0;
  static double get notificationIconMobile => 24.0;
  static double get notificationIconTablet => 32.0;
  static double get profileAvatarMobile => 32.0;
  static double get profileAvatarTablet => 40.0;

  // Spacing
  static double get spacingXS => 4.0;
  static double get spacingS => 8.0;
  static double get spacingM => 16.0;
  static double get spacingL => 24.0;
  static double get spacingXL => 32.0;
  static double get spacingXXL => 48.0;

  // Get responsive value based on screen size
  static double responsiveValue({
    required BuildContext context,
    required double mobile,
    required double tablet,
  }) {
    // Get the screen width
    final size = MediaQuery.of(context).size;
    
    // If it's a tablet
    if (size.width >= 600) {
      // Scale based on tablet width
      final scale = size.width / _baseTabletWidth;
      return tablet * scale;
    }
    
    // For mobile
    final scale = size.width / _baseMobileWidth;
    return mobile * scale;
  }

  // Get responsive height value
  static double responsiveHeight({
    required BuildContext context,
    required double mobile,
    required double tablet,
  }) {
    final size = MediaQuery.of(context).size;
    final baseHeight = size.height;
    
    if (size.width >= 600) {
      final scale = baseHeight / _baseTabletWidth;
      return tablet * scale;
    }
    
    final scale = baseHeight / _baseMobileWidth;
    return mobile * scale;
  }

  // Get icon size based on device type
  static double getIconSize(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: menuIconMobile,
      tablet: menuIconTablet,
    );
  }

  // Get logo height based on device type
  static double getLogoHeight(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: logoHeightMobile,
      tablet: logoHeightTablet,
    );
  }

  // Get notification icon size
  static double getNotificationIconSize(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: notificationIconMobile,
      tablet: notificationIconTablet,
    );
  }

  // Get profile avatar size
  static double getProfileAvatarSize(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: profileAvatarMobile,
      tablet: profileAvatarTablet,
    );
  }
} 