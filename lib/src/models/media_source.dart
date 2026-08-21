/// Identifies where a piece of media originated from.
///
/// This is the package's own source enum. It intentionally does **not** reuse
/// `ImageSource` from `image_picker` so that the public API stays decoupled
/// from the underlying implementation.
enum MediaSource {
  /// Captured with the camera (in-app CameraX on Android, native on iOS).
  camera,

  /// Selected from the device photo gallery.
  gallery,

  /// Selected from the file system (desktop / document flows).
  files,
}

/// Convenience checks on [MediaSource].
extension MediaSourceX on MediaSource {
  /// Whether this source represents a live camera capture.
  bool get isCamera => this == MediaSource.camera;

  /// Whether this source represents a gallery selection.
  bool get isGallery => this == MediaSource.gallery;

  /// Whether this source represents a file-system selection.
  bool get isFiles => this == MediaSource.files;
}
