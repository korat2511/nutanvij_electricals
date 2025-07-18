import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/utils/image_compression_utils.dart';
import '../../core/utils/image_picker_utils.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/task.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class UpdateTaskProgressScreen extends StatefulWidget {
  final Task task;

  const UpdateTaskProgressScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<UpdateTaskProgressScreen> createState() => _UpdateTaskProgressScreenState();
}

class _UpdateTaskProgressScreenState extends State<UpdateTaskProgressScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _workDoneController = TextEditingController();
  final TextEditingController _workLeftController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  
  final List<File> _progressImages = [];
  final List<File> _progressAttachments = [];
  
  bool _isLoading = false;
  final String _selectedUnit = '%';
  double _currentProgress = 0.0;
  double _totalWorkDone = 0.0;
  double _totalWork = 100.0;

  @override
  void initState() {
    super.initState();
    _initializeProgress();
  }

  void _initializeProgress() {
    // Get current progress from task
    _currentProgress = widget.task.progress?.toDouble() ?? 0.0;
    _totalWorkDone = widget.task.totalWorkDone?.toDouble() ?? 0.0;
    _totalWork = widget.task.totalWork?.toDouble() ?? 100.0;
    
    // Set initial work left
    _workLeftController.text = (_totalWork - _totalWorkDone).toString();
  }

  @override
  void dispose() {
    _workDoneController.dispose();
    _workLeftController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  bool _isUpdatingWorkDone = false;
  bool _isUpdatingWorkLeft = false;

  void _onWorkDoneChanged(String value) {
    if (_isUpdatingWorkLeft) return; // Prevent infinite loop
    
    _isUpdatingWorkDone = true;
    if (value.isEmpty) {
      // If work done is cleared, set work left to total remaining work
      _workLeftController.text = (_totalWork - _totalWorkDone).toStringAsFixed(1);
    } else {
      final workDone = double.tryParse(value) ?? 0.0;
      final maxWorkDone = _totalWork - _totalWorkDone; // Maximum work that can be done
      
      // If user enters more than what's left, cap it at the maximum
      if (workDone > maxWorkDone) {
        _workDoneController.text = maxWorkDone.toStringAsFixed(1);
        _workLeftController.text = '0.0';
      } else {
        final workLeft = _totalWork - _totalWorkDone - workDone;
        _workLeftController.text = workLeft.toStringAsFixed(1);
      }
    }
    _isUpdatingWorkDone = false;
  }

  void _onWorkLeftChanged(String value) {
    if (_isUpdatingWorkDone) return; // Prevent infinite loop
    
    _isUpdatingWorkLeft = true;
    if (value.isEmpty) {
      // If work left is cleared, set work done to 0
      _workDoneController.text = '0';
    } else {
      final workLeft = double.tryParse(value) ?? 0.0;
      final workDone = _totalWork - _totalWorkDone - workLeft;
      _workDoneController.text = workDone.toStringAsFixed(1);
    }
    _isUpdatingWorkLeft = false;
  }

  Future<void> _pickImages() async {
    final paths = await ImagePickerUtils.pickMultipleImages(context: context);
    if (paths.isNotEmpty) {
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
        final imageFiles = paths.map((p) => File(p)).toList();
        final compressedImages = await ImageCompressionUtils.compressImages(imageFiles);
        
        setState(() {
          _progressImages.addAll(compressedImages);
        });
      } finally {
        // Hide loading indicator
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _progressAttachments.addAll(result.paths.whereType<String>().map((path) => File(path)));
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final workDone = double.tryParse(_workDoneController.text) ?? 0.0;
    final workLeft = double.tryParse(_workLeftController.text) ?? 0.0;
    
    // Validate that work done + work left + previous work done = total work
    final expectedWorkLeft = _totalWork - _totalWorkDone - workDone;
    if ((workLeft - expectedWorkLeft).abs() > 0.1) {
      SnackBarUtils.showError(context, 'Work done and work left values are inconsistent. Please check your calculations.');
      return;
    }
    
    // Ensure at least one value is provided
    if (workDone == 0.0 && workLeft == (_totalWork - _totalWorkDone)) {
      SnackBarUtils.showError(context, 'Please enter work done or work left to update progress.');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.user?.data.apiToken ?? '';
      
      await ApiService().updateTaskProgress(
        apiToken: apiToken,
        taskId: widget.task.id,
        workDone: _workDoneController.text.trim(),
        workLeft: _workLeftController.text.trim(),
        unit: _selectedUnit,
        remark: _remarkController.text.trim().isEmpty ? null : _remarkController.text.trim(),
        images: _progressImages.isEmpty ? null : _progressImages,
        attachments: _progressAttachments.isEmpty ? null : _progressAttachments,
      );
      
      SnackBarUtils.showSuccess(context, 'Task progress updated successfully!');
      Navigator.of(context).pop(true);
    } catch (e) {
      SnackBarUtils.showError(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: CustomAppBar(
        title: 'Update Progress',
        onMenuPressed: () => Navigator.of(context).pop(),
        showProfilePicture: false,
        showNotification: false,
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                      widget.task.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildProgressInfo('Current Progress', '${_currentProgress.toStringAsFixed(1)}%'),
                        ),
                        Expanded(
                          child: _buildProgressInfo('Total Work Done', '${_totalWorkDone.toStringAsFixed(1)} $_selectedUnit'),
                        ),
                        Expanded(
                          child: _buildProgressInfo('Total Work', '${_totalWork.toStringAsFixed(1)} $_selectedUnit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Progress Update Form
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                      'Progress Update',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                                         // Work Done
                     CustomTextField(
                       controller: _workDoneController,
                       label: 'Work Done Today',
                       keyboardType: TextInputType.number,
                       onChanged: _onWorkDoneChanged,
                       validator: (value) {
                         if (value == null || value.isEmpty) {
                           return 'Required';
                         }
                         final workDone = double.tryParse(value);
                         if (workDone == null || workDone < 0) {
                           return 'Must be a positive number';
                         }
                         final maxWorkDone = _totalWork - _totalWorkDone;
                         if (workDone > maxWorkDone) {
                           return 'Cannot exceed remaining work ($maxWorkDone)';
                         }
                         return null;
                       },
                     ),

                    
                    const SizedBox(height: 12),
                    
                                         // Work Left
                     CustomTextField(
                       controller: _workLeftController,
                       label: 'Work Left',
                       keyboardType: TextInputType.number,
                       onChanged: _onWorkLeftChanged,
                       validator: (value) {
                         if (value == null || value.isEmpty) {
                           return 'Required';
                         }
                         final workLeft = double.tryParse(value);
                         if (workLeft == null || workLeft < 0) {
                           return 'Must be a positive number';
                         }
                         if (workLeft > (_totalWork - _totalWorkDone)) {
                           return 'Cannot exceed remaining work';
                         }
                         return null;
                       },
                     ),
                    
                    const SizedBox(height: 12),
                    
                    // Remark (Optional)
                    CustomTextField(
                      controller: _remarkController,
                      label: 'Remark (Optional)',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Images Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                      'Progress Images (Optional)',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (_progressImages.isNotEmpty) ...[
                      GridView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: _progressImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _progressImages[index],
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _progressImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: double.infinity,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary, width: 1.5, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.primary.withOpacity(0.05),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: AppColors.primary, size: 24),
                              SizedBox(height: 4),
                              Text('Add Images', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Attachments Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                      'Attachments (Optional)',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (_progressAttachments.isNotEmpty) ...[
                      ..._progressAttachments.map((file) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              _getFileIcon(file.path),
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.basename(file.path),
                                style: AppTypography.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _progressAttachments.remove(file);
                                });
                              },
                              child: const Icon(Icons.close, color: Colors.red, size: 20),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 12),
                    ],
                    
                    GestureDetector(
                      onTap: _pickAttachments,
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary, width: 1.5, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.primary.withOpacity(0.05),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.attach_file, color: AppColors.primary, size: 24),
                              SizedBox(height: 4),
                              Text('Add Attachments', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              CustomButton(
                text: _isLoading ? 'Updating...' : 'Update Progress',
                isLoading: _isLoading,
                onPressed: _submit,
                width: double.infinity,
              ),
              
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildProgressInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return Icons.image;
    } else if (['.pdf'].contains(ext)) {
      return Icons.picture_as_pdf;
    } else if (['.doc', '.docx'].contains(ext)) {
      return Icons.description;
    } else if (['.xls', '.xlsx'].contains(ext)) {
      return Icons.table_chart;
    } else if (['.mp4', '.avi', '.mov', '.wmv'].contains(ext)) {
      return Icons.videocam;
    } else if (['.mp3', '.wav', '.aac'].contains(ext)) {
      return Icons.audiotrack;
    } else {
      return Icons.attach_file;
    }
  }
} 