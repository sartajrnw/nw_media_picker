import 'package:flutter/widgets.dart';

import '../models/camera_capture_config.dart';
import '../models/media_result.dart';

/// Abstraction over "capture a photo with the camera".
///
/// Consuming apps never see which implementation is used (in-app CameraX on
/// Android, native `image_picker` on iOS, or an unsupported stub on desktop).
/// The returned [MediaResult] is **unprocessed** — the service applies the
/// image-processing pipeline afterward.
abstract interface class CameraCaptureAdapter {
  /// Opens the camera experience and returns the captured (raw) media.
  ///
  /// Returns `null` if the user cancels. Throws a `MediaPickerException` on
  /// genuine failure.
  Future<MediaResult?> capture({
    required BuildContext context,
    required CameraCaptureConfig config,
  });

  /// Whether camera capture is available on this platform/device.
  Future<bool> isAvailable();
}
