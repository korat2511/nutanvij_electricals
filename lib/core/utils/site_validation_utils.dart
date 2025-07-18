import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'snackbar_utils.dart';

class SiteValidationUtils {
  static bool canManageUsers(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentDesignationId = userProvider.user?.data.designationId ?? 99;
    return [1, 2, 3, 4].contains(currentDesignationId);
  }

  static bool canCreateSite(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return userProvider.user?.data.designationId == 1;
  }

  static bool canEditSite(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentDesignationId = userProvider.user?.data.designationId ?? 99;
    return [1, 2, 3, 4].contains(currentDesignationId);
  }

  static bool canRemoveUser(BuildContext context, int userId) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return userProvider.user?.data.id != userId;
  }

  static void showNoPermissionError(BuildContext context) {
    SnackBarUtils.showError(
      context,
      'You do not have permission to assign or remove users.',
    );
  }

  static void showCannotRemoveSelfError(BuildContext context) {
    SnackBarUtils.showError(
      context,
      "You cannot remove yourself from the site.",
    );
  }

  static bool validateUserManagement(
    BuildContext context, {
    int? userIdToRemove,
    int? targetUserDesignationId,
  }) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentDesignationId = userProvider.user?.data.designationId ?? 99;

    if (!canManageUsers(context)) {
      showNoPermissionError(context);
      return false;
    }

    if (userIdToRemove != null && !canRemoveUser(context, userIdToRemove)) {
      showCannotRemoveSelfError(context);
      return false;
    }

    if (targetUserDesignationId != null && targetUserDesignationId < currentDesignationId) {
      SnackBarUtils.showError(
        context,
        "You cannot manage a user with higher authority than yourself.",
      );
      return false;
    }

    return true;
  }
} 