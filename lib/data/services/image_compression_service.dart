import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';

class ImageCompressionService {
  Future<File> compressImage(File sourceFile) async {
    try {
      final temporaryDirectory =
      await getTemporaryDirectory();

      final extension =
      path.extension(sourceFile.path).toLowerCase();

      final targetExtension =
      extension == '.png' ? '.png' : '.jpg';

      final targetPath = path.join(
        temporaryDirectory.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}'
            '$targetExtension',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        sourceFile.absolute.path,
        targetPath,
        minWidth: AppConstants.maxImageWidth,
        minHeight: AppConstants.maxImageWidth,
        quality: AppConstants.imageQuality,
        format: targetExtension == '.png'
            ? CompressFormat.png
            : CompressFormat.jpeg,
      );

      if (result == null) {
        throw const ImageProcessingException(
          'Image compression failed.',
        );
      }

      return File(result.path);
    } catch (e) {
      if (e is ImageProcessingException) {
        rethrow;
      }

      throw ImageProcessingException(
        'Failed to compress image: $e',
      );
    }
  }
}