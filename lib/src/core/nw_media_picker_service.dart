import 'package:flutter/material.dart';

import '../exceptions/media_picker_exception.dart';
import '../logging/media_picker_logger.dart';
import '../models/media_capabilities.dart';
import '../models/media_picker_callbacks.dart';
import '../models/media_picker_config.dart';
import '../models/media_result.dart';
import '../models/media_source.dart';
import '../permissions/permission_service.dart';
import '../processing/default_image_processor.dart';
import '../processing/image_processor.dart';
import '../theme/media_picker_theme.dart';
import '../utils/media_temp_manager.dart';
import '../widgets/media_source_sheet.dart';
import 'platform_resolver.dart';

/// The orchestration core behind the `NWMediaPicker` facade.
///
/// Instance-based to support dependency injection and testing; the facade
/// exposes a static convenience layer over a shared default instance.
///
/// Contract: **cancellation returns `null`**; genuine failures throw a
/// [MediaPickerException].
class NWMediaPickerService {
  final MediaPickerLogger _logger;
  final MediaTempManager _tempManager;
  final PermissionService _permissionService;
  final ImageProcessor _processor;
  final PlatformResolver _resolver;
  final MediaPickerCallbacks _callbacks;

  /// Creates a service. All dependencies are optional and default to the
  /// production implementations.
  factory NWMediaPickerService({
    MediaPickerLogger? logger,
    MediaTempManager? tempManager,
    PermissionService? permissionService,
    ImageProcessor? processor,
    PlatformResolver? resolver,
    MediaPickerCallbacks callbacks = const MediaPickerCallbacks(),
  }) {
    final log = logger ?? const DebugMediaPickerLogger();
    final temp = tempManager ?? MediaTempManager(logger: log);
    final perms = permissionService ?? PermissionService(logger: log);
    final proc =
        processor ?? DefaultImageProcessor(tempManager: temp, logger: log);
    final res =
        resolver ??
        PlatformResolver(
          tempManager: temp,
          permissionService: perms,
          logger: log,
        );
    return NWMediaPickerService._(
      logger: log,
      tempManager: temp,
      permissionService: perms,
      processor: proc,
      resolver: res,
      callbacks: callbacks,
    );
  }

  NWMediaPickerService._({
    required MediaPickerLogger logger,
    required MediaTempManager tempManager,
    required PermissionService permissionService,
    required ImageProcessor processor,
    required PlatformResolver resolver,
    required MediaPickerCallbacks callbacks,
  }) : _logger = logger,
       _tempManager = tempManager,
       _permissionService = permissionService,
       _processor = processor,
       _resolver = resolver,
       _callbacks = callbacks;

  MediaPickerTheme _themeFor(BuildContext context, MediaPickerConfig config) {
    return config.theme ?? MediaPickerTheme.fromTheme(Theme.of(context));
  }

  /// Picks a single image, showing a source chooser when multiple sources are
  /// enabled, or opening the single configured source directly.
  ///
  /// Returns `null` if the user cancels.
  Future<MediaResult?> pickImage(
    BuildContext context, {
    MediaPickerConfig config = const MediaPickerConfig(),
  }) async {
    config.validate();

    MediaSource? source;
    if (config.sources.length == 1) {
      source = config.sources.first;
    } else {
      source = await _chooseSource(context, config);
      if (source == null) {
        _callbacks.onCancelled?.call();
        return null; // dismissed chooser
      }
    }

    if (!context.mounted) return null;
    switch (source) {
      case MediaSource.camera:
        return camera(context, config: config);
      case MediaSource.gallery:
      case MediaSource.files:
        return gallery(config: config);
    }
  }

  Future<MediaSource?> _chooseSource(
    BuildContext context,
    MediaPickerConfig config,
  ) {
    if (config.sourcePickerBuilder != null) {
      return Navigator.of(context).push<MediaSource>(
        MaterialPageRoute<MediaSource>(
          fullscreenDialog: true,
          builder: (context) => config.sourcePickerBuilder!(
            context,
            config.sources,
            (source) => Navigator.of(context).pop(source),
            () => Navigator.of(context).pop(),
          ),
        ),
      );
    }
    return MediaSourceSheet.show(
      context,
      sources: config.sources,
      theme: config.theme,
    );
  }

