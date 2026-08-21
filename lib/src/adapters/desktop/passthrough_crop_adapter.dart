import '../../logging/media_picker_logger.dart';
import '../../models/interactive_crop_config.dart';
import '../image_cropper_adapter.dart';

/// [ImageCropperAdapter] for platforms without an interactive cropper (desktop).
///
/// Rather than failing, it logs and returns the original image path unchanged,
/// so an app that enables interactive cropping still works (sans crop) on
/// desktop and in headless tests.
class PassthroughCropAdapter implements ImageCropperAdapter {
  final MediaPickerLogger _logger;

  /// Creates the pass-through cropper.
  const PassthroughCropAdapter({
    MediaPickerLogger logger = const DebugMediaPickerLogger(),
  }) : _logger = logger;

  @override
  Future<String?> crop({
    required String imagePath,
    required InteractiveCropConfig config,
  }) async {
    _logger.info(
      'Interactive cropping is not supported on this platform; '
      'returning the original image.',
    );
    return imagePath;
  }
}
