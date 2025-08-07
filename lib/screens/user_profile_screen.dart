import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/navigation_utils.dart';
import '../models/task.dart';
import '../widgets/custom_app_bar.dart';
import '../screens/viewer/full_screen_image_viewer.dart';

class UserProfileScreen extends StatefulWidget {
  final AssignUser user;

  const UserProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: CustomAppBar(
        title: 'User Profile',
        onMenuPressed: () => Navigator.of(context).pop(),
        showProfilePicture: false,
        showNotification: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header Card
            Container(
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
                children: [
                  // Profile Picture
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                    ),
                    child: ClipOval(
                      child: widget.user.imagePath != null
                          ? Image.network(
                              widget.user.imagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // User Name
                  Text(
                    widget.user.name,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // User ID
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ID: ${widget.user.id}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // User Details Card
            Container(
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
                  Text(
                    'User Information',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Profile Images Section
                  if (widget.user.addharCardFrontPath != null || 
                      widget.user.addharCardBackPath != null ||
                      widget.user.panCardImagePath != null ||
                      widget.user.passbookImagePath != null) ...[
                    Text(
                      'Documents',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (widget.user.addharCardFrontPath != null)
                          _buildDocumentCard('Aadhar Front', widget.user.addharCardFrontPath!),
                        if (widget.user.addharCardBackPath != null)
                          _buildDocumentCard('Aadhar Back', widget.user.addharCardBackPath!),
                        if (widget.user.panCardImagePath != null)
                          _buildDocumentCard('PAN Card', widget.user.panCardImagePath!),
                        if (widget.user.passbookImagePath != null)
                          _buildDocumentCard('Passbook', widget.user.passbookImagePath!),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                                     // User ID Information
                   Text(
                     'User Information',
                     style: AppTypography.bodyMedium.copyWith(
                       fontWeight: FontWeight.w600,
                       color: Colors.black87,
                     ),
                   ),
                   const SizedBox(height: 12),
                   
                   _buildInfoRow('User ID', widget.user.id.toString()),
                   _buildInfoRow('Name', widget.user.name),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Quick Actions Card
            Container(
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
                  Text(
                    'Quick Actions',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.work,
                          label: 'Tasks',
                          onTap: () {
                            // Navigate to user's tasks
                            Navigator.of(context).pop();
                            // You can add navigation to user's tasks here
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.access_time,
                          label: 'Attendance',
                          onTap: () {
                            // Navigate to user's attendance
                            Navigator.of(context).pop();
                            // You can add navigation to user's attendance here
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.event_note,
                          label: 'Leaves',
                          onTap: () {
                            // Navigate to user's leaves
                            Navigator.of(context).pop();
                            // You can add navigation to user's leaves here
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.receipt,
                          label: 'Expenses',
                          onTap: () {
                            // Navigate to user's expenses
                            Navigator.of(context).pop();
                            // You can add navigation to user's expenses here
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(String title, String imagePath) {
    return GestureDetector(
      onTap: () {
        NavigationUtils.push(
          context,
          FullScreenImageViewer(
            images: [imagePath],
            initialIndex: 0,
          ),
        );
      },
      child: Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 