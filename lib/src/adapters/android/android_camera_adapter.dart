import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../camera/camera_page.dart';
import '../../logging/media_picker_logger.dart';
import '../../models/camera_capture_config.dart';
import '../../models/media_picker_config.dart';
import '../../models/media_result.dart';
import '../../permissions/permission_service.dart';
import '../../theme/media_picker_theme.dart';
import '../../utils/media_temp_manager.dart';
import '../camera_capture_adapter.dart';

/// Android camera adapter that presents the in-app CameraX camera UI.
///
/// It **never** launches the OEM/system camera app — avoiding the instability
/// seen on some Samsung/Xiaomi/Oppo/Vivo/Realme devices, which is the core
/// motivation for this package.
class AndroidCameraCaptureAdapter implements CameraCaptureAdapter {
  final MediaTempManager _tempManager;
  final PermissionService _permissionService;
  final MediaPickerLogger _logger;

  /// Visual theme for the camera UI.
  final MediaPickerTheme theme;

  /// Whether to show the in-app preview after capture.
  final bool showPreviewAfterCapture;

  /// Optional gallery shortcut used by the camera UI's gallery button and by
  /// the camera-error/permission fallbacks. Injected by the resolver so the UI
  /// can offer "Choose from Gallery" without coupling to the gallery adapter.
  final Future<MediaResult?> Function()? onPickFromGallery;

  /// Optional custom preview builder.
  final PreviewBuilder? previewBuilder;

  /// Creates the Android camera adapter.
  AndroidCameraCaptureAdapter({
    required MediaTempManager tempManager,
    required PermissionService permissionService,
    this.theme = const MediaPickerTheme(),
    this.showPreviewAfterCapture = true,
    this.onPickFromGallery,
    this.previewBuilder,
    MediaPickerLogger logger = const DebugMediaPickerLogger(),
  }) : _tempManager = tempManager,
       _permissionService = permissionService,
       _logger = logger;

  @override
  Future<MediaResult?> capture({
    required BuildContext context,
    required CameraCaptureConfig config,
  }) async {
    config.validate();
    if (!context.mounted) return null;
    _logger.debug('Presenting in-app camera page.');
    final navigator = Navigator.of(context, rootNavigator: true);
    return navigator.push<MediaResult?>(
      MaterialPageRoute<MediaResult?>(
        fullscreenDialog: true,
        builder: (context) => CameraPage(
          config: config,
          theme: theme,
          tempManager: _tempManager,
          permissionService: _permissionService,
          showPreviewAfterCapture: showPreviewAfterCapture,
          onPickFromGallery: onPickFromGallery,
          previewBuilder: previewBuilder,
          logger: _logger,
        ),
      ),
    );
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final cameras = await availableCameras();
      return cameras.isNotEmpty;
    } on CameraException catch (e) {
      _logger.warning('availableCameras failed: $e');
      return false;
    } catch (e) {
      _logger.warning('availableCameras failed: $e');
      return false;
    }
  }
}