  /// Opens the camera and returns a processed [MediaResult], or `null` on
  /// cancellation.
  Future<MediaResult?> camera(
    BuildContext context, {
    MediaPickerConfig config = const MediaPickerConfig(),
  }) async {
    config.validate();
    final theme = _themeFor(context, config);

    // Wire a gallery shortcut for the camera UI when the gallery source is
    // enabled, so permission/error fallbacks can offer it.
    Future<MediaResult?> Function()? galleryShortcut;
    if (config.hasGallery) {
      galleryShortcut = () => gallery(config: config);
    }

    final adapter = _resolver.resolveCameraAdapter(
      config: config.camera,
      theme: theme,
      showPreviewAfterCapture: config.showPreviewAfterCapture,
      onPickFromGallery: galleryShortcut,
      previewBuilder: config.previewBuilder,
    );

    _callbacks.onCameraOpened?.call();
    _callbacks.onCaptureStarted?.call();
    try {
      final raw = await adapter.capture(
        context: context,
        config: config.camera,
      );
      if (raw == null) {
        _callbacks.onCancelled?.call();
        return null;
      }
      // If the raw result already came from the gallery shortcut, it is a
      // gallery selection; process it the same way.
      final processed = await _processor.process(raw, config.processing);
      _callbacks.onCaptureCompleted?.call(processed);
      return processed;
    } on MediaPickerException catch (e, s) {
      _callbacks.onCaptureFailed?.call(e, s);
      rethrow;
    } catch (e, s) {
      _callbacks.onCaptureFailed?.call(e, s);
      _logger.error('Camera flow failed', error: e, stackTrace: s);
      throw MediaPickerException(
        MediaPickerErrorCode.captureFailed,
        'Camera capture failed: $e',
        cause: e,
        stackTrace: s,
      );
    }
  }

  /// Opens the gallery for a single selection and returns a processed
  /// [MediaResult], or `null` on cancellation.
  Future<MediaResult?> gallery({
    MediaPickerConfig config = const MediaPickerConfig(),
  }) async {
    config.validate();
    _callbacks.onGalleryOpened?.call();
    try {
      final raw = await _resolver.galleryAdapter.pickImage(
        config: config.gallery,
      );
      if (raw == null) {
        _callbacks.onCancelled?.call();
        return null;
      }
      final processed = await _processor.process(raw, config.processing);
      _callbacks.onGallerySelected?.call([processed]);
      return processed;
    } on MediaPickerException {
      rethrow;
    } catch (e, s) {
      _logger.error('Gallery flow failed', error: e, stackTrace: s);
      throw MediaPickerException(
        MediaPickerErrorCode.gallerySelectionFailed,
        'Gallery selection failed: $e',
        cause: e,
        stackTrace: s,
      );
    }
  }

  /// Opens the gallery for multiple selection and returns processed results.
  ///
  /// Returns an empty list if the user cancels.
  Future<List<MediaResult>> galleryMultiple({
    MediaPickerConfig config = const MediaPickerConfig(),
  }) async {
    config.validate();
    _callbacks.onGalleryOpened?.call();
    try {
      final effectiveGallery = config.gallery.allowMultiple
          ? config.gallery
          : config.gallery.copyWith(allowMultiple: true);
      final rawList = await _resolver.galleryAdapter.pickMultipleImages(
        config: effectiveGallery,
      );
      if (rawList.isEmpty) {
        _callbacks.onCancelled?.call();
        return const [];
      }
      final processed = <MediaResult>[];
      for (final raw in rawList) {
        processed.add(await _processor.process(raw, config.processing));
      }
      _callbacks.onGallerySelected?.call(processed);
      return processed;
    } on MediaPickerException {
      rethrow;
    } catch (e, s) {
      _logger.error('Multi gallery flow failed', error: e, stackTrace: s);
      throw MediaPickerException(
        MediaPickerErrorCode.gallerySelectionFailed,
        'Gallery selection failed: $e',
        cause: e,
        stackTrace: s,
      );
    }
  }

  /// Reports the device's media capabilities.
  Future<MediaCapabilities> capabilities() => _resolver.capabilities();

  /// The permission service, exposed for advanced apps that want to pre-check.
  PermissionService get permissions => _permissionService;

  /// Deletes all package-managed temporary files.
  Future<void> clearTemporaryFiles() => _tempManager.clear();

  /// Returns the total size of package temporary files in bytes.
  Future<int> getTemporaryCacheSize() => _tempManager.size();
}
