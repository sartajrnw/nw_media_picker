import 'package:flutter/widgets.dart';

import '../theme/media_picker_theme.dart';
import 'camera_capture_config.dart';
import 'gallery_picker_config.dart';
import 'image_processing_config.dart';
import 'interactive_crop_config.dart';
import 'media_result.dart';
import 'media_source.dart';

/// Builds a custom source-chooser UI. Call `onSelected` with the chosen source,
/// or `onCancel` to dismiss.
typedef SourcePickerBuilder =
    Widget Function(
      BuildContext context,
      List<MediaSource> sources,
      ValueChanged<MediaSource> onSelected,
      VoidCallback onCancel,
    );

/// Builds a custom post-capture preview UI. Call `onUse` to accept the photo or
/// `onRetake` to return to the camera.
typedef PreviewBuilder =
    Widget Function(
      BuildContext context,
      MediaResult result,
      VoidCallback onUse,
      VoidCallback onRetake,
    );

/// High-level configuration passed to `NWMediaPicker.pickImage`.
///
/// Immutable and `const`-friendly. Groups the camera, gallery, and processing
/// sub-configs, plus theming and UX flags.
class MediaPickerConfig {
  /// Which sources to offer. When more than one is enabled, a source chooser
  /// is shown; when exactly one is enabled it opens directly.
  final List<MediaSource> sources;

  /// Camera capture configuration.
  final CameraCaptureConfig camera;

  /// Gallery selection configuration.
  final GalleryPickerConfig gallery;

  /// Interactive crop configuration. When [InteractiveCropConfig.enabled] is
  /// true, the user is shown a crop editor after capture/selection and before
  /// [processing] runs. Defaults to disabled.
  final InteractiveCropConfig crop;

  /// Image optimization configuration applied after selection/capture (and
  /// after interactive cropping, when enabled).
  final ImageProcessingConfig processing;

  /// Optional theme override. When null, a theme is derived from the host
  /// application's [ThemeData].
  final MediaPickerTheme? theme;

  /// Whether to show a preview screen after camera capture.
  final bool showPreviewAfterCapture;

  /// Optional custom builder for the source chooser.
  final SourcePickerBuilder? sourcePickerBuilder;

  /// Optional custom builder for the post-capture preview.
  final PreviewBuilder? previewBuilder;

  /// Creates a high-level media picker configuration.
  const MediaPickerConfig({
    this.sources = const [MediaSource.camera, MediaSource.gallery],
    this.camera = const CameraCaptureConfig(),
    this.gallery = const GalleryPickerConfig(),
    this.crop = InteractiveCropConfig.disabled,
    this.processing = const ImageProcessingConfig(),
    this.theme,
    this.showPreviewAfterCapture = true,
    this.sourcePickerBuilder,
    this.previewBuilder,
  });

  /// Validates all nested configs and this object's invariants.
  void validate() {
    if (sources.isEmpty) {
      throw ArgumentError('sources must not be empty');
    }
    camera.validate();
    gallery.validate();
    crop.validate();
    processing.validate();
  }

  /// Whether the camera source is enabled.
  bool get hasCamera => sources.contains(MediaSource.camera);

  /// Whether the gallery source is enabled.
  bool get hasGallery => sources.contains(MediaSource.gallery);

  /// Whether the files source is enabled.
  bool get hasFiles => sources.contains(MediaSource.files);

  /// Returns a copy with the given fields replaced.
  MediaPickerConfig copyWith({
    List<MediaSource>? sources,
    CameraCaptureConfig? camera,
    GalleryPickerConfig? gallery,
    InteractiveCropConfig? crop,
    ImageProcessingConfig? processing,
    MediaPickerTheme? theme,
    bool? showPreviewAfterCapture,
    SourcePickerBuilder? sourcePickerBuilder,
    PreviewBuilder? previewBuilder,
  }) {
    return MediaPickerConfig(
      sources: sources ?? this.sources,
      camera: camera ?? this.camera,
      gallery: gallery ?? this.gallery,
      crop: crop ?? this.crop,
      processing: processing ?? this.processing,
      theme: theme ?? this.theme,
      showPreviewAfterCapture:
          showPreviewAfterCapture ?? this.showPreviewAfterCapture,
      sourcePickerBuilder: sourcePickerBuilder ?? this.sourcePickerBuilder,
      previewBuilder: previewBuilder ?? this.previewBuilder,
    );
  }
}
