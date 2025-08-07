import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../services/location_service.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/site.dart';

class AttendanceCard extends StatefulWidget {
  final String? checkInTime;
  final String? checkOutTime;
  final String? checkInDate;
  final String? checkOutDate;
  final VoidCallback onPunchIn;
  final VoidCallback onPunchOut;
  final bool isPunchedIn;
  final bool isAutoCheckoutEnabled;
  final Site? checkInSite;

  const AttendanceCard({
    super.key,
    this.checkInTime,
    this.checkOutTime,
    this.checkInDate,
    this.checkOutDate,
    required this.onPunchIn,
    required this.onPunchOut,
    required this.isPunchedIn,
    this.isAutoCheckoutEnabled = false,
    this.checkInSite,
  });

  @override
  State<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<AttendanceCard> {
  String _address = 'Getting location...';
  bool _isLoadingLocation = true;
  LocationErrorType? _locationErrorType;
  String? _locationErrorMessage;

  @override
  void initState() {
    super.initState();
    _getCurrentAddress();
  }

  Future<void> _getCurrentAddress() async {
    setState(() {
      _isLoadingLocation = true;
      _locationErrorType = null;
      _locationErrorMessage = null;
    });

    final result = await LocationService.getCurrentAddressWithRetry();
    
    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
        if (result.isSuccess) {
          _address = result.address!;
        } else if (result.hasError) {
          _address = 'Address not available';
          _locationErrorType = result.errorType;
          _locationErrorMessage = result.errorMessage;
          
          // Start location service check if location service is disabled
          if (result.errorType == LocationErrorType.locationServiceDisabled) {
            _startLocationServiceCheck();
          }
        } else {
          _address = result.address ?? 'Address not available';
        }
      });
    }
  }

  Future<void> _handleLocationRetry() async {
    if (_locationErrorType == LocationErrorType.permissionDenied) {
      // Request permission again
      try {
        await LocationService.getCurrentPosition();
        await _getCurrentAddress();
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Location permission denied. Please grant permission in settings.');
        }
      }
    } else if (_locationErrorType == LocationErrorType.permissionDeniedForever) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Location permission is permanently denied. Please enable it in device settings.');
      }
    } else if (_locationErrorType == LocationErrorType.locationServiceDisabled) {
      // Check if location service is now enabled
      try {
        final isEnabled = await LocationService.isLocationServiceEnabled();
        if (isEnabled) {
          // Location service is now enabled, try to get location
          await _getCurrentAddress();
        } else {
          if (mounted) {
            SnackBarUtils.showError(context, 'Location services are still disabled. Please enable location services in your device settings.');
          }
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Failed to check location service status. Please try again.');
        }
      }
    } else {
      // For other errors, just retry
      await _getCurrentAddress();
    }
  }

  void _startLocationServiceCheck() {
    // Check location service status every 2 seconds when there's an error
    if (_locationErrorType == LocationErrorType.locationServiceDisabled) {
      Future.delayed(const Duration(seconds: 2), () async {
        if (mounted && _locationErrorType == LocationErrorType.locationServiceDisabled) {
          try {
            final isEnabled = await LocationService.isLocationServiceEnabled();
            if (isEnabled) {
              // Location service is now enabled, try to get location
              await _getCurrentAddress();
            } else {
              // Continue checking
              _startLocationServiceCheck();
            }
          } catch (e) {
            // Continue checking
            _startLocationServiceCheck();
          }
        }
      });
    }
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_locationErrorType != null && !_isLoadingLocation)
                    Row(
                      children: [

                        Expanded(
                          child: Text(
                            _locationErrorMessage ?? 'Failed to get location',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.orange,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        TextButton(
                          onPressed: _handleLocationRetry,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            'Retry',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_isLoadingLocation)
                    Row(
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Getting location...',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      _address,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),

      ],
    );
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
          _buildLocationSection(),
          const SizedBox(height: 16),
          
          // Auto checkout indicator
          if (widget.isAutoCheckoutEnabled && widget.checkInSite != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Auto checkout enabled for ${widget.checkInSite!.name} (${widget.checkInSite!.maxRange ?? 500}m range)',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
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