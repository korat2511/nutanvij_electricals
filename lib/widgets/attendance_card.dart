import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../services/location_service.dart';

class AttendanceCard extends StatefulWidget {
  final String? checkInTime;
  final String? checkOutTime;
  final String? checkInDate;
  final String? checkOutDate;
  final VoidCallback onPunchIn;
  final VoidCallback onPunchOut;
  final bool isPunchedIn;

  const AttendanceCard({
    super.key,
    this.checkInTime,
    this.checkOutTime,
    this.checkInDate,
    this.checkOutDate,
    required this.onPunchIn,
    required this.onPunchOut,
    required this.isPunchedIn,
  });

  @override
  State<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<AttendanceCard> {
  String _address = 'Getting location...';

  @override
  void initState() {
    super.initState();
    _getCurrentAddress();
  }

  Future<void> _getCurrentAddress() async {
    final address = await LocationService.getCurrentAddress();
    if (mounted) {
      setState(() {
        _address = address;
      });
    }
  }

  Widget _buildTimeCard({
    required String title,
    required String time,
    required String date,
    required Color color,
    required String icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.1),
            ),
            child: SvgPicture.asset(
              icon,
              width: 20,
              height: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  time,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  date,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Attendance',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildTimeCard(
                  title: 'Check In',
                  time: widget.checkInTime ?? 'N/A',
                  date: widget.checkInDate ?? '',
                  color: AppColors.primary,
                  icon: 'assets/svg/punchin.svg',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeCard(
                  title: 'Check Out',
                  time: widget.checkOutTime ?? 'N/A',
                  date: widget.checkOutDate ?? '',
                  color: AppColors.punchOut,
                  icon: 'assets/svg/punchout.svg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: SvgPicture.asset(
                  "assets/svg/location.svg",
                  width: 15,
                  height: 15,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _address,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isPunchedIn ? widget.onPunchOut : widget.onPunchIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isPunchedIn  ? AppColors.punchOut : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.isPunchedIn ? 'Punch Out' : 'Punch In',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 