import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutanvij_electricals/models/transporter.dart';
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
import '../../models/site.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';

import '../auth/signup_screen.dart';

class EditTransporterScreen extends StatefulWidget {
  final Transporter transporter;

  const EditTransporterScreen({Key? key, required this.transporter})
      : super(key: key);

  @override
  _EditTranspoerterScreenState createState() => _EditTranspoerterScreenState();
}

class _EditTranspoerterScreenState extends State<EditTransporterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _pancardController = TextEditingController();
  final TextEditingController _fairController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _minRangeController = TextEditingController();
  final TextEditingController _maxRangeController = TextEditingController();

  bool _isLoading = false;
  String _selectedCompany = "NEPL";

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final transporter = widget.transporter;
    _nameController.text = transporter.name;
    _addressController.text = transporter.address;
    _emailController.text = transporter.email;
    _phoneNumberController.text = transporter.phone;
    _pancardController.text = transporter.pancard;
    _fairController.text = transporter.fair;
    _vehicleTypeController.text = transporter.vehicleType;

    if (transporter.company == "NE" || transporter.company == "NEPL") {
      _selectedCompany = transporter.company;
    } else {
      _selectedCompany = "NEPL";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _pancardController.dispose();
    _fairController.dispose();
    _vehicleTypeController.dispose();
    _addressController.dispose();
    _minRangeController.dispose();
    _maxRangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Update Transporter', style: AppTypography.titleLarge),
        backgroundColor: AppColors.primary,
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                const SizedBox(height: 16),
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
                  validator: TansporterValidationUtils.validateFair,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _vehicleTypeController,
                  label: 'Vehicle Type',
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Update Transporter',
                  isLoading: _isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isLoading = true);
                      final userProvider =
                          Provider.of<UserProvider>(context, listen: false);
                      try {
                        await ApiService().updateTransporter(
                          context: context,
                          apiToken: userProvider.user?.data.apiToken ?? '',
                          transporterId: widget.transporter.id,
                          name: _nameController.text.trim(),
                          email: _emailController.text.trim(),
                          phone: _phoneNumberController.text.trim(),
                          address: _addressController.text.trim(),
                          pancard: _pancardController.text.trim(),
                          fair: _fairController.text.trim(),
                          vehicleType: _vehicleTypeController.text.trim(),
                          company: _selectedCompany.trim(),
                        );
                        if (mounted) {
                          SnackBarUtils.showSuccess(
                              context, 'Transporter updated successfully!');
                          NavigationUtils.pop(context, true);
                        }
                      } on ApiException catch (e) {
                        SnackBarUtils.showError(context, e.message);
                      } catch (e) {
                        SnackBarUtils.showError(
                            context, 'Something went wrong.');
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
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

}
