import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'custom_text_field.dart';
import '../core/utils/transporter_validations_utils.dart';

class AddContractorSheet extends StatefulWidget {
  final Future<void> Function(String, String, String) onAdd;
  const AddContractorSheet({Key? key, required this.onAdd}) : super(key: key);

  @override
  State<AddContractorSheet> createState() => _AddContractorSheetState();
}

class _AddContractorSheetState extends State<AddContractorSheet> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    'Add new contractor',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// Contractor Name
            CustomTextField(
              controller: _nameController,
              label: 'Enter contractor name',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            /// Email
            CustomTextField(
              controller: _emailController,
              label: 'Enter email',
              validator: TansporterValidationUtils.validateEmail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            /// Phone Number
            CustomTextField(
              controller: _phoneController,
              label: 'Enter phone number',
              validator: TansporterValidationUtils.validatePhone,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
                signed: false,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 24),

            /// Add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading
                    ? null
                    : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);

                    await widget.onAdd(_nameController.text.trim(),
                        _emailController.text.trim(),
                        _phoneController.text.trim());

                    setState(() => _isLoading = false);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
