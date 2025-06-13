import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'dart:io';

class ImagePickerUtils {
  static Future<String?> pickImage({
    required BuildContext context,
    bool allowCamera = true,
    bool allowGallery = true,
    int imageQuality = 70,
  }) async {
    if (!allowCamera && !allowGallery) {
      throw Exception('At least one source must be allowed');
    }

    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Image Source',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (allowCamera)
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              if (allowGallery)
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primary),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
            ],
          ),
        );
      },
    );

    if (source == null) return null;

    try {
      final XFile? image = await ImagePicker().pickImage(
        source: source,
        imageQuality: imageQuality,
      );
      return image?.path;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }

  static Future<List<String>> pickMultipleImages({required BuildContext context}) async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    return images.map((xFile) => xFile.path).toList();
  }
} 