/// Which physical camera to prefer when opening the capture UI.
enum CameraLens {
  /// The user-facing (selfie) camera.
  front,

  /// The world-facing (rear) camera.
  back,
}

/// Package-level capture resolution.
///
/// This is intentionally decoupled from the `camera` package's
/// `ResolutionPreset` so the dependency can change without breaking the
/// public API.
enum CameraResolution {
  /// Lowest resolution — smallest files, fastest.
  low,

  /// Balanced resolution.
  medium,

  /// High resolution — a good default for uploads.
  high,

  /// Very high resolution.
  veryHigh,

  /// The maximum resolution the hardware advertises.
  max,
}

/// Selects which camera experience the package should present.
///
/// See the package README for the per-platform behavior matrix.
enum CameraExperience {
  /// Use the most appropriate default per platform.
  ///
  /// * Android → the in-app CameraX camera (never the OEM camera app).
  /// * iOS → the native `image_picker` camera.
  platformDefault,

  /// Force the package's custom in-app camera UI where implemented.
  custom,
}

/// Flash behavior exposed by the package.
///
/// Internally mapped to the `camera` package's flash mode; the underlying
/// enum is never exposed.
enum MediaFlashMode {
  /// Flash disabled.
  off,

  /// Flash fires automatically based on scene lighting.
  auto,

  /// Flash always fires on capture.
  on,

  /// Constant illumination (torch) while the camera is open.
  torch,
}

/// Explicit lifecycle state of the in-app camera screen.
enum CameraState {
  /// Camera resources are being acquired / the controller is initializing.
  initializing,

  /// Camera is initialized and previewing; capture is allowed.
  ready,

  /// A capture is currently in flight.
  capturing,

  /// The captured image is being processed.
  processing,

  /// A recoverable error occurred (e.g. initialization failure).
  error,

  /// Camera permission was denied.
  permissionDenied,
}
