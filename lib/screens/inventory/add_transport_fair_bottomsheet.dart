import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutanvij_electricals/screens/inventory/providers/transporter_fair_provider.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../../core/utils/transporter_validations_utils.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_button.dart';
import '../../../core/theme/app_typography.dart';

class AddTransporterFairBottomSheet extends StatefulWidget {
  final int transporterId;

  const AddTransporterFairBottomSheet({
    Key? key,
    required this.transporterId,
  }) : super(key: key);

  @override
  State<AddTransporterFairBottomSheet> createState() =>
      _AddTransporterFairBottomSheetState();
}

class _AddTransporterFairBottomSheetState
    extends State<AddTransporterFairBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fairController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _toLocationController = TextEditingController();
  final TextEditingController _fromLocationController =
  TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Consumer2<TransporterFairProvider, UserProvider>(
        builder: (context, provider, userProvider, child) {
          return Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  "Add Transporter Fair",
                  style:
                  AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Fair
                CustomTextField(
                  controller: _fairController,
                  label: "Fair (₹)",
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  validator: TansporterValidationUtils.validateFair,
                ),
                const SizedBox(height: 12),

                // Date
                GestureDetector(
                  onTap: () async {
                    FocusScope.of(context).unfocus(); // hide keyboard if open
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      _dateController.text =
                      "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                      setState(() {});
                    }
                  },
                  child: AbsorbPointer(
                    child: CustomTextField(
                      controller: _dateController,
                      label: "Date (YYYY-MM-DD)",
                      validator: (v) =>
                      v == null || v.isEmpty ? "Date is required" : null,
                    ),
                  ),
                ),

                /*// Date
                CustomTextField(
                  controller: _dateController,
                  label: "Date (YYYY-MM-DD)",
                  validator: (v) =>
                  v == null || v.isEmpty ? "Date is required" : null,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),*/

                const SizedBox(height: 12),

                // To Location
                CustomTextField(
                  controller: _toLocationController,
                  label: "To Location",
                  validator: (v) =>
                  v == null || v.isEmpty ? "To Location required" : null,
                ),
                const SizedBox(height: 12),

                // From Location
                CustomTextField(
                  controller: _fromLocationController,
                  label: "From Location",
                  validator: (v) =>
                  v == null || v.isEmpty ? "From Location required" : null,
                ),
                const SizedBox(height: 20),

                // Save Button
                CustomButton(
                  text: "Save",
                  isLoading: provider.loading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await provider.storeTransporterFair(
                        context: context,
                        userProvider: userProvider,
                        transporterId: widget.transporterId,
                        fair: _fairController.text.trim(),
                        date: _dateController.text.trim(),
                        toLocation: _toLocationController.text.trim(),
                        fromLocation: _fromLocationController.text.trim(),
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _fairController.dispose();
    _dateController.dispose();
    _toLocationController.dispose();
    _fromLocationController.dispose();
    super.dispose();
  }
}
