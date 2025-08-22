import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import '../core/utils/responsive.dart';
import '../core/utils/navigation_utils.dart';
import '../services/notification_permission_service.dart';
import '../services/auto_checkout_service.dart';
import 'notification_permission_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Start the animation
    await _controller.forward();

    // Wait for animation to complete and add a small delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Get the UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Load saved user data if any
    await userProvider.loadUser();

    if (!mounted) return;

          // Check if user exists and redirect accordingly
      if (userProvider.user != null) {
        log(userProvider.user!.token);
        print('token ::: ${userProvider.user!.token} ');

        // Check for auto checkout on app start
        await AutoCheckoutService.instance.checkForAutoCheckoutOnAppStart(context);
        
        if (!mounted) return;
        
        // Check notification permission
        bool hasPermission = await NotificationPermissionService.isNotificationPermissionGranted();
        
        if (!mounted) return;
        
        if (!hasPermission) {
          // Show notification permission screen
          NavigationUtils.pushReplacement(
            context,
            NotificationPermissionScreen(
              onPermissionGranted: () {
                print('DEBUG: Splash screen - onPermissionGranted called');
                if (mounted) {
                  print('DEBUG: Splash screen - navigating to HomeScreen');
                  NavigationUtils.pushReplacement(context, const HomeScreen());
                }
              },
              onPermissionDenied: () {
                print('DEBUG: Splash screen - onPermissionDenied called');
                if (mounted) {
                  print('DEBUG: Splash screen - navigating to HomeScreen');
                  NavigationUtils.pushReplacement(context, const HomeScreen());
                }
              },
            ),
          );
        } else {
        NavigationUtils.pushReplacement(context, const HomeScreen());
      }
    } else {
      NavigationUtils.pushReplacement(context, const LoginScreen());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/NEPL_LOGO.png',
                        width: Responsive.responsiveValue(
                          context: context,
                          mobile: 200,
                          tablet: 300,
                        ),
                        height: Responsive.responsiveValue(
                          context: context,
                          mobile: 200,
                          tablet: 300,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.responsiveValue(
                          context: context,
                          mobile: 24,
                          tablet: 32,
                        ),
                      ),
                      Text(
                        'Nutanvij Electricals',
                        style: AppTypography.headlineLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
} 