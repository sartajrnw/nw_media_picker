import 'package:permission_handler/permission_handler.dart' as ph;

import '../logging/media_picker_logger.dart';

/// Package-level, normalized permission states.
///
/// Decoupled from `permission_handler`'s enum so the dependency is not exposed.
enum MediaPermissionStatus {
  /// State not yet known / not determined.
  unknown,

  /// Access granted (fully, or limited on iOS — see [isUsable]).
  granted,

  /// Access denied but may be requested again.
  denied,

  /// Access permanently denied; the user must change it in system Settings.
  permanentlyDenied,

  /// Access restricted by device policy (e.g. parental controls).
  restricted,
}

/// Whether a status permits proceeding.
extension MediaPermissionStatusX on MediaPermissionStatus {
  /// Whether the permission is usable for capturing/selecting media.
  bool get isUsable => this == MediaPermissionStatus.granted;

  /// Whether re-requesting is pointless (permanently denied / restricted).
  bool get isBlocked =>
      this == MediaPermissionStatus.permanentlyDenied ||
      this == MediaPermissionStatus.restricted;
}

/// Thin wrapper over `permission_handler` that:
/// * translates plugin statuses into [MediaPermissionStatus],
/// * never re-requests a permanently-denied permission, and
/// * exposes opening the app settings page.
class PermissionService {
  final MediaPickerLogger _logger;

  /// Creates a permission service.
  const PermissionService({
    MediaPickerLogger logger = const DebugMediaPickerLogger(),
  }) : _logger = logger;

  MediaPermissionStatus _map(ph.PermissionStatus s) {
    if (s.isGranted || s.isLimited) return MediaPermissionStatus.granted;
    if (s.isPermanentlyDenied) {
      return MediaPermissionStatus.permanentlyDenied;
    }
    if (s.isRestricted) return MediaPermissionStatus.restricted;
    if (s.isDenied) return MediaPermissionStatus.denied;
    return MediaPermissionStatus.unknown;
  }

  Future<MediaPermissionStatus> _ensure(ph.Permission permission) async {
    try {
      final current = await permission.status;
      final mapped = _map(current);

      // Never re-request a permanently denied / restricted permission.
      if (mapped == MediaPermissionStatus.permanentlyDenied ||
          mapped == MediaPermissionStatus.restricted ||
          mapped == MediaPermissionStatus.granted) {
        return mapped;
      }

      final requested = await permission.request();
      return _map(requested);
    } catch (e, s) {
      _logger.error('Permission request failed', error: e, stackTrace: s);
      return MediaPermissionStatus.unknown;
    }
  }

  /// Ensures camera permission, requesting it once if it is merely denied.
  Future<MediaPermissionStatus> ensureCamera() => _ensure(ph.Permission.camera);

  /// Ensures photo-library permission.
  ///
  /// Modern system galleries (Android Photo Picker, iOS `PHPicker`) often need
  /// **no** runtime permission — callers should prefer to let the system
  /// picker handle access and only fall back to this when direct library
  /// access is genuinely required.
  Future<MediaPermissionStatus> ensurePhotos() => _ensure(ph.Permission.photos);

  /// Reads camera permission status without requesting it.
  Future<MediaPermissionStatus> cameraStatus() async =>
      _map(await ph.Permission.camera.status);

  /// Opens the system app settings page. Returns whether it opened.
  Future<bool> openSettings() => ph.openAppSettings();
}
