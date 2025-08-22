import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/image_picker_utils.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/tag.dart';
import '../../models/site.dart';
import '../../models/task.dart';
import '../../widgets/user_picker.dart';
import '../../widgets/tag_picker.dart';
import '../../widgets/add_tag_sheet.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class EditTaskScreen extends StatefulWidget {
  final Task task;
  final int siteId;
  const EditTaskScreen({Key? key, required this.task, required this.siteId}) : super(key: key);

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _siteIdController;

  final List<File> _newTaskImages = [];
  final List<File> _newTaskAttachments = [];
  late List<TaskImage> _existingImages;
  late List<TaskAttachment> _existingAttachments;
  bool _isLoading = false;
  List<Tag> _allTags = [];
  int? _selectedTagId;
  bool _isTagLoading = false;
  String? _tagError;
  List<UserInSite> _allUsers = [];
  List<UserInSite> _selectedUsers = [];
  bool _isUserLoading = false;
  String? _userError;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _nameController = TextEditingController(text: t.name);
    _startDateController = TextEditingController(text: t.startDate);
    _endDateController = TextEditingController(text: t.endDate);
    _siteIdController = TextEditingController(text: widget.siteId.toString());
    _existingImages = List.from(t.taskImages);
    _existingAttachments = List.from(t.taskAttachments);
    _selectedTagId = t.tags.isNotEmpty ? t.tags.first.id : null;
    _selectedUsers = t.assignUser.map((u) => UserInSite(id: u.id, name: u.name)).toList();
    _fetchTags();
    _fetchUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _siteIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final paths = await ImagePickerUtils.pickMultipleImages(context: context);
    setState(() {
      _newTaskImages.addAll(paths.map((p) => File(p)));
    });
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _newTaskAttachments.addAll(result.paths.whereType<String>().map((path) => File(path)));
      });
    }
  }



  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _fetchTags() async {
    setState(() {
      _isTagLoading = true;
      _tagError = null;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.user?.data.apiToken ?? '';
      final tags = await ApiService().getTags(apiToken: apiToken);
      setState(() {
        _allTags = tags;
        _isTagLoading = false;
      });
    } catch (e) {
      setState(() {
        _tagError = e.toString();
        _isTagLoading = false;
      });
    }
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isUserLoading = true;
      _userError = null;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.user?.data.apiToken ?? '';
      final site = await ApiService().getUserBySite(
        context: context,
        apiToken: apiToken,
        siteId: widget.siteId,
      );
      setState(() {
        _allUsers = site.users;
        _isUserLoading = false;
      });
    } catch (e) {
      setState(() {
        _userError = e.toString();
        _isUserLoading = false;
      });
    }
  }

  Future<void> _addTag(String name) async {
    setState(() => _isTagLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.user?.data.apiToken ?? '';
      final tag = await ApiService().addTag(apiToken: apiToken, name: name);
      await _fetchTags(); // Refresh the tag list after adding
      setState(() {
        _selectedTagId = tag.id;
        _isTagLoading = false;
      });
    } catch (e) {
      setState(() {
        _tagError = e.toString();
        _isTagLoading = false;
      });
    }
  }

  void _submit() {
    if (_isLoading) return;
    _submitAsync();
  }

  Future<void> _submitAsync() async {
    // No validation, allow empty fields
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.user?.data.apiToken ?? '';


      log("_selectedUsers == $_selectedUsers");

      final response = await ApiService().editTask(
        apiToken: apiToken,
        siteId: widget.siteId,
        taskId: widget.task.id,
        name: _nameController.text.trim(),
        startDate: _startDateController.text.trim(),
        endDate: _endDateController.text.trim(),
        assignTo: _selectedUsers.map((u) => u.id).join(','),
        tags: _selectedTagId?.toString() ?? '',
        taskImages: _newTaskImages,
        taskAttachments: _newTaskAttachments,
      );


      
      SnackBarUtils.showSuccess(context, 'Task updated successfully!');
      Navigator.of(context).pop(true);
    } catch (e) {
      SnackBarUtils.showError(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showUserPicker() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return UserPicker(
          allUsers: _allUsers,
          selectedUsers: _selectedUsers,
          onChanged: (users) => setState(() => _selectedUsers = users),
        );
      },
    );
  }

  void _showTagPicker() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return TagPicker(
          allTags: _allTags,
          selectedTagId: _selectedTagId,
          onChanged: (tag) => setState(() => _selectedTagId = tag.id),
          onAddTag: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              backgroundColor: Colors.white,
              builder: (context) {
                return AddTagSheet(
                  onAdd: (name) async {
                    await _addTag(name);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Edit Task',
        onMenuPressed: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      label: 'Task Name',
                      // validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _startDateController,
                            label: 'Start Date',
                            readOnly: true,
                            onTap: () => _pickDate(_startDateController),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _endDateController,
                            label: 'End Date',
                            readOnly: true,
                            onTap: () => _pickDate(_endDateController),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _isUserLoading ? null : _showUserPicker,
                      child: AbsorbPointer(
                        child: CustomTextField(
                          controller: TextEditingController(
                            text: _selectedUsers.isEmpty
                                ? ''
                                : _selectedUsers.map((u) => u.name).join(', '),
                          ),
                          label: 'Assign To',
                          readOnly: true,
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                        ),
                      ),
                    ),
                    if (_isUserLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (_userError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_userError!,
                            style:
                                AppTypography.bodySmall.copyWith(color: Colors.red)),
                      ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _isTagLoading ? null : _showTagPicker,
                      child: AbsorbPointer(
                        child: CustomTextField(
                          controller: TextEditingController(
                            text: _allTags
                                .firstWhere((t) => t.id == _selectedTagId,
                                    orElse: () => Tag(
                                        id: 0,
                                        name: '',
                                        deletedAt: null,
                                        createdAt: '',
                                        updatedAt: ''))
                                .name,
                          ),
                          label: 'Select tag',
                          readOnly: true,
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                        ),
                      ),
                    ),
                    if (_isTagLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (_tagError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_tagError!,
                            style:
                                AppTypography.bodySmall.copyWith(color: Colors.red)),
                      ),
                    const SizedBox(height: 18),
                    // Existing Images
                    if (_existingImages.isNotEmpty) ...[
                      Text('Existing Images:',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _existingImages.map((img) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                img.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () {
                                  // TODO: Remove image API
                                  setState(() => _existingImages.remove(img));
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        )).toList(),
                      ),
                    ],
                    // Always show Add New Images title and row
                    const SizedBox(height: 12),
                    Text('Add New Images:',
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          ..._newTaskImages.map((f) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    f,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _newTaskImages.remove(f);
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.close, size: 18, color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                border:
                                Border.all(color: AppColors.primary, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.primary.withOpacity(0.07),
                              ),
                              child: const Center(
                                child: Icon(Icons.add_a_photo,
                                    color: AppColors.primary, size: 32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Existing Attachments
                    if (_existingAttachments.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text('Existing Attachments:',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _existingAttachments.map((att) => Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.insert_drive_file, color: AppColors.primary, size: 36),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () {
                                  // TODO: Remove attachment API
                                  setState(() => _existingAttachments.remove(att));
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        )).toList(),
                      ),
                    ],
                    // Always show Add New Attachments title and row
                    const SizedBox(height: 12),
                    Text('Add New Attachments:',
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          ..._newTaskAttachments.map((f) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AppColors.primary, width: 1.5),
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppColors.primary.withOpacity(0.07),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.insert_drive_file,
                                            color: AppColors.primary, size: 28),
                                        const SizedBox(height: 4),
                                        Text(
                                          p.basename(f.path).length > 10
                                              ? '${p.basename(f.path).substring(0, 10)}...'
                                              : p.basename(f.path),
                                          style: AppTypography.bodySmall,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _newTaskAttachments.remove(f);
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 18, color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          GestureDetector(
                            onTap: _pickAttachments,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                border:
                                Border.all(color: AppColors.primary, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.primary.withOpacity(0.07),
                              ),
                              child: const Center(
                                child: Icon(Icons.attach_file,
                                    color: AppColors.primary, size: 32),
                              ),
                            ),
                          ),
                        ],
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
                        onPressed: _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Update Task'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
} 