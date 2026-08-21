import '../models/interactive_crop_config.dart';

/// Abstraction over an interactive image cropper.
///
/// Implementations present a full-screen crop editor and return the path to the
/// cropped file. The default implementation is backed by the `image_cropper`
/// plugin on mobile; desktop uses a pass-through that returns the original
/// image. Keeping this behind an interface lets apps inject a custom cropper or
/// a fake in tests without touching the rest of the pipeline.
abstract interface class ImageCropperAdapter {
  /// Opens the crop editor for the image at [imagePath] using [config].
  ///
  /// Returns the cropped file path, or `null` if the user cancelled the editor.
  /// (How a cancellation is treated by the pick flow is governed by
  /// [InteractiveCropConfig.cancelReturnsOriginal].)
  ///
  /// Throws a `MediaPickerException` (`processingFailed`) on genuine failure.
  Future<String?> crop({
    required String imagePath,
    required InteractiveCropConfig config,
  });
}
