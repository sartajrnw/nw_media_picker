import 'package:flutter/widgets.dart';

import '../logging/media_picker_logger.dart';
import '../models/media_capabilities.dart';
import '../models/media_picker_callbacks.dart';
import '../models/media_picker_config.dart';
import '../models/media_result.dart';
import 'nw_media_picker_service.dart';

/// The primary, ergonomic entry point to the package.
///
/// Static methods cover the common cases with minimal ceremony:
///
/// ```dart
/// final photo = await NWMediaPicker.pickImage(context);
/// if (photo != null) {
///   await repository.upload(photo.path);
/// }
/// ```
///
/// For dependency injection / testing, construct a [NWMediaPickerService]
/// directly and call the same-named instance methods. To customize the shared
/// static instance app-wide (e.g. inject a Crashlytics logger or analytics
/// callbacks), call [configure] once during startup.
///
/// ## Error contract
/// * User cancellation returns `null` (never throws).
/// * Genuine failures throw a `MediaPickerException` with a stable code.
class NWMediaPicker {
  const NWMediaPicker._();

  static NWMediaPickerService _instance = NWMediaPickerService();

  /// Replaces the shared service used by the static API.
  ///
  /// Call once at startup to inject a custom [logger] and/or analytics
  /// [callbacks]. Passing an explicit [service] overrides everything else.
  static void configure({
    NWMediaPickerService? service,
    MediaPickerLogger? logger,
    MediaPickerCallbacks callbacks = const MediaPickerCallbacks(),
  }) {
    _instance =
        service ?? NWMediaPickerService(logger: logger, callbacks: callbacks);
  }

  /// The shared service backing the static API (advanced use / testing).
  static NWMediaPickerService get instance => _instance;

  /// Picks a single image.
  ///
  /// Shows a source chooser when the config enables multiple sources, otherwise
  /// opens the single configured source directly. Applies the configured image
  /// processing and returns a normalized [MediaResult].
  ///
  /// Returns `null` when the user cancels. Throws `MediaPickerException` on
  /// failure.
  static Future<MediaResult?> pickImage(
    BuildContext context, {
    MediaPickerConfig config = const MediaPickerConfig(),
  }) => _instance.pickImage(context, config: config);

  /// Opens the camera directly and returns the captured, processed image.
  ///
  /// On Android this is the in-app CameraX camera (never the OEM camera app);
  /// on iOS it is the native camera by default. Returns `null` on cancel.
  static Future<MediaResult?> camera(
    BuildContext context, {
    MediaPickerConfig config = const MediaPickerConfig(),
  }) => _instance.camera(context, config: config);

  /// Opens the gallery for a single selection. Returns `null` on cancel.
  static Future<MediaResult?> gallery({
    MediaPickerConfig config = const MediaPickerConfig(),
  }) => _instance.gallery(config: config);

  /// Opens the gallery for multiple selection. Returns an empty list on cancel.
  static Future<List<MediaResult>> galleryMultiple({
    MediaPickerConfig config = const MediaPickerConfig(),
  }) => _instance.galleryMultiple(config: config);

  /// Reports the device's media capabilities (camera/gallery/lenses).
  static Future<MediaCapabilities> capabilities() => _instance.capabilities();

  /// Deletes all package-managed temporary files.
  ///
  /// Note: returned [MediaResult.path]s may live in temporary storage — persist
  /// the file in your app before clearing if you still need it.
  static Future<void> clearTemporaryFiles() => _instance.clearTemporaryFiles();

  /// Returns the total size, in bytes, of package temporary files.
  static Future<int> getTemporaryCacheSize() =>
      _instance.getTemporaryCacheSize();
}
