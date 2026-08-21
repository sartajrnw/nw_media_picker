import 'camera_capture_config.dart';
import 'camera_enums.dart';
import 'gallery_picker_config.dart';
import 'image_processing_config.dart';
import 'media_picker_config.dart';
import 'media_source.dart';

/// Convenience, business-agnostic configuration presets.
///
/// These are pure conveniences — the package works fully without them. Names
/// are intentionally generic (no app-specific branding or feature coupling).
class MediaPickerPresets {
  const MediaPickerPresets._();

  /// Front-camera, square, ~1000px, quality 85 — suitable for avatars.
  static const MediaPickerConfig profilePhoto = MediaPickerConfig(
    sources: [MediaSource.camera, MediaSource.gallery],
    camera: CameraCaptureConfig(
      preferredLens: CameraLens.front,
      resolution: CameraResolution.high,
    ),
    processing: ImageProcessingConfig(
      quality: 85,
      maxWidth: 1000,
      maxHeight: 1000,
      cropAspectRatio: 1,
    ),
  );

  /// Square 1:1 image at ~1200px — a generic square-crop preset.
  static const MediaPickerConfig squareImage = MediaPickerConfig(
    processing: ImageProcessingConfig(
      quality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
      cropAspectRatio: 1,
    ),
  );

  /// Back-camera, ~1600px, quality 85 — general catalog/product imagery.
  static const MediaPickerConfig productPhoto = MediaPickerConfig(
    sources: [MediaSource.camera, MediaSource.gallery],
    camera: CameraCaptureConfig(
      preferredLens: CameraLens.back,
      resolution: CameraResolution.veryHigh,
    ),
    processing: ImageProcessingConfig(
      quality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    ),
  );

  /// Back-camera, ~2200px, quality 90, no forced crop — high detail.
  static const MediaPickerConfig highQualityPhoto = MediaPickerConfig(
    camera: CameraCaptureConfig(
      preferredLens: CameraLens.back,
      resolution: CameraResolution.max,
    ),
    processing: ImageProcessingConfig(
      quality: 90,
      maxWidth: 2200,
      maxHeight: 2200,
    ),
  );

  /// Back-camera, high resolution, quality 90, minimal compression — documents.
  static const MediaPickerConfig documentPhoto = MediaPickerConfig(
    camera: CameraCaptureConfig(
      preferredLens: CameraLens.back,
      resolution: CameraResolution.max,
      allowFlash: true,
    ),
    processing: ImageProcessingConfig(
      quality: 90,
      maxWidth: 2400,
      maxHeight: 2400,
    ),
    gallery: GalleryPickerConfig(),
  );
}
