import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/image_picker_utils.dart';
import '../../core/utils/image_compression_utils.dart';

class ApplyExpenseScreen extends StatefulWidget {
  const ApplyExpenseScreen({Key? key}) : super(key: key);

  @override
  State<ApplyExpenseScreen> createState() => _ApplyExpenseScreenState();
}

class _ApplyExpenseScreenState extends State<ApplyExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? _title;
  String? _amount;
  String? _description;
  DateTime? _expenseDate;
  List<String> _imagePaths = [];

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  Future<void> _pickImages() async {
    final picked = await ImagePickerUtils.pickMultipleImages(context: context);
    if (picked.isNotEmpty) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Compress images
        final imageFiles = picked.map((p) => File(p)).toList();
        final compressedImages = await ImageCompressionUtils.compressImages(imageFiles);
        
        setState(() {
          _imagePaths = compressedImages.map((f) => f.path).toList();
        });
      } finally {
        // Hide loading indicator
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expenseDate == null) {
      SnackBarUtils.showError(context, 'Please select expense date.');
      return;
    }
    setState(() => _isLoading = true);
    _formKey.currentState!.save();
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user == null) throw Exception('User not found');
      await ApiService().applyForEmployeeExpense(
        context: context,
        apiToken: user.data.apiToken,
        title: _title!,
        amount: _amount!,
        description: _description ?? '',
        expenseDate: DateFormat('yyyy-MM-dd').format(_expenseDate!),
        images: _imagePaths.map((p) => XFile(p)).toList(),
      );
      SnackBarUtils.showSuccess(context, 'Expense applied successfully!');
      Navigator.of(context).pop();
    } catch (e) {
      SnackBarUtils.showError(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Apply Expense',
        onMenuPressed: () => Navigator.of(context).pop(),
        showProfilePicture: false,
        showNotification: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.responsiveValue(context: context, mobile: 16, tablet: 32),
          vertical: 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter title',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSaved: (val) => _title = val,
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Text('Amount', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter amount',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSaved: (val) => _amount = val,
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Text('Description', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter description',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSaved: (val) => _description = val,
              ),
              const SizedBox(height: 16),
              Text('Expense Date', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _expenseDate != null ? DateFormat('dd MMM yyyy').format(_expenseDate!) : '',
                    ),
                    validator: (val) => _expenseDate == null ? 'Required' : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Images (Optional)', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._imagePaths.map((img) => Stack(
                        alignment: Alignment.topRight,
                      children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                              File(img),
                              width: 70,
                              height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _imagePaths.remove(img);
                              });
                            },
                              child: Container(
                              decoration: const BoxDecoration(
                                  color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                      ],
                      )),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: const Icon(Icons.add_a_photo, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 