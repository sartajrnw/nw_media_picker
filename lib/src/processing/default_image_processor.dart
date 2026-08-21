import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../exceptions/media_picker_exception.dart';
import '../logging/media_picker_logger.dart';
import '../models/image_processing_config.dart';
import '../models/media_result.dart';
import '../utils/media_file_utils.dart';
import '../utils/media_temp_manager.dart';
import 'image_processor.dart';
import 'media_metadata_reader.dart';

/// Default [ImageProcessor] backed by `flutter_image_compress`.
///
/// Design goals:
/// * **Memory safety** — resizing/compression run natively via
///   [FlutterImageCompress.compressAndGetFile], which reads from disk and never
///   materializes the full-resolution bitmap on the Dart heap. Source
///   dimensions are read header-only. Optional cropping runs on the already
///   down-scaled image, so the only in-heap decode is small.
/// * **No unnecessary work** — when the config would not change the image, the
///   original file is returned untouched.
/// * **Correct orientation** — EXIF rotation is baked into pixels so images do
///   not appear sideways; output is always JPEG (documented behavior).
class DefaultImageProcessor implements ImageProcessor {
  final MediaTempManager _temp;
  final MediaMetadataReader _metadata;
  final MediaPickerLogger _logger;

  /// Creates the default processor.
  DefaultImageProcessor({
    required MediaTempManager tempManager,
    MediaMetadataReader? metadataReader,
    MediaPickerLogger logger = const DebugMediaPickerLogger(),
  }) : _temp = tempManager,
       _metadata = metadataReader ?? MediaMetadataReader(logger: logger),
       _logger = logger;

  @override
  Future<MediaResult> process(
    MediaResult input,
    ImageProcessingConfig config,
  ) async {
    config.validate();

    try {
      if (!config.requiresProcessing) {
        return _withMetadata(input);
      }

      final srcDims = await _metadata.readDimensions(input.path);
      final target = _targetDimensions(srcDims, config);

      final compressedPath = await _temp.newFilePath(extension: 'jpg');
      final result = await FlutterImageCompress.compressAndGetFile(
        input.path,
        compressedPath,
        minWidth: target.width,
        minHeight: target.height,
        quality: config.quality,
        autoCorrectionAngle: config.correctOrientation,
        keepExif: config.preserveMetadata,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        throw const MediaPickerException(
          MediaPickerErrorCode.processingFailed,
          'Image compression returned no output.',
        );
      }

      var outputPath = result.path;

      if (config.cropAspectRatio != null) {
        final cropped = await _centerCropToAspect(
          outputPath,
          config.cropAspectRatio!,
          config.quality,
        );
        if (cropped != null && cropped != outputPath) {
          await _deleteQuietly(outputPath);
          outputPath = cropped;
        }
      }

      return _withMetadata(
        input.copyWith(path: outputPath, mimeType: 'image/jpeg'),
      );
    } on MediaPickerException {
      rethrow;
    } catch (e, s) {
      _logger.error('Image processing failed', error: e, stackTrace: s);
      throw MediaPickerException(
        MediaPickerErrorCode.processingFailed,
        'Failed to process image: $e',
        cause: e,
        stackTrace: s,
      );
    }
  }

  /// Computes the resize target passed to the native compressor.
  ///
  /// The returned dimensions preserve aspect ratio and fit within the
  /// configured `maxWidth`/`maxHeight` bounding box (longest side included),
  /// and never upscale. Because they are proportional to the source, the
  /// native `min(w/tw, h/th)` scaling reproduces them exactly.
  ImageDimensions _targetDimensions(
    ImageDimensions? src,
    ImageProcessingConfig config,
  ) {
    // Fallback when source dimensions are unknown: hand the native side the
    // configured bounds (best effort), or a large no-op bound.
    if (src == null) {
      return ImageDimensions(
        config.maxWidth ?? 1 << 20,
        config.maxHeight ?? 1 << 20,
      );
    }

    var scale = 1.0;
    if (config.maxWidth != null) {
      scale = math.min(scale, config.maxWidth! / src.width);
    }
    if (config.maxHeight != null) {
      scale = math.min(scale, config.maxHeight! / src.height);
    }
    if (scale >= 1.0) {
      return src; // never upscale
    }
    return ImageDimensions(
      math.max(1, (src.width * scale).round()),
      math.max(1, (src.height * scale).round()),
    );
  }

  /// Center-crops the (already down-scaled, upright) JPEG at [path] to
  /// [aspectRatio] (width / height) and re-encodes as JPEG at [quality].
  ///
  /// Operates on the small, down-scaled image, so the in-heap decode is
  /// bounded. Returns the new path, or the original path if no crop is needed.
  Future<String?> _centerCropToAspect(
    String path,
    double aspectRatio,
    int quality,
  ) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final w = image.width;
      final h = image.height;
      final currentRatio = w / h;

      int cropW;
      int cropH;
      if ((currentRatio - aspectRatio).abs() < 0.001) {
        return path; // already the requested ratio
      } else if (currentRatio > aspectRatio) {
        // Too wide: trim width.
        cropH = h;
        cropW = (h * aspectRatio).round();
      } else {
        // Too tall: trim height.
        cropW = w;
        cropH = (w / aspectRatio).round();
      }
      cropW = cropW.clamp(1, w);
      cropH = cropH.clamp(1, h);
      final dx = ((w - cropW) / 2).floor().toDouble();
      final dy = ((h - cropH) / 2).floor().toDouble();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final src = ui.Rect.fromLTWH(dx, dy, cropW.toDouble(), cropH.toDouble());
      final dst = ui.Rect.fromLTWH(0, 0, cropW.toDouble(), cropH.toDouble());
      canvas.drawImageRect(image, src, dst, ui.Paint());
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(cropW, cropH);
      picture.dispose();

      final pngData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      croppedImage.dispose();
      if (pngData == null) return path;

      final jpeg = await FlutterImageCompress.compressWithList(
        pngData.buffer.asUint8List(),
        minWidth: cropW,
        minHeight: cropH,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      final outPath = await _temp.newFilePath(extension: 'jpg');
      await File(outPath).writeAsBytes(jpeg, flush: true);
      return outPath;
    } finally {
      image.dispose();
      codec.dispose();
    }
  }

  Future<MediaResult> _withMetadata(MediaResult r) async {
    final dims = await _metadata.readDimensions(r.path);
    return r.copyWith(
      width: dims?.width,
      height: dims?.height,
      sizeBytes: MediaFileUtils.sizeBytesOf(r.path),
      mimeType: r.mimeType ?? MediaFileUtils.mimeTypeForPath(r.path),
    );
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } on FileSystemException catch (e) {
      _logger.warning('Could not delete intermediate file $path: $e');
    }
  }
}
