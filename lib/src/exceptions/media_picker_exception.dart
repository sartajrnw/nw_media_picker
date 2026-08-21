/// Stable, package-level error codes.
///
/// Consuming apps switch on these instead of catching raw plugin exceptions,
/// so the underlying implementation can change without breaking error handling.
enum MediaPickerErrorCode {
  /// Camera or gallery permission was denied for this request.
  permissionDenied,

  /// Permission was permanently denied; the user must enable it in Settings.
  permissionPermanentlyDenied,

  /// No usable camera hardware is available.
  cameraUnavailable,

  /// The camera controller failed to initialize (after fallbacks).
  cameraInitializationFailed,

  /// Capturing the photo failed.
  captureFailed,

  /// The gallery/file picker is unavailable on this platform.
  galleryUnavailable,

  /// Selecting from the gallery/files failed.
  gallerySelectionFailed,

  /// Image processing (resize/compress/orientation) failed.
  processingFailed,

  /// The requested operation is not supported on this platform.
  unsupportedPlatform,

  /// The user cancelled. Note: cancellation normally returns `null` rather
  /// than throwing — this code exists for completeness.
  cancelled,

  /// An unexpected error occurred.
  unknown,
}

/// The single exception type thrown by this package for real failures.
///
/// Cancellation does **not** throw — picker methods return `null` instead.
/// Genuine failures throw a [MediaPickerException] carrying a stable [code],
/// a human-readable [message], and the optional underlying [cause].
class MediaPickerException implements Exception {
  /// The stable error code.
  final MediaPickerErrorCode code;

  /// A human-readable description (not intended for end-user display as-is).
  final String message;

  /// The underlying error, if any.
  final Object? cause;

  /// The underlying stack trace, if any.
  final StackTrace? stackTrace;

  /// Creates a normalized package exception.
  const MediaPickerException(
    this.code,
    this.message, {
    this.cause,
    this.stackTrace,
  });

  /// Convenience: permission was denied.
  const MediaPickerException.permissionDenied([
    String message = 'Permission denied.',
  ]) : code = MediaPickerErrorCode.permissionDenied,
       message = message,
       cause = null,
       stackTrace = null;

  /// Convenience: permission was permanently denied.
  const MediaPickerException.permissionPermanentlyDenied([
    String message = 'Permission permanently denied.',
  ]) : code = MediaPickerErrorCode.permissionPermanentlyDenied,
       message = message,
       cause = null,
       stackTrace = null;

  /// Convenience: the platform does not support this operation.
  const MediaPickerException.unsupportedPlatform([
    String message = 'This operation is not supported on this platform.',
  ]) : code = MediaPickerErrorCode.unsupportedPlatform,
       message = message,
       cause = null,
       stackTrace = null;

  @override
  String toString() =>
      'MediaPickerException(${code.name}: $message${cause == null ? '' : ' | cause: $cause'})';
}
