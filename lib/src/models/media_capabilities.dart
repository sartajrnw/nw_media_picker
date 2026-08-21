/// Describes which media features are available on the current platform/device.
///
/// Consuming apps can query this instead of writing `if (Platform.isWindows)`
/// checks throughout their code.
class MediaCapabilities {
  /// Whether camera capture is available at all.
  final bool camera;

  /// Whether gallery selection is available.
  final bool gallery;

  /// Whether selecting multiple gallery items is supported.
  final bool multipleGallerySelection;

  /// Whether a front-facing camera is present.
  final bool frontCamera;

  /// Whether a back-facing camera is present.
  final bool backCamera;

  /// Creates a capability descriptor.
  const MediaCapabilities({
    required this.camera,
    required this.gallery,
    required this.multipleGallerySelection,
    required this.frontCamera,
    required this.backCamera,
  });

  /// All features off — a safe default for unsupported platforms.
  static const MediaCapabilities none = MediaCapabilities(
    camera: false,
    gallery: false,
    multipleGallerySelection: false,
    frontCamera: false,
    backCamera: false,
  );

  @override
  String toString() =>
      'MediaCapabilities(camera: $camera, gallery: $gallery, '
      'multipleGallerySelection: $multipleGallerySelection, '
      'frontCamera: $frontCamera, backCamera: $backCamera)';
}
