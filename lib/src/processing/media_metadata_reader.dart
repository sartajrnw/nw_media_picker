import 'dart:io';
import 'dart:ui' as ui;

import '../logging/media_picker_logger.dart';

/// Pixel dimensions of an image.
class ImageDimensions {
  /// Width in pixels.
  final int width;

  /// Height in pixels.
  final int height;

  /// Creates a dimensions pair.
  const ImageDimensions(this.width, this.height);

  @override
  String toString() => '${width}x$height';
}

/// Reads image metadata cheaply.
///
/// Crucially, [readDimensions] uses [ui.ImageDescriptor.encoded], which parses
/// only the image header — it does **not** decode the full-resolution bitmap.
/// This keeps memory usage bounded even for 12MP/48MP source images (only the
/// compressed bytes are held, never the ~hundreds-of-MB decoded bitmap).
class MediaMetadataReader {
  final MediaPickerLogger _logger;

  /// Creates a metadata reader.
  const MediaMetadataReader({
    MediaPickerLogger logger = const DebugMediaPickerLogger(),
  }) : _logger = logger;

  /// Reads the pixel dimensions of the image at [path], or `null` if they
  /// cannot be determined (e.g. unsupported format).
  ///
  /// Dimensions reflect the encoded orientation as decoded by the engine.
  Future<ImageDimensions?> readDimensions(String path) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      return ImageDimensions(descriptor.width, descriptor.height);
    } catch (e, s) {
      _logger.warning('Could not read image dimensions for $path: $e');
      _logger.debug('$s');
      return null;
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
  }
}
