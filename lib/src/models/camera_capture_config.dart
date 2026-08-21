import 'camera_enums.dart';

/// Configuration for the camera capture experience.
///
/// Immutable; prefer `const` construction. Individual flags gate on-screen
/// controls and behaviors of the in-app camera (Android). On iOS's native
/// camera, only a subset (e.g. [preferredLens]) applies.
class CameraCaptureConfig {
  /// The camera to prefer on open. Falls back to the other lens if the
  /// preferred one is unavailable.
  final CameraLens preferredLens;

  /// Whether to show the front/back switch control (hidden if only one camera).
  final bool allowCameraSwitch;

  /// Whether to expose flash controls.
  final bool allowFlash;

  /// Whether zoom is allowed at all.
  final bool allowZoom;

  /// Whether tapping the preview sets focus/exposure point.
  final bool enableTapToFocus;

  /// Whether to expose manual exposure adjustment (optional/advanced).
  final bool enableExposureControl;

  /// Whether pinch gestures control zoom.
  final bool enablePinchToZoom;

  /// Optional lower bound for zoom. Clamped to device capabilities.
  final double? minimumZoom;

  /// Optional upper bound for zoom. Clamped to device capabilities.
  final double? maximumZoom;

  /// Requested capture resolution (mapped internally, with fallback).
  final CameraResolution resolution;

  /// Which camera experience to present. See [CameraExperience].
  final CameraExperience experience;

  /// Creates an immutable camera capture configuration.
  const CameraCaptureConfig({
    this.preferredLens = CameraLens.back,
    this.allowCameraSwitch = true,
    this.allowFlash = true,
    this.allowZoom = true,
    this.enableTapToFocus = true,
    this.enableExposureControl = false,
    this.enablePinchToZoom = true,
    this.minimumZoom,
    this.maximumZoom,
    this.resolution = CameraResolution.high,
    this.experience = CameraExperience.platformDefault,
  });

  /// Validates the configuration, throwing [ArgumentError] on invalid values.
  void validate() {
    if (minimumZoom != null && minimumZoom! <= 0) {
      throw ArgumentError.value(
        minimumZoom,
        'minimumZoom',
        'must be greater than 0',
      );
    }
    if (maximumZoom != null && maximumZoom! <= 0) {
      throw ArgumentError.value(
        maximumZoom,
        'maximumZoom',
        'must be greater than 0',
      );
    }
    if (minimumZoom != null &&
        maximumZoom != null &&
        minimumZoom! > maximumZoom!) {
      throw ArgumentError('minimumZoom must be <= maximumZoom');
    }
  }

  /// Returns a copy with the given fields replaced.
  CameraCaptureConfig copyWith({
    CameraLens? preferredLens,
    bool? allowCameraSwitch,
    bool? allowFlash,
    bool? allowZoom,
    bool? enableTapToFocus,
    bool? enableExposureControl,
    bool? enablePinchToZoom,
    double? minimumZoom,
    double? maximumZoom,
    CameraResolution? resolution,
    CameraExperience? experience,
  }) {
    return CameraCaptureConfig(
      preferredLens: preferredLens ?? this.preferredLens,
      allowCameraSwitch: allowCameraSwitch ?? this.allowCameraSwitch,
      allowFlash: allowFlash ?? this.allowFlash,
      allowZoom: allowZoom ?? this.allowZoom,
      enableTapToFocus: enableTapToFocus ?? this.enableTapToFocus,
      enableExposureControl:
          enableExposureControl ?? this.enableExposureControl,
      enablePinchToZoom: enablePinchToZoom ?? this.enablePinchToZoom,
      minimumZoom: minimumZoom ?? this.minimumZoom,
      maximumZoom: maximumZoom ?? this.maximumZoom,
      resolution: resolution ?? this.resolution,
      experience: experience ?? this.experience,
    );
  }
}
