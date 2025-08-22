import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/navigation_utils.dart';
import '../../services/api_service.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    try {
      await ApiService().changePassword(
        context: context,
        apiToken: user!.data.apiToken,
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
        confirmPassword: _confirmPasswordController.text.trim(),
      );
      SnackBarUtils.showSuccess(context, 'Password changed successfully');
      Navigator.of(context).pop();
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
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: CustomAppBar(
          onMenuPressed: () => NavigationUtils.pop(context),
          title: 'Change Password',
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
                      mobile: 78,
                      tablet: 116,
                    ),
                  ),
                  CustomTextField(
                    controller: _currentPasswordController,
                    label: 'Current Password',
                    obscureText: _obscureCurrent,
                    maxLines: 1,
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSecondary),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter current password'
                        : null,
                  ),
                  SizedBox(
                      height: Responsive.responsiveValue(
                          context: context, mobile: 16, tablet: 24)),
                  CustomTextField(
                    controller: _newPasswordController,
                    label: 'New Password',
                    obscureText: _obscureNew,
                    maxLines: 1,
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscureNew ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textSecondary),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    validator: (value) => value == null || value.length < 6
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                  SizedBox(
                      height: Responsive.responsiveValue(
                          context: context, mobile: 16, tablet: 24)),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    obscureText: _obscureConfirm,
                    maxLines: 1,
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSecondary),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (value) => value != _newPasswordController.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  SizedBox(
                      height: Responsive.responsiveValue(
                          context: context, mobile: 32, tablet: 48)),
                  CustomButton(
                    text: 'Change Password',
                    onPressed: _handleChangePassword,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }
}
