/// A generic, application-agnostic Flutter media picker.
///
/// Provides a unified API for capturing photos (in-app CameraX camera on
/// Android, native camera on iOS), selecting from the gallery/files, applying
/// configurable image optimization, and returning a normalized [MediaResult] —
/// all behind a stable public API that hides the underlying plugins.
///
/// ```dart
/// import 'package:nw_media_picker/nw_media_picker.dart';
///
/// final photo = await NWMediaPicker.pickImage(context);
/// if (photo != null) {
///   await repository.upload(photo.path);
/// }
/// ```
library;

// Facade + instance service.
export 'src/core/nw_media_picker.dart';
export 'src/core/nw_media_picker_service.dart' show NWMediaPickerService;
export 'src/core/platform_resolver.dart' show AvailableLenses;

// Models & enums.
export 'src/models/media_result.dart';
export 'src/models/media_source.dart';
export 'src/models/media_capabilities.dart';
export 'src/models/camera_enums.dart'
    show
        CameraLens,
        CameraResolution,
        CameraExperience,
        MediaFlashMode,
        CameraState;

// Configuration.
export 'src/models/media_picker_config.dart'
    show MediaPickerConfig, SourcePickerBuilder, PreviewBuilder;
export 'src/models/camera_capture_config.dart';
export 'src/models/gallery_picker_config.dart';
export 'src/models/image_processing_config.dart';
export 'src/models/media_picker_presets.dart';
export 'src/models/media_picker_callbacks.dart';

// Theme.
export 'src/theme/media_picker_theme.dart';

// Errors.
export 'src/exceptions/media_picker_exception.dart';

// Logging (so apps can plug in Crashlytics/Sentry/custom loggers).
export 'src/logging/media_picker_logger.dart';

// Permissions (normalized status enum for advanced pre-checks).
export 'src/permissions/permission_service.dart'
    show MediaPermissionStatus, MediaPermissionStatusX, PermissionService;

// Adapter interfaces (for advanced/custom implementations & DI).
export 'src/adapters/camera_capture_adapter.dart';
export 'src/adapters/gallery_picker_adapter.dart';
export 'src/adapters/image_cropper_adapter.dart';

// Processing interface (for custom processors).
export 'src/processing/image_processor.dart';
