import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'snackbar_utils.dart';

class TansporterValidationUtils {

  static bool canCreateTransporter(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return userProvider.user?.data.designationId == 1 || userProvider.user?.data.designationId == 2;
  }

  /// ✅ Email Validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  /// ✅ Phone Number Validation (10 digits)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    final phoneRegex = RegExp(r'^[6-9]\d{9}$'); // starts with 6-9 & 10 digits
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// ✅ PAN Card Validation (ABCDE1234F)
  static String? validatePanCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    if (!panRegex.hasMatch(value.toUpperCase().trim())) {
      return 'Enter a valid PAN number (e.g., ABCDE1234F)';
    }
    return null;
  }

  /// ✅ Fair (Amount) Validation
  static String? validateFair(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Enter a valid number';
    }
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    return null;
  }
}



