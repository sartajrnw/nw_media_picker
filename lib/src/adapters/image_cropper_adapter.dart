/// Abstraction over an interactive image cropper.
///
/// The package intentionally ships **no** cropping dependency in v1. Automatic
/// center-crop to an aspect ratio is handled by the processing pipeline. This
/// interface exists so an interactive cropper (e.g. `image_cropper`) can be
/// introduced later without changing the public API.
abstract interface class ImageCropperAdapter {
  /// Crops the image at [imagePath] to [aspectRatio] (width / height), or free
  /// crop when null. Returns the cropped file path, or `null` if cancelled.
  Future<String?> crop({
    required String imagePath,
    required double? aspectRatio,
  });
}
