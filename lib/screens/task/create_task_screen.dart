import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/tag.dart';
import '../../models/site.dart';
import '../../widgets/user_picker.dart';
import '../../widgets/tag_picker.dart';
import '../../widgets/add_tag_sheet.dart';
import 'package:path/path.dart' as p;
import '../../core/utils/image_picker_utils.dart';
import '../../core/utils/image_compression_utils.dart';

class CreateTaskScreen extends StatefulWidget {
  final int siteId;

  const CreateTaskScreen({Key? key, required this.siteId}) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _assignToController = TextEditingController();
  late final TextEditingController _siteIdController;

  final List<File> _taskImages = [];
  final List<File> _taskAttachments = [];
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
    _siteIdController = TextEditingController(text: widget.siteId.toString());
    _fetchTags();
    _fetchUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _tagsController.dispose();
    _assignToController.dispose();
    _siteIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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
          _taskImages.addAll(compressedImages);
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
        _taskAttachments.addAll(result.paths.whereType<String>().map((path) => File(path)));
      });
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

  void _submit() {
    if (_isLoading) return;
    _submitAsync();
  }

  Future<void> _submitAsync() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.user?.data.apiToken ?? '';
      final response = await ApiService().createTask(
        apiToken: apiToken,
        siteId: widget.siteId,
        name: _nameController.text.trim(),
        startDate: _startDateController.text.trim(),
        endDate: _endDateController.text.trim(),
        assignTo: _selectedUsers.map((u) => u.id).join(','),
        tags: _selectedTagId?.toString() ?? '',
        taskImages: _taskImages,
        taskAttachments: _taskAttachments,
      );
      SnackBarUtils.showSuccess(context, 'Task created successfully!');
      Navigator.of(context).pop(true);
    } catch (e) {
      SnackBarUtils.showError(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Create Task', style: AppTypography.titleLarge),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 10,
              ),
              CustomTextField(
                controller: _nameController,
                label: 'Task Name',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              spaceBetweenField(),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _startDateController,
                      label: 'Start Date',
                      readOnly: true,
                      onTap: () => _pickDate(_startDateController),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _endDateController,
                      label: 'End Date',
                      readOnly: true,
                      onTap: () => _pickDate(_endDateController),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              spaceBetweenField(),
              CustomTextField(
                controller: TextEditingController(
                  text: _selectedUsers.isEmpty
                      ? ''
                      : _selectedUsers.map((u) => u.name).join(', '),
                ),
                label: 'Assign To',
                readOnly: true,
                onTap: _isUserLoading ? null : _showUserPicker,
                suffixIcon: const Icon(Icons.arrow_drop_down),
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
              spaceBetweenField(),
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
              spaceBetweenField(),
              Text('Task Images ',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ..._taskImages.map((f) => Padding(
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
                                      _taskImages.remove(f);
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
              spaceBetweenField(),
              Text('Task Attachments ',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ..._taskAttachments.map((f) => Padding(
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
                                            ? p.basename(f.path).substring(0, 10) + '...'
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
                                      _taskAttachments.remove(f);
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
              const SizedBox(height: 32),
              CustomButton(
                text: _isLoading ? 'Creating...' : 'Create Task',
                isLoading: _isLoading,
                onPressed: _submit,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  spaceBetweenField() {
    return const SizedBox(
      height: 10,
    );
  }
}
 