import 'package:image_picker/image_picker.dart';

import '../adapters/gallery_picker_adapter.dart';
import '../adapters/xfile_mapper.dart';
import '../exceptions/media_picker_exception.dart';
import '../logging/media_picker_logger.dart';
import '../models/gallery_picker_config.dart';
import '../models/media_result.dart';
import '../models/media_source.dart';

/// Gallery adapter backed by `image_picker`.
///
/// Returns **raw** [MediaResult]s (no resizing here) — the service applies the
/// processing pipeline so behavior is identical across camera and gallery.
/// The system photo picker manages its own access, so this adapter does not
/// pre-request permissions.
class ImagePickerGalleryAdapter implements GalleryPickerAdapter {
  final ImagePicker _picker;
  final MediaPickerLogger _logger;

  /// Creates the gallery adapter, optionally with an injected [picker] (tests).
  ImagePickerGalleryAdapter({
    ImagePicker? picker,
    MediaPickerLogger logger = const DebugMediaPickerLogger(),
  }) : _picker = picker ?? ImagePicker(),
       _logger = logger;

  @override
  Future<MediaResult?> pickImage({required GalleryPickerConfig config}) async {
    config.validate();
    try {
      _logger.debug('Opening gallery for single selection.');
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return null; // cancelled
      return XFileMapper.toMediaResult(file, source: MediaSource.gallery);
    } catch (e, s) {
      _logger.error('Gallery selection failed', error: e, stackTrace: s);
      throw MediaPickerException(
        MediaPickerErrorCode.gallerySelectionFailed,
        'Failed to pick image from gallery: $e',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<List<MediaResult>> pickMultipleImages({
    required GalleryPickerConfig config,
  }) async {
    config.validate();
    try {
      _logger.debug('Opening gallery for multiple selection.');
      // image_picker requires a limit >= 2; a limit of 1 is treated as
      // "no explicit limit" to satisfy the platform validator.
      final int? limit =
          (config.maxSelection != null && config.maxSelection! >= 2)
          ? config.maxSelection
          : null;
      final List<XFile> files = await _picker.pickMultiImage(limit: limit);
      if (files.isEmpty) return const [];

      final results = <MediaResult>[];
      for (final file in files) {
        results.add(
          await XFileMapper.toMediaResult(file, source: MediaSource.gallery),
        );
      }
      // Defensively enforce the cap even if the platform ignored `limit`.
      if (config.maxSelection != null &&
          results.length > config.maxSelection!) {
        return results.sublist(0, config.maxSelection!);
      }
      return results;
    } catch (e, s) {
      _logger.error('Multi gallery selection failed', error: e, stackTrace: s);
      throw MediaPickerException(
        MediaPickerErrorCode.gallerySelectionFailed,
        'Failed to pick images from gallery: $e',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<bool> isAvailable() async => true;
}
