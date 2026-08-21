import 'package:image_cropper/image_cropper.dart';

import '../../exceptions/media_picker_exception.dart';
import '../../logging/media_picker_logger.dart';
import '../../models/interactive_crop_config.dart';
import '../../theme/media_picker_theme.dart';
import '../image_cropper_adapter.dart';

/// [ImageCropperAdapter] backed by the `image_cropper` plugin (UCrop on
/// Android, TOCropViewController on iOS).
///
/// Colors omitted from the [InteractiveCropConfig] fall back to [_theme] so the
/// crop editor visually matches the host application.
///
/// > **Android setup:** the host app must register `UCropActivity` in its
/// > `AndroidManifest.xml` (see the package README). Without it the editor
/// > fails to launch.
class ImageCropperCropAdapter implements ImageCropperAdapter {
  final MediaPickerTheme _theme;
  final MediaPickerLogger _logger;
  final ImageCropper _cropper;

  /// Creates the plugin-backed cropper. [cropper] is injectable for testing.
  ImageCropperCropAdapter({
    required MediaPickerTheme theme,
    MediaPickerLogger logger = const DebugMediaPickerLogger(),
    ImageCropper? cropper,
  }) : _theme = theme,
       _logger = logger,
       _cropper = cropper ?? ImageCropper();

  @override
  Future<String?> crop({
    required String imagePath,
    required InteractiveCropConfig config,
  }) async {
    config.validate();
    try {
      final cropped = await _cropper.cropImage(
        sourcePath: imagePath,
        aspectRatio: config.aspectRatio == null
            ? null
            : CropAspectRatio(ratioX: config.aspectRatio!, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: config.compressQuality,
        uiSettings: [
          _androidSettings(config),
          _iosSettings(config),
        ],
      );
      // A null result means the user cancelled the editor.
      return cropped?.path;
    } catch (e, s) {
      _logger.error('Interactive crop failed', error: e, stackTrace: s);
      throw MediaPickerException(
        MediaPickerErrorCode.processingFailed,
        'Interactive crop failed: $e',
        cause: e,
        stackTrace: s,
      );
    }
  }

  AndroidUiSettings _androidSettings(InteractiveCropConfig config) {
    return AndroidUiSettings(
      toolbarTitle: config.toolbarTitle ?? 'Crop',
      toolbarColor: config.toolbarColor ?? _theme.primaryColor,
      toolbarWidgetColor: config.toolbarWidgetColor ?? _theme.backgroundColor,
      backgroundColor: config.backgroundColor ?? _theme.backgroundColor,
      activeControlsWidgetColor:
          config.activeControlsColor ?? _theme.primaryColor,
      cropStyle: config.shape == CropShape.oval
          ? CropStyle.circle
          : CropStyle.rectangle,
      lockAspectRatio: config.lockAspectRatio,
      hideBottomControls: config.hideBottomControls,
      showCropGrid: config.showGrid,
      aspectRatioPresets: _presets(config),
    );
  }

  IOSUiSettings _iosSettings(InteractiveCropConfig config) {
    return IOSUiSettings(
      title: config.toolbarTitle ?? 'Crop',
      cropStyle: config.shape == CropShape.oval
          ? CropStyle.circle
          : CropStyle.rectangle,
      aspectRatioLockEnabled: config.lockAspectRatio,
      aspectRatioPickerButtonHidden:
          config.lockAspectRatio || !config.showAspectRatioPresets,
      resetAspectRatioEnabled: !config.lockAspectRatio,
      aspectRatioPresets: _presets(config),
    );
  }

  /// The preset list to expose. When the ratio is locked or presets are
  /// disabled there is nothing to choose from, so an empty list is returned.
  List<CropAspectRatioPreset> _presets(InteractiveCropConfig config) {
    if (config.lockAspectRatio || !config.showAspectRatioPresets) {
      return const [];
    }
    return const [
      CropAspectRatioPreset.original,
      CropAspectRatioPreset.square,
      CropAspectRatioPreset.ratio3x2,
      CropAspectRatioPreset.ratio4x3,
      CropAspectRatioPreset.ratio16x9,
    ];
  }
}
