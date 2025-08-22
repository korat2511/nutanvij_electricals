import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/snackbar_utils.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../core/utils/navigation_utils.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;
  
  const EditProfileScreen({Key? key, required this.profileData}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Editable fields
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _dobController;
  late TextEditingController _bankAccountController;
  late TextEditingController _bankNameController;
  late TextEditingController _ifscCodeController;
  late TextEditingController _panCardController;
  late TextEditingController _aadharCardController;

  // Read-only fields (for display only)
  String? _employeeId;
  String? _designation;
  String? _department;
  String? _dateOfJoining;
  String? _salary;
  String? _documentStatus;
  int? _hasKeypadMobile;
  int? _isCheckinExempted;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadReadOnlyFields();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.profileData['name'] ?? '');
    _emailController = TextEditingController(text: widget.profileData['email'] ?? '');
    _mobileController = TextEditingController(text: widget.profileData['mobile'] ?? '');
    _dobController = TextEditingController(text: widget.profileData['dob'] ?? '');
    _bankAccountController = TextEditingController(text: widget.profileData['bank_account_no'] ?? '');
    _bankNameController = TextEditingController(text: widget.profileData['bank_name'] ?? '');
    _ifscCodeController = TextEditingController(text: widget.profileData['ifsc_code'] ?? '');
    _panCardController = TextEditingController(text: widget.profileData['pan_card_no'] ?? '');
    _aadharCardController = TextEditingController(text: widget.profileData['aadhar_card_no'] ?? '');
  }

  void _loadReadOnlyFields() {
    _employeeId = widget.profileData['employee_id'];
    _designation = widget.profileData['designation']?['name'];
    _department = widget.profileData['sub_department']?['name'];
    _dateOfJoining = widget.profileData['date_of_joining'];
    _salary = widget.profileData['salary'];
    _documentStatus = widget.profileData['document_status'];
    _hasKeypadMobile = widget.profileData['has_keypad_mobile'];
    _isCheckinExempted = widget.profileData['is_checkin_exmpted'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _bankAccountController.dispose();
    _bankNameController.dispose();
    _ifscCodeController.dispose();
    _panCardController.dispose();
    _aadharCardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
        child: Column(
          children: [
                    _buildEditableSection(),
                    const SizedBox(height: 16),
                    _buildReadOnlySection(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEditableSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editable Information',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          // Personal Information
          Text(
            'Personal Information',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            ),
          const SizedBox(height: 12),
          
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
            ),
            const SizedBox(height: 16),
          
          _buildTextField(
              controller: _mobileController,
            label: 'Mobile Number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Mobile number is required';
              }
              if (value.length != 10) {
                return 'Please enter a valid 10-digit mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _dobController,
            label: 'Date of Birth',
            icon: Icons.calendar_today,
            readOnly: true,
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 24),
          
          // Bank Information
          Text(
            'Bank Information',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildTextField(
            controller: _bankNameController,
            label: 'Bank Name',
            icon: Icons.account_balance,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Bank name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _bankAccountController,
            label: 'Account Number',
            icon: Icons.account_circle,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Account number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _ifscCodeController,
            label: 'IFSC Code',
            icon: Icons.code,
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'IFSC code is required';
              }
              if (value.length != 11) {
                return 'IFSC code must be 11 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _panCardController,
            label: 'PAN Card Number',
            icon: Icons.credit_card,
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'PAN card number is required';
              }
              if (value.length != 10) {
                return 'PAN card number must be 10 characters';
              }
              return null;
            },
            ),
            const SizedBox(height: 16),
          
          _buildTextField(
            controller: _aadharCardController,
            label: 'Aadhar Card Number',
            icon: Icons.credit_card,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Aadhar card number is required';
              }
              if (value.length != 12) {
                return 'Aadhar card number must be 12 digits';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Read-Only Information',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildReadOnlyField('Employee ID', _employeeId ?? 'N/A', Icons.badge),
          const SizedBox(height: 12),
          _buildReadOnlyField('Designation', _designation ?? 'N/A', Icons.work),
          const SizedBox(height: 12),
          _buildReadOnlyField('Department', _department ?? 'N/A', Icons.business),
          const SizedBox(height: 12),
          _buildReadOnlyField('Date of Joining', _dateOfJoining ?? 'N/A', Icons.event),
          const SizedBox(height: 12),
          _buildReadOnlyField('Salary', _salary ?? 'N/A', Icons.attach_money),
          const SizedBox(height: 12),
          _buildReadOnlyField('Document Status', _documentStatus ?? 'N/A', Icons.description),
          const SizedBox(height: 12),
          _buildReadOnlyField('Has Keypad Mobile', _hasKeypadMobile == 1 ? 'Yes' : 'No', Icons.phone_android),
          const SizedBox(height: 12),
          _buildReadOnlyField('Check-in Exempted', _isCheckinExempted == 1 ? 'Yes' : 'No', Icons.location_off),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      textCapitalization: textCapitalization,
      validator: validator,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock,
            color: Colors.grey.shade400,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Save Changes',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
            ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user == null) {
        SnackBarUtils.showError(context, 'User session expired');
        return;
      }

      final apiService = ApiService();
      final response = await apiService.editProfile(
        context: context,
        apiToken: user.data.apiToken,
        userId: widget.profileData['id'],
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        dob: _dobController.text.trim(),
        bankName: _bankNameController.text.trim(),
        bankAccountNo: _bankAccountController.text.trim(),
        ifscCode: _ifscCodeController.text.trim(),
        panCardNo: _panCardController.text.trim(),
        aadharCardNo: _aadharCardController.text.trim(),
      );

      if (response['status'] == 1) {
        SnackBarUtils.showSuccess(context, 'Profile updated successfully');
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        SnackBarUtils.showError(context, response['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to update profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
} 