import '../models/image_processing_config.dart';
import '../models/media_result.dart';

/// Transforms a captured/selected image according to an
/// [ImageProcessingConfig].
///
/// The processing layer is deliberately decoupled from the camera/gallery
/// implementations: it receives a [MediaResult] (a path on disk) and returns a
/// new [MediaResult] pointing at the optimized output.
abstract interface class ImageProcessor {
  /// Processes [input] and returns the resulting media.
  ///
  /// Implementations should avoid large memory spikes for high-resolution
  /// images and must not upscale. When no processing is required they may
  /// return [input] unchanged (with metadata populated).
  ///
  /// Throws a `MediaPickerException` (code `processingFailed`) on failure.
  Future<MediaResult> process(MediaResult input, ImageProcessingConfig config);
}
