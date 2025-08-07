import 'package:flutter/material.dart';
import '../core/utils/navigation_utils.dart';
import '../models/task.dart';
import '../screens/user_profile_screen.dart';
import '../core/theme/app_colors.dart';

class ClickableUserName extends StatelessWidget {
  final AssignUser user;
  final TextStyle? style;
  final bool showUnderline;

  const ClickableUserName({
    Key? key,
    required this.user,
    this.style,
    this.showUnderline = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        NavigationUtils.push(
          context,
          UserProfileScreen(user: user),
        );
      },
      child: Text(
        user.name,
        style: style?.copyWith(
          color: AppColors.primary,
          decoration: showUnderline ? TextDecoration.underline : null,
        ) ?? TextStyle(
          color: AppColors.primary,
          decoration: showUnderline ? TextDecoration.underline : null,
        ),
      ),
    );
  }
} 