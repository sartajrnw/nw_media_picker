/// Configuration for the image optimization pipeline.
///
/// When no meaningful processing is requested (see [requiresProcessing]) the
/// pipeline skips re-encoding entirely to avoid unnecessary work and quality
/// loss.
class ImageProcessingConfig {
  /// JPEG quality, 1–100. Ignored when the image is passed through untouched.
  final int quality;

  /// Optional maximum width in pixels. The image is downscaled to fit.
  final int? maxWidth;

  /// Optional maximum height in pixels. The image is downscaled to fit.
  final int? maxHeight;

  /// Optional crop aspect ratio (width / height). `1` = square.
  final double? cropAspectRatio;

  /// Whether to preserve all metadata. When false, non-essential metadata is
  /// stripped (orientation is still applied first — see [correctOrientation]).
  final bool preserveMetadata;

  /// Whether to bake EXIF orientation into the pixels so images never appear
  /// sideways.
  final bool correctOrientation;

  /// Whether to strip unnecessary metadata from the output.
  final bool stripUnnecessaryMetadata;

  /// Creates an immutable processing configuration.
  const ImageProcessingConfig({
    this.quality = 85,
    this.maxWidth,
    this.maxHeight,
    this.cropAspectRatio,
    this.preserveMetadata = false,
    this.correctOrientation = true,
    this.stripUnnecessaryMetadata = true,
  });

  /// A config that performs no resizing/compression (pass-through), useful when
  /// the caller wants the original file untouched.
  static const ImageProcessingConfig none = ImageProcessingConfig(
    quality: 100,
    correctOrientation: false,
    stripUnnecessaryMetadata: false,
  );

  /// Validates bounds, throwing [ArgumentError] on invalid values.
  void validate() {
    if (quality < 1 || quality > 100) {
      throw ArgumentError.value(
        quality,
        'quality',
        'must be between 1 and 100',
      );
    }
    if (maxWidth != null && maxWidth! <= 0) {
      throw ArgumentError.value(maxWidth, 'maxWidth', 'must be > 0');
    }
    if (maxHeight != null && maxHeight! <= 0) {
      throw ArgumentError.value(maxHeight, 'maxHeight', 'must be > 0');
    }
    if (cropAspectRatio != null && cropAspectRatio! <= 0) {
      throw ArgumentError.value(
        cropAspectRatio,
        'cropAspectRatio',
        'must be > 0',
      );
    }
  }

  /// Whether this configuration would actually alter the image.
  ///
  /// If nothing here changes the output, the pipeline can return the original
  /// file untouched (subject to orientation correction).
  bool get requiresProcessing =>
      maxWidth != null ||
      maxHeight != null ||
      cropAspectRatio != null ||
      quality < 100 ||
      correctOrientation ||
      stripUnnecessaryMetadata;

  /// Returns a copy with the given fields replaced.
  ImageProcessingConfig copyWith({
    int? quality,
    int? maxWidth,
    int? maxHeight,
    double? cropAspectRatio,
    bool? preserveMetadata,
    bool? correctOrientation,
    bool? stripUnnecessaryMetadata,
  }) {
    return ImageProcessingConfig(
      quality: quality ?? this.quality,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      cropAspectRatio: cropAspectRatio ?? this.cropAspectRatio,
      preserveMetadata: preserveMetadata ?? this.preserveMetadata,
      correctOrientation: correctOrientation ?? this.correctOrientation,
      stripUnnecessaryMetadata:
          stripUnnecessaryMetadata ?? this.stripUnnecessaryMetadata,
    );
  }
}
