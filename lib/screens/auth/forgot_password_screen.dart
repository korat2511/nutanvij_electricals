import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 0; // 0: email, 1: otp, 2: new password
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _apiToken;
  int? _otpFromApi;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _handleSendEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final resp = await ApiService().forgotPassword(_emailController.text.trim());
      setState(() {
        _step = 1;
        _apiToken = resp['api_token'];
        _otpFromApi = resp['otp'];
      });
      SnackBarUtils.showSuccess(context, 'OTP sent to your email');
    } catch (e) {
      SnackBarUtils.showError(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.trim().length != 4) {
      SnackBarUtils.showError(context, 'Enter 4 digit OTP');
      return;
    }
    if (_otpFromApi != int.tryParse(_otpController.text.trim())) {
      SnackBarUtils.showError(context, 'Invalid OTP');
      return;
    }
    setState(() => _step = 2);
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ApiService().resetPassword(
        apiToken: _apiToken!,
        newPassword: _newPasswordController.text.trim(),
        confirmPassword: _confirmPasswordController.text.trim(),
      );
      SnackBarUtils.showSuccess(context, 'Password reset successfully');
      NavigationUtils.pop(context);
    } catch (e) {
      SnackBarUtils.showError(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => NavigationUtils.pop(context),
          ),
          title: const Text('Forgot Password', style: TextStyle(color: Colors.black)),
        ),
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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                      mobile: 32,
                      tablet: 48,
                    ),
                  ),
                  if (_step == 0) ...[
                    Text('Enter your registered email', style: AppTypography.headlineSmall),
                    SizedBox(height: 24),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter your email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 32),
                    CustomButton(
                      text: 'Send OTP',
                      onPressed: _handleSendEmail,
                      isLoading: _isLoading,
                    ),
                  ] else if (_step == 1) ...[
                    Text('Enter the 4 digit OTP sent to your email', style: AppTypography.headlineSmall),
                    SizedBox(height: 24),
                    CustomTextField(
                      controller: _otpController,
                      label: 'OTP',
                      keyboardType: TextInputType.number,
                      maxLines: 1,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(4),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter OTP';
                        if (value.length != 4) return 'OTP must be 4 digits';
                        if (!RegExp(r'^\d{4}').hasMatch(value)) return 'OTP must be 4 digits';
                        return null;
                      },
                    ),
                    SizedBox(height: 32),
                    CustomButton(
                      text: 'Verify OTP',
                      onPressed: _handleVerifyOtp,
                      isLoading: _isLoading,
                    ),
                  ] else if (_step == 2) ...[
                    Text('Set your new password', style: AppTypography.headlineSmall),
                    SizedBox(height: 24),
                    CustomTextField(
                      controller: _newPasswordController,
                      label: 'New Password',
                      obscureText: _obscureNew,
                      maxLines: 1,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                      validator: (value) => value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      obscureText: _obscureConfirm,
                      maxLines: 1,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (value) => value != _newPasswordController.text ? 'Passwords do not match' : null,
                    ),
                    SizedBox(height: 32),
                    CustomButton(
                      text: 'Reset Password',
                      onPressed: _handleResetPassword,
                      isLoading: _isLoading,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 