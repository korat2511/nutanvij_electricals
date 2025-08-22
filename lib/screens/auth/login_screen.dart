import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../notification_permission_screen.dart';
import '../../services/notification_permission_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _apiService = ApiService();

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    _dismissKeyboard();
    if (!_formKey.currentState!.validate()) return;

    try {
      // Set loading state
      Provider.of<UserProvider>(context, listen: false).setLoading(true);

      final user = await _apiService.login(
        _mobileController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      // Update user provider with logged in user
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.setUser(user, context);

      // Show success message
      SnackBarUtils.showSuccess(context, 'Login successful');
      
      // Check notification permission
      bool hasPermission = await NotificationPermissionService.isNotificationPermissionGranted();
      
      if (!mounted) return;
      
      if (!hasPermission) {
        // Show notification permission screen
        NavigationUtils.pushAndRemoveUntil(
          context,
          NotificationPermissionScreen(
            onPermissionGranted: () {
              print('DEBUG: Login screen - onPermissionGranted called');
              if (mounted) {
                print('DEBUG: Login screen - navigating to HomeScreen');
                NavigationUtils.pushAndRemoveUntil(context, const HomeScreen());
              }
            },
            onPermissionDenied: () {
              print('DEBUG: Login screen - onPermissionDenied called');
              if (mounted) {
                print('DEBUG: Login screen - navigating to HomeScreen');
                NavigationUtils.pushAndRemoveUntil(context, const HomeScreen());
              }
            },
          ),
        );
      } else {
      NavigationUtils.pushAndRemoveUntil(context, const HomeScreen());
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        'An unexpected error occurred. Please try again.',
      );
    } finally {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setLoading(false);
      }
    }
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.responsiveValue(
                context: context,
                mobile: 18,
                tablet: 40,
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: Responsive.responsiveValue(
                      context: context,
                      mobile: 40,
                      tablet: 75,
                    ),
                  ),
                  Image.asset(
                    'assets/images/NEPL_LOGO.png',
                    width: Responsive.responsiveValue(
                      context: context,
                      mobile: 150,
                      tablet: 175,
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
                    'Welcome Back 👋',
                    style: AppTypography.headlineMedium,
                    textAlign: TextAlign.start,
                  ),
                  Text(
                    'to NEPL',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  SizedBox(
                    height: Responsive.responsiveValue(
                      context: context,
                      mobile: 22,
                      tablet: 35,
                    ),
                  ),
                  Center(
                    child: Text(
                      'Login',
                      style: AppTypography.headlineLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: Responsive.responsiveValue(
                      context: context,
                      mobile: 32,
                      tablet: 48,
                    ),
                  ),
                  CustomTextField(
                    controller: _mobileController,
                    label: 'Mobile Number',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your mobile number';
                      }
                      if (value.length != 10) {
                        return 'Mobile number must be 10 digits';
                      }
                      return null;
                    },
                  ),
                  SizedBox(
                    height: Responsive.responsiveValue(
                      context: context,
                      mobile: 16,
                      tablet: 24,
                    ),
                  ),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    maxLines: 1,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        NavigationUtils.push(context, const ForgotPasswordScreen());
                      },
                      child: Text(
                        'Forgot Password?',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: Responsive.responsiveValue(
                      context: context,
                      mobile: 22,
                      tablet: 36,
                    ),
                  ),
                  Consumer<UserProvider>(
                    builder: (context, userProvider, _) {
                      return CustomButton(
                        text: 'Login',
                        onPressed: _handleLogin,
                        isLoading: userProvider.isLoading,
                      );
                    },
                  ),
                  SizedBox(
                    height: Responsive.responsiveValue(
                      context: context,
                      mobile: 16,
                      tablet: 24,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't have an account? ",
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          NavigationUtils.push(context, const SignupScreen());
                        },
                        child: Text(
                          'Sign up',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 