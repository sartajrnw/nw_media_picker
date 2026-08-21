import 'media_result.dart';

/// Optional lifecycle callbacks for analytics/telemetry.
///
/// The package ships no analytics SDK. These hooks let host apps observe the
/// flow (open/capture/select) and forward events to whatever analytics they
/// use, without coupling analytics to this package.
class MediaPickerCallbacks {
  /// Called when the camera screen is opened.
  final void Function()? onCameraOpened;

  /// Called when a capture begins.
  final void Function()? onCaptureStarted;

  /// Called when a capture completes successfully, with the raw result
  /// (before/after processing depending on stage — see docs).
  final void Function(MediaResult result)? onCaptureCompleted;

  /// Called when a capture fails.
  final void Function(Object error, StackTrace stackTrace)? onCaptureFailed;

  /// Called when the gallery picker is opened.
  final void Function()? onGalleryOpened;

  /// Called when one or more gallery items are selected.
  final void Function(List<MediaResult> results)? onGallerySelected;

  /// Called when the user cancels any flow.
  final void Function()? onCancelled;

  /// Creates a set of optional callbacks.
  const MediaPickerCallbacks({
    this.onCameraOpened,
    this.onCaptureStarted,
    this.onCaptureCompleted,
    this.onCaptureFailed,
    this.onGalleryOpened,
    this.onGallerySelected,
    this.onCancelled,
  });
}
