import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCompressionUtils {
  static const int maxSizeBytes = 800 * 1024; // 800 KB in bytes

  /// Compresses an image file to ensure it's under 800 KB
  /// Returns the compressed file path
  static Future<File> compressImage(File imageFile) async {
    try {
      // Get original file size
      final originalSize = await imageFile.length();
      
      // If already under 800 KB, return original
      if (originalSize <= maxSizeBytes) {
        return imageFile;
      }

      // Get temporary directory for compressed file
      final tempDir = await getTemporaryDirectory();
      final compressedPath = path.join(
        tempDir.path,
        'compressed_${path.basename(imageFile.path)}',
      );

      // Start with quality 85 and adjust based on size
      int quality = 85;
      File? compressedFile;

      while (quality > 10) {
        final result = await FlutterImageCompress.compressAndGetFile(
          imageFile.path,
          compressedPath,
          quality: quality,
          minWidth: 1024, // Maintain reasonable resolution
          minHeight: 1024,
        );

        if (result != null) {
          compressedFile = File(result.path);
          final compressedSize = await compressedFile!.length();

          // If size is acceptable, return the compressed file
          if (compressedSize <= maxSizeBytes) {
            return compressedFile!;
          }

          // If still too large, reduce quality and try again
          quality -= 15;
        } else {
          // If compression failed, return original
          return imageFile;
        }
      }

      // If we reach here, return the last compressed version even if it's still large
      return compressedFile ?? imageFile;
    } catch (e) {
      // If any error occurs, return original file
      return imageFile;
    }
  }

  /// Compresses multiple images and returns list of compressed files
  static Future<List<File>> compressImages(List<File> imageFiles) async {
    final List<File> compressedFiles = [];
    
    for (final imageFile in imageFiles) {
      final compressedFile = await compressImage(imageFile);
      compressedFiles.add(compressedFile);
    }
    
    return compressedFiles;
  }

  /// Gets file size in KB for display purposes
  static Future<String> getFileSizeInKB(File file) async {
    final sizeInBytes = await file.length();
    final sizeInKB = sizeInBytes / 1024;
    return '${sizeInKB.toStringAsFixed(1)} KB';
  }
} 