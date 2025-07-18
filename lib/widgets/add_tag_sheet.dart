import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class AddTagSheet extends StatefulWidget {
  final Future<void> Function(String) onAdd;
  const AddTagSheet({Key? key, required this.onAdd}) : super(key: key);

  @override
  State<AddTagSheet> createState() => _AddTagSheetState();
}

class _AddTagSheetState extends State<AddTagSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
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
                  'Add new tag',
                  style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w500),
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
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Enter tag name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading
                  ? null
                  : () async {
                      final name = _controller.text.trim();
                      if (name.isNotEmpty) {
                        setState(() => _isLoading = true);
                        await widget.onAdd(name);
                        setState(() => _isLoading = false);
                        Navigator.of(context).pop();
                      }
                    },
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
} 