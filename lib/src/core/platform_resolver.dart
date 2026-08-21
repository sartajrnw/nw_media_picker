import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../adapters/android/android_camera_adapter.dart';
import '../adapters/camera_capture_adapter.dart';
import '../adapters/desktop/unsupported_camera_adapter.dart';
import '../adapters/gallery_picker_adapter.dart';
import '../adapters/ios/ios_camera_adapter.dart';
import '../gallery/image_picker_gallery_adapter.dart';
import '../logging/media_picker_logger.dart';
import '../models/camera_capture_config.dart';
import '../models/camera_enums.dart';
import '../models/media_capabilities.dart';
import '../models/media_picker_config.dart';
import '../models/media_result.dart';
import '../permissions/permission_service.dart';
import '../theme/media_picker_theme.dart';
import '../utils/media_temp_manager.dart';

/// Which physical camera lenses are present.
class AvailableLenses {
  /// Whether a front camera is present.
  final bool front;

  /// Whether a back camera is present.
  final bool back;

  /// Creates a lens availability record.
  const AvailableLenses({required this.front, required this.back});

  /// Whether any camera is present.
  bool get any => front || back;
}

/// Chooses platform-appropriate adapters and reports device capabilities.
///
/// This is the single place that knows about platform differences, so
/// consuming apps never need `if (Platform.isX)` checks.
class PlatformResolver {
  final MediaTempManager tempManager;
  final PermissionService permissionService;
  final MediaPickerLogger logger;

  /// The platform to resolve for. Defaults to the running platform but can be
  /// overridden in tests.
  final TargetPlatform platform;

  /// Reusable gallery adapter (stateless across platforms).
  final GalleryPickerAdapter galleryAdapter;

  AvailableLenses? _cachedLenses;

  /// Creates a platform resolver.
  PlatformResolver({
    required this.tempManager,
    required this.permissionService,
    required this.logger,
    TargetPlatform? platform,
    GalleryPickerAdapter? galleryAdapter,
  }) : platform = platform ?? defaultTargetPlatform,
       galleryAdapter =
           galleryAdapter ?? ImagePickerGalleryAdapter(logger: logger);

  /// Whether the current platform is a mobile platform.
  bool get isMobile =>
      platform == TargetPlatform.android || platform == TargetPlatform.iOS;

  /// Resolves the camera adapter for the current platform and config.
  ///
  /// * Android → in-app CameraX custom camera (never the OEM camera app).
  /// * iOS → native `image_picker` camera for [CameraExperience.platformDefault],
  ///   or the custom in-app camera for [CameraExperience.custom].
  /// * Desktop → an unsupported stub that fails gracefully.
  CameraCaptureAdapter resolveCameraAdapter({
    required CameraCaptureConfig config,
    required MediaPickerTheme theme,
    required bool showPreviewAfterCapture,
    Future<MediaResult?> Function()? onPickFromGallery,
    PreviewBuilder? previewBuilder,
  }) {
    switch (platform) {
      case TargetPlatform.android:
        return AndroidCameraCaptureAdapter(
          tempManager: tempManager,
          permissionService: permissionService,
          theme: theme,
          showPreviewAfterCapture: showPreviewAfterCapture,
          onPickFromGallery: onPickFromGallery,
          previewBuilder: previewBuilder,
          logger: logger,
        );
      case TargetPlatform.iOS:
        if (config.experience == CameraExperience.custom) {
          // The custom CameraX-backed page also runs on iOS.
          return AndroidCameraCaptureAdapter(
            tempManager: tempManager,
            permissionService: permissionService,
            theme: theme,
            showPreviewAfterCapture: showPreviewAfterCapture,
            onPickFromGallery: onPickFromGallery,
            previewBuilder: previewBuilder,
            logger: logger,
          );
        }
        return IosSystemCameraCaptureAdapter(logger: logger);
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return const UnsupportedCameraCaptureAdapter();
    }
  }

  /// Probes which camera lenses are available (mobile only; cached).
  Future<AvailableLenses> availableLenses() async {
    if (_cachedLenses != null) return _cachedLenses!;
    if (!isMobile) {
      return _cachedLenses = const AvailableLenses(front: false, back: false);
    }
    try {
      final cameras = await availableCameras();
      final front = cameras.any(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      final back = cameras.any(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      return _cachedLenses = AvailableLenses(front: front, back: back);
    } catch (e) {
      logger.warning('availableCameras failed during capability probe: $e');
      return _cachedLenses = const AvailableLenses(front: false, back: false);
    }
  }

  /// Computes the device's media capabilities.
  Future<MediaCapabilities> capabilities() async {
    final lenses = await availableLenses();
    final galleryAvailable = await galleryAdapter.isAvailable();
    return MediaCapabilities(
      camera: lenses.any,
      gallery: galleryAvailable,
      multipleGallerySelection: galleryAvailable,
      frontCamera: lenses.front,
      backCamera: lenses.back,
    );
  }
}
