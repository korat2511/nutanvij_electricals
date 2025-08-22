import 'tag.dart';

class Task {
  final int id;
  final String name;
  final int siteId;
  final String startDate;
  final String endDate;
  final String status;
  final AssignUser? createdBy;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;
  final int? completedBy;
  final int? progress;
  final int? totalWorkDone;
  final String? unit;
  final int? totalWork;
  final List<AssignUser> assignUser;
  final List<TaskImage> taskImages;
  final List<Tag> tags;
  final List<TaskAttachment> taskAttachments;
  final List<TaskProgress> taskProgress;

  Task({
    required this.id,
    required this.name,
    required this.siteId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.createdBy,
    required this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.completedBy,
    this.progress,
    this.totalWorkDone,
    this.unit,
    this.totalWork,
    required this.assignUser,
    required this.taskImages,
    required this.tags,
    required this.taskAttachments,
    required this.taskProgress,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    // Handle createdBy field which can be either an int (user ID) or an AssignUser object
    AssignUser? createdByUser;
    if (json['created_by'] != null) {
      if (json['created_by'] is Map<String, dynamic>) {
        // It's an AssignUser object
        createdByUser = AssignUser.fromJson(json['created_by']);
      } else if (json['created_by'] is int) {
        // It's a user ID, create a minimal AssignUser object
        createdByUser = AssignUser(
          id: json['created_by'],
          name: 'User ${json['created_by']}', // Fallback name
        );
      }
    }

    return Task(
      id: json['id'],
      name: json['name']?.toString() ?? '',
      siteId: json['site_id'],
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdBy: createdByUser,
      deletedAt: json['deleted_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      completedAt: json['completed_at']?.toString(),
      completedBy: json['completed_by'],
      progress: json['progress'],
      totalWorkDone: json['total_work_done'],
      unit: json['unit']?.toString(),
      totalWork: json['total_work'],
      assignUser: (json['assign_user'] as List<dynamic>?)?.map((e) => AssignUser.fromJson(e)).toList() ?? [],
      taskImages: (json['task_images'] as List<dynamic>?)?.map((e) => TaskImage.fromJson(e)).toList() ?? [],
      tags: (json['tags'] as List<dynamic>?)?.map((e) => Tag.fromJson(e)).toList() ?? [],
      taskAttachments: (json['task_attachments'] as List<dynamic>?)?.map((e) => TaskAttachment.fromJson(e)).toList() ?? [],
      taskProgress: (json['task_progress'] as List<dynamic>?)?.map((e) => TaskProgress.fromJson(e)).toList() ?? [],
    );
  }
}

class AssignUser {
  final int id;
  final String name;
  final String? image;
  final String? imagePath;
  final String? addharCardFrontPath;
  final String? addharCardBackPath;
  final String? panCardImagePath;
  final String? passbookImagePath;
  final Pivot? pivot;

  AssignUser({
    required this.id,
    required this.name,
    this.image,
    this.imagePath,
    this.addharCardFrontPath,
    this.addharCardBackPath,
    this.panCardImagePath,
    this.passbookImagePath,
    this.pivot,
  });

  factory AssignUser.fromJson(Map<String, dynamic> json) {
    return AssignUser(
      id: json['id'],
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
      imagePath: json['image_path']?.toString(),
      addharCardFrontPath: json['addhar_card_front_path']?.toString(),
      addharCardBackPath: json['addhar_card_back_path']?.toString(),
      panCardImagePath: json['pan_card_image_path']?.toString(),
      passbookImagePath: json['passbook_image_path']?.toString(),
      pivot: json['pivot'] != null ? Pivot.fromJson(json['pivot']) : null,
    );
  }
}

class Pivot {
  final int taskId;
  final int userId;

  Pivot({required this.taskId, required this.userId});

  factory Pivot.fromJson(Map<String, dynamic> json) {
    return Pivot(
      taskId: json['task_id'],
      userId: json['user_id'],
    );
  }
}

class TaskImage {
  final int id;
  final int taskId;
  final String image;
  final int createdBy;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;
  final String imageUrl;

  TaskImage({
    required this.id,
    required this.taskId,
    required this.image,
    required this.createdBy,
    required this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.imageUrl,
  });

  factory TaskImage.fromJson(Map<String, dynamic> json) {
    return TaskImage(
      id: json['id'],
      taskId: json['task_id'],
      image: json['image']?.toString() ?? '',
      createdBy: json['created_by'],
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }
}

class TaskAttachment {
  final int id;
  final int taskId;
  final String file;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;

  TaskAttachment({
    required this.id,
    required this.taskId,
    required this.file,
    required this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      id: json['id'],
      taskId: json['task_id'],
      file: json['file']?.toString() ?? '',
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class TaskProgress {
  final int id;
  final int taskId;
  final int userId;
  final String workDone;
  final String workLeft;
  final String? unit;
  final String remark;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final AssignUser? approvedBy;
  final String? approvedAt;
  final String status;
  final List<TaskProgressImage> taskProgressImage;
  final List<TaskRemark> taskRemark;
  final List<TaskProgressAttachment> taskAttachment;
  final AssignUser? user;

  TaskProgress({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.workDone,
    required this.workLeft,
    this.unit,
    required this.remark,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.approvedBy,
    this.approvedAt,
    required this.status,
    required this.taskProgressImage,
    required this.taskRemark,
    required this.taskAttachment,
    this.user,
  });

  factory TaskProgress.fromJson(Map<String, dynamic> json) {
    return TaskProgress(
      id: json['id'],
      taskId: json['task_id'],
      userId: json['user_id'],
      workDone: json['work_done']?.toString() ?? '0',
      workLeft: json['work_left']?.toString() ?? '0',
      unit: json['unit'],
      remark: json['remark']?.toString() ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      approvedBy: json['approved_by'] != null ? AssignUser.fromJson(json['approved_by']) : null,
      approvedAt: json['approved_at']?.toString(),
      status: json['status']?.toString() ?? 'Pending',
      taskProgressImage: (json['task_progress_image'] as List<dynamic>?)?.map((e) => TaskProgressImage.fromJson(e)).toList() ?? [],
      taskRemark: (json['task_remark'] as List<dynamic>?)?.map((e) => TaskRemark.fromJson(e)).toList() ?? [],
      taskAttachment: (json['task_attachment'] as List<dynamic>?)?.map((e) => TaskProgressAttachment.fromJson(e)).toList() ?? [],
      user: json['user'] != null ? AssignUser.fromJson(json['user']) : null,
    );
  }
}

class TaskProgressImage {
  final int id;
  final int taskProgressId;
  final int? userId;
  final String image;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String imageUrl;

  TaskProgressImage({
    required this.id,
    required this.taskProgressId,
    this.userId,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.imageUrl,
  });

  factory TaskProgressImage.fromJson(Map<String, dynamic> json) {
    return TaskProgressImage(
      id: json['id'],
      taskProgressId: json['task_progress_id'],
      userId: json['user_id'],
      image: json['image']?.toString() ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }
}

class TaskRemark {
  final int id;
  final int taskProgressId;
  final int userId;
  final String remark;
  final String createdAt;
  final String updatedAt;

  TaskRemark({
    required this.id,
    required this.taskProgressId,
    required this.userId,
    required this.remark,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskRemark.fromJson(Map<String, dynamic> json) {
    return TaskRemark(
      id: json['id'],
      taskProgressId: json['task_progress_id'],
      userId: json['user_id'],
      remark: json['remark']?.toString() ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class TaskProgressAttachment {
  final int id;
  final int taskProgressId;
  final String file;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String fileUrl;

  TaskProgressAttachment({
    required this.id,
    required this.taskProgressId,
    required this.file,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.fileUrl,
  });

  factory TaskProgressAttachment.fromJson(Map<String, dynamic> json) {
    return TaskProgressAttachment(
      id: json['id'],
      taskProgressId: json['task_progress_id'],
      file: json['file']?.toString() ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      fileUrl: json['file_url']?.toString() ?? '',
    );
  }
}