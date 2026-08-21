import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import '../../exceptions/media_picker_exception.dart';
import '../../logging/media_picker_logger.dart';
import '../../models/camera_capture_config.dart';
import '../../models/camera_enums.dart';
import '../../models/media_result.dart';
import '../../models/media_source.dart';
import '../camera_capture_adapter.dart';
import '../xfile_mapper.dart';

/// iOS camera adapter using the native `image_picker` camera.
///
/// For standard capture flows the native Apple camera experience is the
/// intended `platformDefault`. The public API is unchanged, so a future release
/// can swap this for the custom `camera` implementation (`CameraExperience`)
/// without breaking consumers.
class IosSystemCameraCaptureAdapter implements CameraCaptureAdapter {
  final ImagePicker _picker;
  final MediaPickerLogger _logger;

  /// Creates the iOS camera adapter.
  IosSystemCameraCaptureAdapter({
    ImagePicker? picker,
    MediaPickerLogger logger = const DebugMediaPickerLogger(),
  }) : _picker = picker ?? ImagePicker(),
       _logger = logger;

  @override
  Future<MediaResult?> capture({
    required BuildContext context,
    required CameraCaptureConfig config,
  }) async {
    config.validate();
    try {
      _logger.debug('Opening native iOS camera.');
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: config.preferredLens == CameraLens.front
            ? CameraDevice.front
            : CameraDevice.rear,
      );
      if (file == null) return null; // cancelled
      return XFileMapper.toMediaResult(file, source: MediaSource.camera);
    } catch (e, s) {
      _logger.error('iOS camera capture failed', error: e, stackTrace: s);
      throw MediaPickerException(
        MediaPickerErrorCode.captureFailed,
        'Native camera capture failed: $e',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<bool> isAvailable() async => true;
}
