import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../core/utils/snackbar_utils.dart';
import '../core/utils/navigation_utils.dart';
import 'edit_profile_screen.dart';
import 'viewer/full_screen_image_viewer.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;

  const ProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user == null) return;

      final apiService = ApiService();
      final response = await apiService.getProfile(
        context: context,
        apiToken: user.data.apiToken,
        userId: widget.userId.toString(),
      );

      setState(() {
        _profileData = response['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      SnackBarUtils.showError(context, 'Failed to load profile data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_profileData != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEditProfile(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfileData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null
              ? const Center(child: Text('No profile data available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 16),
                      _buildPersonalInfoCard(),
                      const SizedBox(height: 16),
                      _buildBankDetailsCard(),
                      const SizedBox(height: 16),
                      _buildDocumentsCard(),
                      const SizedBox(height: 16),
                      _buildSitesCard(),
                      const SizedBox(height: 16),
                      _buildAdditionalInfoCard(),
                      SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
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
              child: _profileData!['image_path'] != null
                  ? Image.network(
                      _profileData!['image_path'],
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
            _profileData!['name'] ?? 'N/A',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Employee ID
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ID: ${_profileData!['employee_id'] ?? 'N/A'}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _profileData!['status'] == 'Active'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _profileData!['status'] ?? 'N/A',
              style: AppTypography.bodySmall.copyWith(
                color: _profileData!['status'] == 'Active'
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
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
          Text(
            'Personal Information',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Name', _profileData!['name'] ?? 'N/A'),
          _buildInfoRow('Email', _profileData!['email'] ?? 'N/A'),
          _buildInfoRow('Mobile', _profileData!['mobile'] ?? 'N/A'),
          _buildInfoRow(
              'Designation', _profileData!['designation']?['name'] ?? 'N/A'),
          if (_profileData!['sub_department'] != null)
            _buildInfoRow(
                'Department', _profileData!['sub_department']['name'] ?? 'N/A'),
          _buildInfoRow('Date of Birth', _profileData!['dob'] ?? 'N/A'),
          _buildInfoRow(
              'Date of Joining', _profileData!['date_of_joining'] ?? 'N/A'),
          _buildInfoRow('Salary', _profileData!['salary'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildBankDetailsCard() {
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
          Text(
            'Bank Details',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Bank Name', _profileData!['bank_name'] ?? 'N/A'),
          _buildInfoRow(
              'Account No.', _profileData!['bank_account_no'] ?? 'N/A'),
          _buildInfoRow('IFSC Code', _profileData!['ifsc_code'] ?? 'N/A'),
          _buildInfoRow('PAN Card', _profileData!['pan_card_no'] ?? 'N/A'),
          _buildInfoRow(
              'Aadhar Card', _profileData!['aadhar_card_no'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildDocumentsCard() {
    final documents = <String, String?>{};

    if (_profileData!['addhar_card_front_path'] != null) {
      documents['Aadhar Front'] = _profileData!['addhar_card_front_path'];
    }
    if (_profileData!['addhar_card_back_path'] != null) {
      documents['Aadhar Back'] = _profileData!['addhar_card_back_path'];
    }
    if (_profileData!['pan_card_image_path'] != null) {
      documents['PAN Card'] = _profileData!['pan_card_image_path'];
    }
    if (_profileData!['passbook_image_path'] != null) {
      documents['Passbook'] = _profileData!['passbook_image_path'];
    }

    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }

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
          Text(
            'Documents',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: documents.entries.map((entry) {
              return _buildDocumentCard(entry.key, entry.value!);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSitesCard() {
    final sites = _profileData!['sites'] as List<dynamic>? ?? [];

    if (sites.isEmpty) {
      return const SizedBox.shrink();
    }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assigned Sites',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                "+ Add or Remove",
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          ...sites.map((site) => _buildSiteCard(site)).toList(),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
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
          Text(
            'Additional Information',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
              'Document Status', _profileData!['document_status'] ?? 'N/A'),
          _buildInfoRow('Has Keypad Mobile',
              _profileData!['has_keypad_mobile'] == 1 ? 'Yes' : 'No'),
          _buildInfoRow('Check-in Exempted',
              _profileData!['is_checkin_exmpted'] == 1 ? 'Yes' : 'No'),
        ],
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
            width: 120,
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

  Widget _buildDocumentCard(String title, String imagePath) {
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = 32.0;
    const cardSpacing = 12.0;
    final availableWidth = screenWidth - horizontalPadding;
    final cardWidth = (availableWidth - cardSpacing) / 2;

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
        width: cardWidth,
        height: cardWidth * 0.8, // Maintain aspect ratio
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade50,
        ),
        child: Column(
          children: [
            // Image Preview
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.description,
                          color: AppColors.primary,
                          size: cardWidth * 0.15,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Title
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    NavigationUtils.push(
      context,
      EditProfileScreen(profileData: _profileData!),
    ).then((result) {
      if (result == true) {
        // Refresh profile data after successful edit
        _loadProfileData();
      }
    });
  }

  Widget _buildSiteCard(Map<String, dynamic> site) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  site['name'] ?? 'N/A',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: site['status'] == 'Active'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  site['status'] ?? 'N/A',
                  style: AppTypography.bodySmall.copyWith(
                    color:
                        site['status'] == 'Active' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            site['address'] ?? 'N/A',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
