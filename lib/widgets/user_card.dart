import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class UserCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String? subtitle;
  final String? designation;
  final String? department;
  final Widget? actionButton;
  final VoidCallback? onTap;

  const UserCard({
    Key? key,
    required this.name,
    this.imageUrl,
    this.subtitle,
    this.designation,
    this.department,
    this.actionButton,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.15),
          backgroundImage: imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null,
          child: (imageUrl == null || imageUrl!.isEmpty)
              ? Text(
                  name.isNotEmpty ? name[0] : '',
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(name, style: AppTypography.bodyMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) Text(subtitle!, style: AppTypography.bodySmall),
            if (designation != null && designation!.isNotEmpty)
              Text(designation!, style: AppTypography.bodySmall.copyWith(color: Colors.grey[700])),
            if (department != null && department!.isNotEmpty)
              Text(department!, style: AppTypography.bodySmall.copyWith(color: Colors.grey[700])),
          ],
        ),
        trailing: actionButton,
      ),
    );
  }
} 