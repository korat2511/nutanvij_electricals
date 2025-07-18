import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../models/tag.dart';
import '../../models/site.dart';
import '../../services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/utils/navigation_utils.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'task_details_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_search_field.dart';
import '../../core/utils/task_validation_utils.dart';
import 'create_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key, required this.siteId}) : super(key: key);
  final int siteId;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _isLoading = true;
  String? _error;
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Filter variables
  final String _searchQuery = '';
  String _selectedStatus = '';
  final List<int> _selectedUserIds = [];
  final List<int> _selectedTagIds = [];
  bool _isFilterApplied = false;
  
  // Cached data to avoid repeated API calls
  List<UserInSite> _cachedUsers = [];
  List<Tag> _cachedTags = [];
  bool _hasLoadedUsers = false;
  bool _hasLoadedTags = false;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _loadUsersAndTags();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTasks = _tasks;
      } else {
        _filteredTasks = _tasks.where((task) {
          return task.name.toLowerCase().contains(query) ||
                 task.status.toLowerCase().contains(query) ||
                 task.assignUser.any((user) => user.name.toLowerCase().contains(query)) ||
                 task.tags.any((tag) => tag.name.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      print('Fetching tasks with filters: search=$_searchQuery, status=$_selectedStatus, userId=$_selectedUserIds, tags=$_selectedTagIds');
      final tasks = await ApiService().getTaskList(
        context: context,
        apiToken: userProvider.user?.data.apiToken ?? '',
        siteId: widget.siteId,
        search: _searchQuery,
        status: _selectedStatus,
        userId: _selectedUserIds.isNotEmpty ? _selectedUserIds.first : null,
        tags: _selectedTagIds.isNotEmpty ? _selectedTagIds.join(',') : null,
      );
      setState(() {
        _tasks = tasks;
        _filteredTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching tasks: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      SnackBarUtils.showError(context, e.toString());
    }
  }


  Widget _buildFilterChip({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Status', style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('All Status', style: AppTypography.bodyMedium),
              value: '',
              groupValue: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value ?? '';
                  _isFilterApplied = _selectedStatus.isNotEmpty || _selectedUserIds.isNotEmpty || _selectedTagIds.isNotEmpty;
                });
                _fetchTasks();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Pending', style: AppTypography.bodyMedium),
              value: 'pending',
              groupValue: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value ?? '';
                  _isFilterApplied = _selectedStatus.isNotEmpty || _selectedUserIds.isNotEmpty || _selectedTagIds.isNotEmpty;
                });
                _fetchTasks();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Active', style: AppTypography.bodyMedium),
              value: 'active',
              groupValue: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value ?? '';
                  _isFilterApplied = _selectedStatus.isNotEmpty || _selectedUserIds.isNotEmpty || _selectedTagIds.isNotEmpty;
                });
                _fetchTasks();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Completed', style: AppTypography.bodyMedium),
              value: 'completed',
              groupValue: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value ?? '';
                  _isFilterApplied = _selectedStatus.isNotEmpty || _selectedUserIds.isNotEmpty || _selectedTagIds.isNotEmpty;
                });
                _fetchTasks();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUsersDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Select Users', style: AppTypography.titleMedium),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _cachedUsers.map((user) {
                    final isSelected = _selectedUserIds.contains(user.id);
                    return CheckboxListTile(
                      title: Text(user.name, style: AppTypography.bodyMedium),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedUserIds.add(user.id);
                          } else {
                            _selectedUserIds.remove(user.id);
                          }
                          _isFilterApplied = _selectedStatus.isNotEmpty || _selectedUserIds.isNotEmpty || _selectedTagIds.isNotEmpty;
                        });
                        setState(() {});
                        _fetchTasks();
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Select', style: AppTypography.bodyMedium),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTagsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Select Tags', style: AppTypography.titleMedium),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _cachedTags.map((tag) {
                    final isSelected = _selectedTagIds.contains(tag.id);
                    return CheckboxListTile(
                      title: Text(tag.name, style: AppTypography.bodyMedium),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedTagIds.add(tag.id);
                          } else {
                            _selectedTagIds.remove(tag.id);
                          }
                          _isFilterApplied = _selectedStatus.isNotEmpty || _selectedUserIds.isNotEmpty || _selectedTagIds.isNotEmpty;
                        });
                        setState(() {});
                        _fetchTasks();
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Select', style: AppTypography.bodyMedium),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadUsersAndTags() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.user?.data.apiToken ?? '';
      
      // Load users and tags in parallel
      final futures = await Future.wait([
        ApiService().getUserBySite(
          context: context,
          apiToken: apiToken,
          siteId: widget.siteId,
        ),
        ApiService().getTags(apiToken: apiToken),
      ]);
      
      setState(() {
        _cachedUsers = (futures[0] as dynamic).users;
        _cachedTags = futures[1] as List<Tag>;
        _hasLoadedUsers = true;
        _hasLoadedTags = true;
      });
    } catch (e) {
      // Handle error silently
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: CustomAppBar(
        title: 'Tasks',
        onMenuPressed: () => Navigator.of(context).pop(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomSearchField(
              controller: _searchController,
              hintText: 'Search tasks by name, status, users, or tags...',
              onChanged: (value) {
                // Search is handled by the listener
              },
              onClear: () {
                setState(() {
                  _filteredTasks = _tasks;
                });
              },
            ),
          ),
          // Filter Chips

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(

              spacing: 8,
              runSpacing: 4,
                children: [
                  _buildFilterChip(
                    label: _selectedStatus.isNotEmpty ? 'Status: $_selectedStatus' : 'Status',
                    onTap: () => _showStatusDialog(),
                  ),
                  _buildFilterChip(
                    label: _selectedUserIds.isNotEmpty ? '${_selectedUserIds.length} Users' : 'Users',
                    onTap: () => _showUsersDialog(),
                  ),
                  _buildFilterChip(
                    label: _selectedTagIds.isNotEmpty ? '${_selectedTagIds.length} Tags' : 'Tags',
                    onTap: () => _showTagsDialog(),
                  ),
                ],
              ),
            ),
          // Tasks List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchTasks,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: AppTypography.bodyMedium.copyWith(color: AppColors.error)))
                      : _filteredTasks.isEmpty
                          ? Center(child: Text(_tasks.isEmpty ? 'No tasks found.' : 'No tasks match your search.', style: AppTypography.bodyMedium))
                          : ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              children: [
                                ..._filteredTasks.map((task) => _TaskCard(
                                      task: task,
                                      onTap: () => NavigationUtils.push(context, TaskDetailsScreen(task: task)),
                                    )),
                              ],
                            ),
            ),
          ),
        ],
      ),

      floatingActionButton: TaskValidationUtils.canCreateTask(context)
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Create Task'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () async {
                final shouldRefresh = await NavigationUtils.push(context, CreateTaskScreen(siteId: widget.siteId));
                if (shouldRefresh == true) {
                  _fetchTasks();
                }
              },
            )
          : null,
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  const _TaskCard({required this.task, required this.onTap});

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: getStatusColor(task.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: getStatusColor(task.status).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      task.status.toUpperCase(),
                      style: AppTypography.bodySmall.copyWith(
                        color: getStatusColor(task.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Progress section
              Row(
                children: [
                  const Icon(Icons.trending_up, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Progress',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${task.progress ?? 0}%',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (task.progress ?? 0) / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
              const SizedBox(height: 12),
              
              // Dates section
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      label: 'Start Date',
                      value: task.startDate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoItem(
                      label: 'End Date',
                      value: task.endDate,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Users and tags
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      label: 'Assigned Users',
                      value: _buildUserSummary(task),
                      isWidget: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoItem(
                      label: 'Tags',
                      value: task.tags.isNotEmpty ? task.tags.map((t) => t.name).join(', ') : 'No tags',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    String? label,
    required dynamic value,
    bool isWidget = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.black54,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
        ],
        isWidget
            ? value as Widget
            : Text(
                value.toString(),
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ],
    );
  }

  Widget _buildUserSummary(Task task) {
    if (task.assignUser.isEmpty) {
      return Text(
        'No users',
        style: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
        ),
      );
    }
    
    if (task.assignUser.length == 1) {
      return Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _getInitials(task.assignUser.first.name),
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _getInitials(task.assignUser.first.name),
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      );
    }
    
    return Row(
      children: [
        // Show first user avatar
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              _getInitials(task.assignUser.first.name),
              style: AppTypography.bodySmall.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _getInitials(task.assignUser.first.name),
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '+${task.assignUser.length - 1}',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
} 