import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutanvij_electricals/core/utils/navigation_utils.dart';
import 'package:nutanvij_electricals/screens/task/edit_task_screen.dart';
import 'package:nutanvij_electricals/screens/task/update_task_progress_screen.dart';
import 'package:nutanvij_electricals/widgets/custom_button.dart';
import '../../models/task.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/custom_app_bar.dart';

import '../viewer/full_screen_image_viewer.dart';
import '../viewer/full_screen_pdf_viewer.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Task task;

  const TaskDetailsScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen>
    with SingleTickerProviderStateMixin {
  late Task _task;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _task = widget.task;
    _loadTaskDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTaskDetails() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final apiToken = userProvider.user?.data.apiToken ?? '';
    try {
      final updatedTask = await ApiService().getTaskDetail(
        context: context,
        apiToken: apiToken,
        taskId: _task.id,
      );
      setState(() {
        _task = updatedTask;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading task details: $e');
      // Keep the original task data if API call fails
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshTask() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final apiToken = userProvider.user?.data.apiToken ?? '';
    try {
      final updatedTask = await ApiService().getTaskDetail(
        context: context,
        apiToken: apiToken,
        taskId: _task.id,
      );
      setState(() {
        _task = updatedTask;
      });
    } catch (e) {
      // If getTaskDetail fails, fallback to getTaskList
      final updatedTasks = await ApiService().getTaskList(
        context: context,
        apiToken: apiToken,
        siteId: _task.siteId,
      );
      final updated =
          updatedTasks.firstWhere((t) => t.id == _task.id, orElse: () => _task);
      setState(() {
        _task = updated;
      });
    }
  }

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
    final task = _task;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: CustomAppBar(
        title: task.name,
        onMenuPressed: () => Navigator.of(context).pop(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final shouldRefresh = await NavigationUtils.push(context,
                        EditTaskScreen(task: task, siteId: widget.task.siteId));
                    if (shouldRefresh == true) {
                      await _refreshTask();
                    }
                  },
                  child: const Icon(Icons.edit,
                      color: AppColors.primary, size: 22),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : Column(
              children: [
                // Tab Bar
                Container(
                  margin: const EdgeInsets.all(12.0),
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
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.white,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.black54,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelStyle: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: 'Task Details'),
                      Tab(text: 'Progress'),
                    ],
                  ),
                ),

                // Tab Bar View
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Task Details Tab
                      RefreshIndicator(
                        onRefresh: _refreshTask,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Task Details Card
                              _buildDetailsCard(task),
                              const SizedBox(height: 8),

                              // Assigned Users Card
                              _buildUsersCard(task),

                              const SizedBox(height: 8),

                              // Images Card
                              if (task.taskImages.isNotEmpty) ...[
                                _buildImagesCard(task),
                                const SizedBox(height: 8),
                              ],

                              // Attachments Card
                              if (task.taskAttachments.isNotEmpty) ...[
                                _buildAttachmentsCard(task),
                                const SizedBox(height: 8),
                              ],

                              // Task Completion Button or Update Progress Button
                              if (task.progress == 100 && task.completedAt != null)
                                Container(
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Task Completed on ${_formatDate(task.completedAt!)}',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                )
                              else
                                CustomButton(
                                  text: "Update Progress",
                                  onPressed: () async {
                                    final shouldRefresh = await NavigationUtils.push(
                                      context,
                                      UpdateTaskProgressScreen(task: task),
                                    );
                                    if (shouldRefresh == true) {
                                      await _refreshTask();
                                    }
                                  },
                                ),
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).padding.bottom +
                                          20),
                            ],
                          ),
                        ),
                      ),

                      // Progress Tab
                      RefreshIndicator(
                        onRefresh: _refreshTask,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Progress Timeline
                              _buildProgressTimeline(task),
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).padding.bottom +
                                          20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressTimeline(Task task) {
    final progress = task.progress ?? 0;
    final totalWorkDone = task.totalWorkDone ?? 0;
    final totalWork = task.totalWork ?? 100;
    final unit = task.unit ?? '%';

    print('Task Progress Count: ${task.taskProgress.length}');
    print(
        'Task Progress Data: ${task.taskProgress.map((p) => 'ID: ${p.id}, WorkDone: ${p.workDone}, CreatedAt: ${p.createdAt}').toList()}');

    final sortedProgress = List<TaskProgress>.from(task.taskProgress)
      ..sort((a, b) =>
          DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));

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
          Row(
            children: [
              const Icon(Icons.timeline, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Progress Timeline',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '$progress%',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            borderRadius: BorderRadius.circular(8),
            minHeight: 8,
          ),
          const SizedBox(height: 16),

          // Task Progress Timeline
          if (sortedProgress.isNotEmpty) ...[
            Text(
              'Progress Updates (${sortedProgress.length})',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...sortedProgress
                .map((progressItem) => _buildProgressTimelineItem(progressItem))
                .toList(),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.timeline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No Progress Updates Yet',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Progress updates will appear here when team members update the task',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Task Dates
          Row(
            children: [
              Expanded(
                child: _buildTimelineItem(
                  icon: Icons.play_arrow,
                  title: 'Started',
                  subtitle: task.startDate,
                  isCompleted: true,
                ),
              ),
              Expanded(
                child: _buildTimelineItem(
                  icon: Icons.flag,
                  title: 'Target',
                  subtitle: task.endDate,
                  isCompleted: progress >= 100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildProgressTimelineItem(TaskProgress progress) {
    final utcDate = DateTime.parse(progress.createdAt);
    // Convert UTC to IST by adding 5:30 hours
    final istDate = utcDate.add(const Duration(hours: 5, minutes: 30));
    final formattedDate = '${istDate.day}/${istDate.month}/${istDate.year}';
    final formattedTime =
        '${istDate.hour.toString().padLeft(2, '0')}:${istDate.minute.toString().padLeft(2, '0')}';

    print(
        'Progress Item - ID: ${progress.id}, WorkDone: ${progress.workDone}, Images: ${progress.taskProgressImage.length}, Attachments: ${progress.taskAttachment.length}');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot and line
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: 2,
                height: 60,
                color: Colors.grey.shade300,
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Progress content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with date and work info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              formattedTime,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${progress.workDone} %',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Work details
                  Row(
                    children: [
                      Expanded(
                        child: _buildWorkDetail(
                            'Work Done', progress.workDone, progress.unit),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildWorkDetail(
                            'Work Left', progress.workLeft, progress.unit),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Remark
                  if (progress.remark.isNotEmpty) ...[
                    Text(
                      'Remark:',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress.remark,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                  ],

                  // Progress Images
                  if (progress.taskProgressImage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Progress Images:',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: progress.taskProgressImage.length,
                        itemBuilder: (context, index) {
                          final image = progress.taskProgressImage[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FullScreenImageViewer(
                                    images: progress.taskProgressImage
                                        .map((e) => e.imageUrl)
                                        .toList(),
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  image.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.grey, size: 20),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Progress Attachments
                  if (progress.taskAttachment.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Attachments:',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: progress.taskAttachment.map((attachment) {
                        final fileName = attachment.file.split('/').last;
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FullScreenPdfViewer(
                                  url: attachment.fileUrl,
                                  fileName: fileName,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getAttachmentIcon(fileName),
                                  size: 16,
                                  color: _getAttachmentIconColor(fileName),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  fileName.length > 15
                                      ? '${fileName.substring(0, 15)}...'
                                      : fileName,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkDetail(String label, String value, String? unit) {
    return Column(
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
          '$value ${unit ?? ''}',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.primary : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: isCompleted ? Colors.white : Colors.grey.shade600,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: isCompleted ? Colors.black54 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(Task task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
          _buildDetailRow('Start Date', task.startDate),
          _buildDetailRow('End Date', task.endDate),
          _buildDetailRow('Created By', task.createdBy.toString()),
          _buildDetailRow('Tags', task.tags.isEmpty ? "No tags" : "Tags"),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersCard(Task task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(right: 15, left: 15, top: 10),
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
          Row(
            children: [
              const Icon(Icons.people, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                'Assigned Users',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (task.assignUser.isEmpty)
            Text(
              'No users assigned',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...task.assignUser
                .map((user) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withOpacity(0.15),
                            radius: 20,
                            child: Text(
                              _getInitials(user.name),
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              user.name,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
        ],
      ),
    );
  }



  Widget _buildImagesCard(Task task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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

          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: task.taskImages.length,
            itemBuilder: (context, idx) {
              final img = task.taskImages[idx];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(
                        images: task.taskImages.map((e) => e.imageUrl).toList(),
                        initialIndex: idx,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    img.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey, size: 16),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard(Task task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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

          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1,
              // crossAxisCount: 3,
              // crossAxisSpacing: 8,
              // mainAxisSpacing: 8,
              // childAspectRatio: 0.8,
            ),
            itemCount: task.taskAttachments.length,
            itemBuilder: (context, idx) {
              final att = task.taskAttachments[idx];
              final fileName = att.file.split('/').last;
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FullScreenPdfViewer(
                        url: att.file,
                        fileName: fileName,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getAttachmentIcon(fileName),
                        color: _getAttachmentIconColor(fileName),
                        size: 32,
                      ),
                      // const SizedBox(height: 8),
                      // Text(
                      //   fileName.length > 15
                      //       ? '${fileName.substring(0, 15)}...'
                      //       : fileName,
                      //   style: AppTypography.bodySmall.copyWith(
                      //     color: Colors.black87,
                      //     fontWeight: FontWeight.w500,
                      //   ),
                      //   textAlign: TextAlign.center,
                      //   maxLines: 2,
                      //   overflow: TextOverflow.ellipsis,
                      // ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  IconData _getAttachmentIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
      return Icons.image;
    } else if (['pdf'].contains(ext)) {
      return Icons.picture_as_pdf;
    } else if (['doc', 'docx'].contains(ext)) {
      return Icons.description;
    } else if (['xls', 'xlsx'].contains(ext)) {
      return Icons.table_chart;
    } else if (['mp4', 'avi', 'mov', 'wmv'].contains(ext)) {
      return Icons.videocam;
    } else if (['mp3', 'wav', 'aac'].contains(ext)) {
      return Icons.audiotrack;
    } else {
      return Icons.attach_file;
    }
  }

  Color _getAttachmentIconColor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['pdf'].contains(ext)) return Colors.red;
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext))
      return Colors.orange;
    if (['doc', 'docx'].contains(ext)) return Colors.blue;
    if (['xls', 'xlsx'].contains(ext)) return Colors.green;
    if (['mp4', 'avi', 'mov', 'wmv'].contains(ext)) return Colors.purple;
    if (['mp3', 'wav', 'aac'].contains(ext)) return Colors.teal;
    return AppColors.primary;
  }

  String _formatDate(String dateString) {
    try {
      print('Original date string: $dateString');
      
      // Parse the UTC date
      final utcDate = DateTime.parse(dateString);
      print('Parsed UTC date: $utcDate');
      
      // Force convert to IST by adding 5 hours 30 minutes
      final istDate = utcDate.add(const Duration(hours: 5, minutes: 30));
      print('Converted to IST: $istDate');
      
      // Format as DD/MM/YYYY
      final formattedDate = '${istDate.day.toString().padLeft(2, '0')}/${istDate.month.toString().padLeft(2, '0')}/${istDate.year}';
      print('Final formatted date: $formattedDate');
      
      return formattedDate;
    } catch (e) {
      print('Error parsing date: $e');
      return dateString;
    }
  }
}
 