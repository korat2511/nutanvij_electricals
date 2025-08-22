import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutanvij_electricals/core/utils/app_strings.dart';
import 'package:nutanvij_electricals/screens/inventory/providers/create_transporter_provider.dart';
import '../../core/utils/transporter_validations_utils.dart';
import '../../widgets/custom_button.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/image_picker_utils.dart';
import 'dart:io';
import '../../widgets/custom_text_field.dart';
import '../../core/utils/navigation_utils.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';

import '../auth/signup_screen.dart';

class CreateTransporterScreen extends StatefulWidget {
  @override
  _CreateTransporterScreenState createState() =>
      _CreateTransporterScreenState();
}

class _CreateTransporterScreenState extends State<CreateTransporterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _fairController = TextEditingController();
  final TextEditingController _pancardController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedCompany = "NEPL";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppStrings.create_transporters,
            style: AppTypography.titleLarge),
        backgroundColor: AppColors.primary,
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 2),
                CustomTextField(
                  controller: _nameController,
                  label: 'Transporter Name',
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  validator: TansporterValidationUtils.validateEmail,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _phoneNumberController,
                  label: 'Phone Number',
                  validator: TansporterValidationUtils.validatePhone,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                    signed: false, // disallows negative numbers
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // only digits
                    LengthLimitingTextInputFormatter(10), // max 10 digits
                  ],
                ),
                const SizedBox(height: 12),
                Text("Company",
                    style: AppTypography.bodySmall
                        .copyWith(fontWeight: FontWeight.w400)),
                Row(
                  children: [
                    Radio<String>(
                      value: "NEPL",
                      groupValue: _selectedCompany,
                      onChanged: (val) {
                        setState(() => _selectedCompany = val!);
                      },
                      activeColor: AppColors.primary,
                    ),
                    Text("NEPL"),
                    const SizedBox(width: 20), // small spacing
                    Radio<String>(
                      value: "NE",
                      groupValue: _selectedCompany,
                      onChanged: (val) {
                        setState(() => _selectedCompany = val!);
                      },
                      activeColor: AppColors.primary,
                    ),
                    Text("NE"),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _addressController,
                  label: 'Address',
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _pancardController,
                  label: 'Pancard Number',
                  validator: TansporterValidationUtils.validatePanCard,
                  inputFormatters: [
                    UpperCaseTextFormatter(),
                    // custom: force uppercase
                    LengthLimitingTextInputFormatter(10),
                    // PAN is 10 chars
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                    // allow only letters & digits
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _fairController,
                  label: "Fair (₹)",
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, // allows decimal point input
                    signed: false, // disallows negative numbers
                  ),
                  validator: TansporterValidationUtils.validateFair,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _vehicleTypeController,
                  label: 'Vehicle Type',
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: AppStrings.create_transporters,
                  isLoading:
                      context.watch<CreateTransporterProvider>().isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final userProvider =
                          Provider.of<UserProvider>(context, listen: false);
                      final transporterProvider =
                          Provider.of<CreateTransporterProvider>(context,
                              listen: false);

                      await transporterProvider.createTransporter(
                        context: context,
                        apiToken: userProvider.user?.data.apiToken ?? '',
                        name: _nameController.text.trim(),
                        email: _emailController.text.trim(),
                        phone: _phoneNumberController.text.trim(),
                        address: _addressController.text.trim(),
                        pancard: _pancardController.text.trim(),
                        fair: _fairController.text.trim(),
                        vehicleType: _vehicleTypeController.text.trim(),
                        company: _selectedCompany.trim(),
                      );

                      if (context.mounted) {
                        NavigationUtils.pop(context, true);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _vehicleTypeController.dispose();
    _fairController.dispose();
    _pancardController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
