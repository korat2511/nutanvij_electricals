import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../constants/user_access.dart';
import '../../models/task.dart';

class TaskValidationUtils {
  static bool canCreateTask(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final designationId = userProvider.user?.data.designationId ?? 99;
    return [1, 2, 3, 4].contains(designationId);
  }

  /// Check if user can approve task progress (only admin and partner)
  static bool canApproveProgress(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final designationId = userProvider.user?.data.designationId;
    return [1, 2, 3, 4].contains(designationId);
  }

  /// Check if user can add new progress update
  static bool canAddProgressUpdate(BuildContext context, Task task) {
    // Always allow progress updates - removed the restriction for pending updates
    return true;
  }

  /// Get the reason why user cannot add progress update
  static String? getProgressUpdateBlockReason(BuildContext context, Task task) {
    // No longer blocking progress updates
    return null;
  }

  /// Check if user can edit a specific progress update
  static bool canEditProgress(BuildContext context, TaskProgress progress) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.user?.data.id;
    final designationId = userProvider.user?.data.designationId;
    
    // Admin/Partner can edit any progress
    if ([1, 2, 3, 4].contains(designationId)) {
      return true;
    }
    
    // User can edit their own progress if it's still pending
    if (currentUserId == progress.userId && progress.status.toLowerCase() == 'pending') {
      return true;
    }
    
    return false;
  }
}
