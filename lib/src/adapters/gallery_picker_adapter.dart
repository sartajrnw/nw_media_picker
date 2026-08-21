import '../models/gallery_picker_config.dart';
import '../models/media_result.dart';

/// Abstraction over "select image(s) from the gallery / file system".
abstract interface class GalleryPickerAdapter {
  /// Selects a single image. Returns `null` if the user cancels.
  Future<MediaResult?> pickImage({required GalleryPickerConfig config});

  /// Selects multiple images. Returns an empty list if the user cancels.
  Future<List<MediaResult>> pickMultipleImages({
    required GalleryPickerConfig config,
  });

  /// Whether gallery/file selection is available on this platform.
  Future<bool> isAvailable();
}
