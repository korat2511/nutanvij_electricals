import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class TaskValidationUtils {
  static bool canCreateTask(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final designationId = userProvider.user?.data.designationId ?? 99;
    return [1, 2, 3, 4].contains(designationId);
  }
}
