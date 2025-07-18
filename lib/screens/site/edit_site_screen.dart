import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/image_picker_utils.dart';
import 'dart:io';
import '../../widgets/custom_text_field.dart';
import '../../core/utils/navigation_utils.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../../models/site.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';

class EditSiteScreen extends StatefulWidget {
  final Site site;
  
  const EditSiteScreen({Key? key, required this.site}) : super(key: key);

  @override
  _EditSiteScreenState createState() => _EditSiteScreenState();
}

class _EditSiteScreenState extends State<EditSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _minRangeController = TextEditingController();
  final TextEditingController _maxRangeController = TextEditingController();
  
  final List<String> _newImages = [];
  List<SiteImage> _existingImages = [];
  List<int> _existingImageIds = [];
  
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;
  GoogleMapController? _mapController;
  LatLng? _selectedLatLng;
  bool _isMapLoading = true;
  bool _isDeletingImage = false;
  int? _deletingImageId;
  final Key _mapKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final site = widget.site;
    _nameController.text = site.name;
    _companyController.text = site.company;
    _addressController.text = site.address;
    _latitudeController.text = site.latitude;
    _longitudeController.text = site.longitude;
    _minRangeController.text = site.minRange?.toString() ?? '500';
    _maxRangeController.text = site.maxRange?.toString() ?? '500';
    
    if (site.startDate != null) {
      _startDate = DateFormat('yyyy-MM-dd').parse(site.startDate!);
    }
    if (site.endDate != null) {
      _endDate = DateFormat('yyyy-MM-dd').parse(site.endDate!);
    }
    
    _selectedLatLng = LatLng(double.parse(site.latitude), double.parse(site.longitude));
    _existingImages = List.from(site.siteImages);
    _existingImageIds = site.siteImages.map((img) => img.id).toList();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _minRangeController.dispose();
    _maxRangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Edit Site', style: AppTypography.titleLarge),
        backgroundColor: AppColors.primary,
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: 'Site Name',
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: TextEditingController(text: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : ''),
                  label: 'Start Date',
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                  validator: (v) => _startDate == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: TextEditingController(text: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : ''),
                  label: 'End Date',
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
                      firstDate: _startDate ?? DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _endDate = picked);
                  },
                  validator: (v) => _endDate == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _companyController,
                  label: 'Company',
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.none,
                        child: GoogleMap(
                          key: _mapKey,
                          initialCameraPosition: CameraPosition(
                            target: _selectedLatLng ?? const LatLng(21.1702, 72.8311),
                            zoom: 14,
                          ),
                          onMapCreated: (controller) {
                            _mapController = controller;
                            setState(() => _isMapLoading = false);
                          },
                          markers: _selectedLatLng != null
                              ? {
                                  Marker(
                                    markerId: const MarkerId('selected'),
                                    position: _selectedLatLng!,
                                  ),
                                }
                              : {},
                          onTap: _onMapTap,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: false,
                          zoomGesturesEnabled: true,
                          scrollGesturesEnabled: true,
                          rotateGesturesEnabled: true,
                          tiltGesturesEnabled: true,
                          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                          },
                        ),
                      ),
                      if (_isMapLoading)
                        const Center(child: CircularProgressIndicator()),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Column(
                          children: [
                            FloatingActionButton(
                              heroTag: 'zoom_in',
                              mini: true,
                              backgroundColor: Colors.white,
                              child: const Icon(Icons.add, color: Colors.black),
                              onPressed: () {
                                _mapController?.animateCamera(CameraUpdate.zoomIn());
                              },
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton(
                              heroTag: 'zoom_out',
                              mini: true,
                              backgroundColor: Colors.white,
                              child: const Icon(Icons.remove, color: Colors.black),
                              onPressed: () {
                                _mapController?.animateCamera(CameraUpdate.zoomOut());
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _addressController,
                  label: 'Address',
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: TextEditingController(text: _latitudeController.text.isNotEmpty ? double.parse(_latitudeController.text).toStringAsFixed(6) : ''),
                        label: 'Latitude',
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        onChanged: (val) {
                          if (val.isNotEmpty) _latitudeController.text = double.tryParse(val)?.toStringAsFixed(6) ?? val;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: TextEditingController(text: _longitudeController.text.isNotEmpty ? double.parse(_longitudeController.text).toStringAsFixed(6) : ''),
                        label: 'Longitude',
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        onChanged: (val) {
                          if (val.isNotEmpty) _longitudeController.text = double.tryParse(val)?.toStringAsFixed(6) ?? val;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _minRangeController,
                        label: 'Minimum checkin range (meters)',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final value = int.tryParse(v);
                          if (value == null || value <= 0) return 'Must be a positive number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _maxRangeController,
                        label: 'Auto checkout range (meters)',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final value = int.tryParse(v);
                          if (value == null || value <= 0) return 'Must be a positive number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Existing Images:', style: AppTypography.bodyMedium),
                const SizedBox(height: 8),
                if (_existingImages.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _existingImages.map((img) => Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            img.imageUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (_isDeletingImage) return;
                            setState(() {
                              _isDeletingImage = true;
                              _deletingImageId = img.id;
                            });
                            final userProvider = Provider.of<UserProvider>(context, listen: false);
                            try {
                              await ApiService().deleteSiteImage(
                                context: context,
                                apiToken: userProvider.user?.data.apiToken ?? '',
                                imageId: img.id,
                              );
                              setState(() {
                                _existingImages.remove(img);
                                _existingImageIds.remove(img.id);
                              });
                            } on ApiException catch (e) {
                              SnackBarUtils.showError(context, e.message);
                            } catch (e) {
                              SnackBarUtils.showError(context, 'Failed to delete image.');
                            } finally {
                              setState(() {
                                _isDeletingImage = false;
                                _deletingImageId = null;
                              });
                            }
                          },
                          child: _isDeletingImage && _deletingImageId == img.id
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                        ),
                      ],
                    )).toList(),
                  ),
                const SizedBox(height: 16),
                Text('Add New Images:', style: AppTypography.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._newImages.map((img) => Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(img),
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _newImages.remove(img);
                                });
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        )),
                    GestureDetector(
                      onTap: () async {
                        final picked = await ImagePickerUtils.pickMultipleImages(context: context);
                        if (picked.isNotEmpty) {
                          setState(() {
                            _newImages.addAll(picked.where((p) => !_newImages.contains(p)));
                          });
                        }
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: const Icon(Icons.add_a_photo, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                if (_existingImages.isEmpty && _newImages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('Please keep at least one image.', style: TextStyle(color: AppColors.error)),
                  ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Update Site',
                  isLoading: _isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && (_existingImages.isNotEmpty || _newImages.isNotEmpty)) {
                      if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
                        SnackBarUtils.showError(context, 'End date cannot be before start date.');
                        return;
                      }
                      setState(() => _isLoading = true);
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      try {
                        await ApiService().updateSite(
                          context: context,
                          apiToken: userProvider.user?.data.apiToken ?? '',
                          siteId: widget.site.id,
                          name: _nameController.text.trim(),
                          latitude: _latitudeController.text.trim(),
                          longitude: _longitudeController.text.trim(),
                          address: _addressController.text.trim(),
                          company: _companyController.text.trim(),
                          startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : '',
                          endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : '',
                          minRange: int.parse(_minRangeController.text.trim()),
                          maxRange: int.parse(_maxRangeController.text.trim()),
                          newImagePaths: _newImages,
                          existingImageIds: _existingImageIds,
                        );
                        if (mounted) {
                          SnackBarUtils.showSuccess(context, 'Site updated successfully!');
                          NavigationUtils.pop(context, true);
                        }
                      } on ApiException catch (e) {
                        SnackBarUtils.showError(context, e.message);
                      } catch (e) {
                        SnackBarUtils.showError(context, 'Something went wrong.');
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onMapTap(LatLng latLng) async {
    setState(() {
      _selectedLatLng = latLng;
      _latitudeController.text = latLng.latitude.toStringAsFixed(6);
      _longitudeController.text = latLng.longitude.toStringAsFixed(6);
    });
    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
          place.country
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      // ignore geocoding errors
    }
  }
} 