import 'dart:io';

import 'media_source.dart';

/// A normalized, package-owned result describing a single piece of media.
///
/// The package never returns `XFile` (or any other third-party type) as its
/// primary result — everything is translated into a [MediaResult] so consuming
/// apps depend only on this package's contract.
///
/// The [path] points at a file that may live in temporary storage. Applications
/// that need the media long-term should copy/persist it (see
/// `NWMediaPicker.clearTemporaryFiles`).
class MediaResult {
  /// Absolute path to the media file on disk.
  final String path;

  /// Where this media came from.
  final MediaSource source;

  /// When this result was produced.
  final DateTime createdAt;

  /// MIME type (e.g. `image/jpeg`) when known.
  final String? mimeType;

  /// Pixel width when known.
  final int? width;

  /// Pixel height when known.
  final int? height;

  /// File size in bytes when known.
  final int? sizeBytes;

  /// The original file name reported by the source, when available.
  final String? originalFileName;

  /// Creates a normalized media result.
  const MediaResult({
    required this.path,
    required this.source,
    required this.createdAt,
    this.mimeType,
    this.width,
    this.height,
    this.sizeBytes,
    this.originalFileName,
  });

  /// The underlying file.
  ///
  /// Only valid on platforms with a file system (all currently supported
  /// targets: Android, iOS, Windows, macOS, Linux). Avoid on web.
  File get file => File(path);

  /// Whether the referenced file currently exists on disk.
  bool get exists => file.existsSync();

  /// File size in megabytes, or `null` when [sizeBytes] is unknown.
  double? get sizeMB => sizeBytes == null ? null : sizeBytes! / (1024 * 1024);

  /// Whether this media was captured with the camera.
  bool get isCameraCapture => source == MediaSource.camera;

  /// Whether this media was chosen from the gallery.
  bool get isGallerySelection => source == MediaSource.gallery;

  /// Returns a copy of this result with the given fields replaced.
  MediaResult copyWith({
    String? path,
    MediaSource? source,
    DateTime? createdAt,
    String? mimeType,
    int? width,
    int? height,
    int? sizeBytes,
    String? originalFileName,
  }) {
    return MediaResult(
      path: path ?? this.path,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      originalFileName: originalFileName ?? this.originalFileName,
    );
  }

  @override
  String toString() =>
      'MediaResult(path: $path, source: $source, ${width}x$height, '
      '${sizeBytes}B, mime: $mimeType)';
}
