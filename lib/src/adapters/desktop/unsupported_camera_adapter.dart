import 'package:flutter/widgets.dart';

import '../../exceptions/media_picker_exception.dart';
import '../../models/camera_capture_config.dart';
import '../../models/media_result.dart';
import '../camera_capture_adapter.dart';

/// Camera adapter for platforms without supported camera capture (desktop).
///
/// [isAvailable] reports `false` so apps can query capabilities and hide the
/// camera option. If [capture] is called anyway it throws a normalized
/// `unsupportedPlatform` failure rather than crashing.
class UnsupportedCameraCaptureAdapter implements CameraCaptureAdapter {
  /// Creates the unsupported (desktop) camera adapter.
  const UnsupportedCameraCaptureAdapter();

  @override
  Future<MediaResult?> capture({
    required BuildContext context,
    required CameraCaptureConfig config,
  }) async {
    throw const MediaPickerException.unsupportedPlatform(
      'Camera capture is not supported on this platform.',
    );
  }

  @override
  Future<bool> isAvailable() async => false;
}
