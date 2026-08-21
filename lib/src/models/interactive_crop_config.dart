import 'package:flutter/painting.dart' show Color;

/// Shape of the interactive crop mask.
enum CropShape {
  /// A rectangular crop region (the default).
  rectangle,

  /// A circular/oval crop region — handy for avatars. Note the *output* is
  /// still a rectangular image; the shape only affects the on-screen mask.
  oval,
}

/// Configuration for the **interactive** (user-driven) image cropper.
///
/// This is distinct from [ImageProcessingConfig.cropAspectRatio], which performs
/// a silent, automatic center-crop. When [enabled] is true the user is presented
/// with a full-screen crop editor (backed by the `image_cropper` plugin on
/// mobile) *before* the image is optimized. On platforms without a cropper
/// (desktop), interactive cropping is skipped and the original image is used.
///
/// Colors left null fall back to the active [MediaPickerTheme], so the crop UI
/// matches the host app without extra configuration.
class InteractiveCropConfig {
  /// Whether to show the interactive crop editor.
  final bool enabled;

  /// Fixed crop aspect ratio (width / height). When null the user may choose
  /// freely (or from [showAspectRatioPresets]).
  final double? aspectRatio;

  /// Whether the aspect ratio is locked to [aspectRatio]. Ignored when
  /// [aspectRatio] is null.
  final bool lockAspectRatio;

  /// Whether to offer the built-in aspect-ratio preset picker (original,
  /// square, 3:2, 4:3, 16:9). Ignored when [lockAspectRatio] is true.
  final bool showAspectRatioPresets;

  /// Shape of the crop mask.
  final CropShape shape;

  /// JPEG quality of the cropper's own output, 1–100. The downstream
  /// [ImageProcessingConfig] may compress further.
  final int compressQuality;

  /// Title shown in the crop editor's toolbar/navigation bar.
  final String? toolbarTitle;

  /// Toolbar/navigation-bar background color. Falls back to the theme's
  /// primary color.
  final Color? toolbarColor;

  /// Toolbar text/icon color. Falls back to the theme's background color for
  /// contrast against [toolbarColor].
  final Color? toolbarWidgetColor;

  /// Color of active controls (handles, active preset). Falls back to the
  /// theme's primary color.
  final Color? activeControlsColor;

  /// Editor background color. Falls back to the theme's background color.
  final Color? backgroundColor;

  /// Whether to hide the bottom controls row (Android/UCrop only).
  final bool hideBottomControls;

  /// Whether to draw the rule-of-thirds crop grid.
  final bool showGrid;

  /// What to do when the user cancels the crop editor.
  ///
  /// * `false` (default) — cancelling the crop cancels the whole pick; the
  ///   picker returns `null`.
  /// * `true` — cancelling the crop keeps the original (uncropped) image and
  ///   the flow continues to processing.
  final bool cancelReturnsOriginal;

  /// Creates an interactive crop configuration.
  const InteractiveCropConfig({
    this.enabled = true,
    this.aspectRatio,
    this.lockAspectRatio = false,
    this.showAspectRatioPresets = true,
    this.shape = CropShape.rectangle,
    this.compressQuality = 90,
    this.toolbarTitle,
    this.toolbarColor,
    this.toolbarWidgetColor,
    this.activeControlsColor,
    this.backgroundColor,
    this.hideBottomControls = false,
    this.showGrid = true,
    this.cancelReturnsOriginal = false,
  });

  /// Interactive cropping turned off (the default for [MediaPickerConfig]).
  static const InteractiveCropConfig disabled = InteractiveCropConfig(
    enabled: false,
  );

  /// A square (1:1), aspect-locked crop — convenient for avatars.
  static const InteractiveCropConfig square = InteractiveCropConfig(
    aspectRatio: 1,
    lockAspectRatio: true,
    showAspectRatioPresets: false,
  );

  /// A circular avatar crop: square, aspect-locked, oval mask.
  static const InteractiveCropConfig circle = InteractiveCropConfig(
    aspectRatio: 1,
    lockAspectRatio: true,
    showAspectRatioPresets: false,
    shape: CropShape.oval,
  );

  /// Validates bounds, throwing [ArgumentError] on invalid values.
  void validate() {
    if (compressQuality < 1 || compressQuality > 100) {
      throw ArgumentError.value(
        compressQuality,
        'compressQuality',
        'must be between 1 and 100',
      );
    }
    if (aspectRatio != null && aspectRatio! <= 0) {
      throw ArgumentError.value(aspectRatio, 'aspectRatio', 'must be > 0');
    }
    if (lockAspectRatio && aspectRatio == null) {
      throw ArgumentError(
        'lockAspectRatio requires a non-null aspectRatio',
      );
    }
  }

  /// Returns a copy with the given fields replaced.
  InteractiveCropConfig copyWith({
    bool? enabled,
    double? aspectRatio,
    bool? lockAspectRatio,
    bool? showAspectRatioPresets,
    CropShape? shape,
    int? compressQuality,
    String? toolbarTitle,
    Color? toolbarColor,
    Color? toolbarWidgetColor,
    Color? activeControlsColor,
    Color? backgroundColor,
    bool? hideBottomControls,
    bool? showGrid,
    bool? cancelReturnsOriginal,
  }) {
    return InteractiveCropConfig(
      enabled: enabled ?? this.enabled,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      lockAspectRatio: lockAspectRatio ?? this.lockAspectRatio,
      showAspectRatioPresets:
          showAspectRatioPresets ?? this.showAspectRatioPresets,
      shape: shape ?? this.shape,
      compressQuality: compressQuality ?? this.compressQuality,
      toolbarTitle: toolbarTitle ?? this.toolbarTitle,
      toolbarColor: toolbarColor ?? this.toolbarColor,
      toolbarWidgetColor: toolbarWidgetColor ?? this.toolbarWidgetColor,
      activeControlsColor: activeControlsColor ?? this.activeControlsColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      hideBottomControls: hideBottomControls ?? this.hideBottomControls,
      showGrid: showGrid ?? this.showGrid,
      cancelReturnsOriginal:
          cancelReturnsOriginal ?? this.cancelReturnsOriginal,
    );
  }
}
