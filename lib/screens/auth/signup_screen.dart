import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/utils/image_picker_utils.dart';
import '../../models/designation.dart';
import '../../models/department.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_text_field.dart';
import 'login_screen.dart';
import '../../widgets/custom_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _designationController = TextEditingController();
  final _subDepartmentController = TextEditingController();
  final _salaryController = TextEditingController();
  final _dobController = TextEditingController();
  final _dateOfJoiningController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _ifscController = TextEditingController();
  final _panController = TextEditingController();
  final _aadharController = TextEditingController();
  int? _selectedDesignation;
  int? _selectedDepartment;
  int? _selectedSubDepartment;
  String? _selectedGender;
  String? _profileImagePath;
  bool _obscurePassword = true;
  final _apiService = ApiService();
  List<Designation> _designations = [];
  List<Department> _departments = [];
  bool _isLoadingDesignations = true;
  bool _isLoadingDepartments = true;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  // Add image paths for identity and bank images
  String? _aadharFrontImagePath;
  String? _aadharBackImagePath;
  String? _panCardImagePath;
  String? _passbookImagePath;

  @override
  void initState() {
    super.initState();
    _loadDesignations();
    _loadDepartments();
    _nameController.addListener(() {
      String capitalizedText = capitalize(_nameController.text);
      if (_nameController.text != capitalizedText) {
        _nameController.value = TextEditingValue(
          text: capitalizedText,
          selection: TextSelection.fromPosition(
            TextPosition(offset: capitalizedText.length),
          ),
        );
      }
    });
  }

  String capitalize(String input) {
    if (input.isEmpty) return "";
    return input[0].toUpperCase() + input.substring(1);
  }


  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (controller == _dobController) ? DateTime.now().subtract(const Duration(days: 365 * 18)) : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _loadDesignations() async {
    try {
      final designations = await _apiService.getDesignations();
      setState(() {
        _designations = designations;
        _isLoadingDesignations = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDesignations = false);
        SnackBarUtils.showError(
          context,
          'Failed to load designations. Please try again.',
        );
      }
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await _apiService.getDepartments();
      setState(() {
        _departments = departments;
        _isLoadingDepartments = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDepartments = false);
        SnackBarUtils.showError(
          context,
          'Failed to load departments. Please try again.',
        );
      }
    }
  }

  @override
  void dispose() {
    // _nameController.removeListener();
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _dateOfBirthController.dispose();
    _designationController.dispose();
    _subDepartmentController.dispose();
    _salaryController.dispose();
    _dobController.dispose();
    _dateOfJoiningController.dispose();
    _bankAccountController.dispose();
    _bankNameController.dispose();
    _ifscController.dispose();
    _panController.dispose();
    _aadharController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickDocumentImage(Function(String) setImagePath) async {
    final imagePath = await ImagePickerUtils.pickImage(
      context: context,
      allowCamera: true,
      allowGallery: true,
    );
    if (imagePath != null) {
      setState(() {
        setImagePath(imagePath);
      });
    }
  }

  Future<void> _handleSignup() async {
    _dismissKeyboard();
    if (!_formKey.currentState!.validate()) return;

    try {
      Provider.of<UserProvider>(context, listen: false).setLoading(true);

      final user = await _apiService.signup(
        name: _nameController.text,
        email: _emailController.text,
        mobile: _mobileController.text,
        password: _passwordController.text,
        designation: _selectedDesignation!,
        // department: _selectedDepartment!,
        subDepartmentId: _selectedSubDepartment!,
        address: _addressController.text,
        dateOfBirth: _dobController.text,
        gender: _selectedGender!,
        emergencyContact: _emergencyContactController.text,
        profileImagePath: _profileImagePath != null && _profileImagePath!.isNotEmpty ? File(_profileImagePath!) : null,
        bankAccountNo: _bankAccountController.text,
        bankName: _bankNameController.text,
        ifscCode: _ifscController.text,
        panCardNo: _panController.text,
        aadharCardNo: _aadharController.text,
        aadharCardFront: _aadharFrontImagePath != null && _aadharFrontImagePath!.isNotEmpty ? File(_aadharFrontImagePath!) : null,
        aadharCardBack: _aadharBackImagePath != null && _aadharBackImagePath!.isNotEmpty ? File(_aadharBackImagePath!) : null,
        panCardImage: _panCardImagePath != null && _panCardImagePath!.isNotEmpty ? File(_panCardImagePath!) : null,
        passbookImage: _passbookImagePath != null && _passbookImagePath!.isNotEmpty ? File(_passbookImagePath!) : null,

        salary: _salaryController.text,
        dateOfJoining: _dateOfJoiningController.text,
        context: context,
      );

      if (!mounted) return;

      // Show success message and navigate to login
      SnackBarUtils.showSuccess(context, 'Account created successfully');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        'Failed to create account. Please try again.',
      );
    } finally {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setLoading(false);
      }
    }
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
                      mobile: 22,
                      tablet: 35,
                    ),
                  ),


                  Center(
                    child: Text(
                      'Create Account',
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
                  // SECTION: Personal Details
                  Text('Personal Details', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  CustomTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    maxLines: 1,

                    validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  CustomTextField(
                    controller: _mobileController,
                    label: 'Mobile Number',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    validator: (value) => value == null || value.isEmpty ? 'Please enter your mobile number' : value.length != 10 ? 'Mobile number must be 10 digits' : null,
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value == null || value.isEmpty ? 'Please enter your email' : (!value.contains('@') || !value.contains('.')) ? 'Please enter a valid email' : null,
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: _obscurePassword,
                    maxLines: 1,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter a password' : value.length < 6 ? 'Password must be at least 6 characters' : null,
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  // Designation Dropdown
                  _isLoadingDesignations
                      ? PerfectDropdownField<int>(
                          label: 'Designation',
                          value: null,
                          items: const [],
                          itemLabel: (id) => '',
                          onChanged: (_) {},
                          validator: (_) => 'Loading...',
                        )
                      : PerfectDropdownField<int>(
                          label: 'Designation',
                          value: _selectedDesignation,
                          items: _designations.map((d) => d.id).toList(),
                          itemLabel: (id) => _designations.firstWhere((d) => d.id == id).name,
                          onChanged: (val) => setState(() => _selectedDesignation = val),
                          validator: (value) => value == null ? 'Please select a designation' : null,
                        ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  // Department Dropdown
                  _isLoadingDepartments
                      ? PerfectDropdownField<int>(
                          label: 'Department',
                          value: null,
                          items: const [],
                          itemLabel: (id) => '',
                          onChanged: (_) {},
                          validator: (_) => 'Loading...',
                        )
                      : PerfectDropdownField<int>(
                          label: 'Department',
                          value: _selectedDepartment,
                          items: _departments.map((d) => d.id).toList(),
                          itemLabel: (id) => _departments.firstWhere((d) => d.id == id).name,
                          onChanged: (val) {
                            setState(() {
                              _selectedDepartment = val;
                              _selectedSubDepartment = null; // Reset sub-department when department changes
                            });
                          },
                          validator: (value) => value == null ? 'Please select a department' : null,
                        ),

                  // Sub-Department Dropdown (only show if department has sub-departments)
                  if (_selectedDepartment != null &&
                      _departments.firstWhere((d) => d.id == _selectedDepartment).subDepartments.isNotEmpty)
                    Column(
                      children: [
                        SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                        PerfectDropdownField<int>(
                          label: 'Sub Department',
                          value: _selectedSubDepartment,
                          items: _departments
                              .firstWhere((d) => d.id == _selectedDepartment)
                              .subDepartments
                              .map((sd) => sd.id)
                              .toList(),
                          itemLabel: (id) => _departments
                              .firstWhere((d) => d.id == _selectedDepartment)
                              .subDepartments
                              .firstWhere((sd) => sd.id == id)
                              .name,
                          onChanged: (val) => setState(() => _selectedSubDepartment = val),
                          validator: (value) => value == null ? 'Please select a sub department' : null,
                        ),
                      ],
                    ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  CustomTextField(
                    controller: _addressController,
                    label: 'Address',
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  GestureDetector(
                    onTap: () => _selectDate(context, _dobController),
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: _dobController,
                        label: 'Date of Birth',
                        suffixIcon: const Icon(Icons.calendar_today),
                        validator: (value) => value == null || value.isEmpty ? 'Please select your date of birth' : null,
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  GestureDetector(
                    onTap: () => _selectDate(context, _dateOfJoiningController),
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: _dateOfJoiningController,
                        label: 'Date of Joining',
                        suffixIcon: const Icon(Icons.calendar_today),
                        validator: (value) => value == null || value.isEmpty ? 'Please select your date of joining' : null,
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  // Gender Dropdown
                  PerfectDropdownField<String>(
                    label: 'Gender',
                    value: _selectedGender,
                    items: _genders,
                    itemLabel: (g) => g,
                    onChanged: (val) => setState(() => _selectedGender = val),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your gender';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),

                  CustomTextField(
                    controller: _emergencyContactController,
                    label: 'Emergency Contact Number',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],

                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 24, tablet: 36)),
                  // SECTION: Bank Details
                  Text('Bank Details', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  CustomTextField(
                    controller: _bankAccountController,
                    label: 'Bank Account Number (Optional)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  CustomTextField(
                    controller: _bankNameController,
                    label: 'Bank Name (Optional)',
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  CustomTextField(
                    controller: _ifscController,
                    label: 'IFSC Code (Optional)',
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 24, tablet: 36)),
                  // SECTION: Identity Details
                  Text('Identity Details', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  CustomTextField(
                    controller: _panController,
                    label: 'PAN Card Number (Optional)',
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  CustomTextField(
                    controller: _aadharController,
                    label: 'Aadhar Card Number (Optional)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 24, tablet: 36)),
                  // SECTION: Images
                  Text('Upload Images', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  _buildImagePickerRow('Aadhar Card Front', _aadharFrontImagePath, (path) => _aadharFrontImagePath = path),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  _buildImagePickerRow('Aadhar Card Back', _aadharBackImagePath, (path) => _aadharBackImagePath = path),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  _buildImagePickerRow('PAN Card Image', _panCardImagePath, (path) => _panCardImagePath = path),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  _buildImagePickerRow('Passbook Image', _passbookImagePath, (path) => _passbookImagePath = path),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 32, tablet: 48)),
                  CustomButton(
                    onPressed: _handleSignup,
                    text: 'Create Account',
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 14, tablet: 20)),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Already have an account? Login',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.responsiveValue(context: context, mobile: 32, tablet: 48)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for image picker row
  Widget _buildImagePickerRow(String label, String? imagePath, Function(String) setImagePath) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        imagePath != null
            ? Image.file(File(imagePath), width: 50, height: 50, fit: BoxFit.cover)
            : const SizedBox(width: 50, height: 50, child: Icon(Icons.image, color: Colors.grey)),
        IconButton(
          icon: const Icon(Icons.upload_file),
          onPressed: () => _pickDocumentImage(setImagePath),
        ),
      ],
    );
  }
}

class PerfectDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final String? Function(T?)? validator;

  const PerfectDropdownField({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value != null ? itemLabel(value!) : '');
    return FormField<T>(
      validator: validator,
      builder: (field) {
        return GestureDetector(
          onTap: () async {
            final result = await showModalBottomSheet<T>(
              context: context,
              isScrollControlled: true,
              builder: (context) => SafeArea(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(label, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: items.map((item) => ListTile(
                            title: Text(itemLabel(item)),
                            onTap: () => Navigator.pop(context, item),
                            selected: item == value,
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
            if (result != null) onChanged(result);
            field.didChange(result);
          },
          child: AbsorbPointer(
            child: CustomTextField(
              controller: controller,
              label: label,
              suffixIcon: const Icon(Icons.arrow_drop_down),
              validator: (_) => field.errorText,
            ),
          ),
        );
      },
    );
  }
} 