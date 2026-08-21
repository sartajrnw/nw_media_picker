# Build a Production-Grade Generic Flutter Media Picker Package

You are a senior Flutter package engineer. Build a reusable, production-grade Flutter package for capturing and selecting images across multiple Flutter applications.

The package must be generic and application-agnostic. It will initially be used across multiple mobile and desktop applications, but it must not contain any application-specific business logic, API logic, Firebase logic, user IDs, shop IDs, product IDs, or backend integration.

The package should provide a unified API for:

* Taking photos
* Selecting photos from gallery/files
* Applying configurable image optimization
* Handling platform-specific implementations
* Returning a normalized result object
* Handling camera lifecycle safely
* Recovering gracefully from failures
* Supporting future extensions such as crop, video, multi-select, document capture, and OCR

The main motivation for this package is reliability.

The current implementation uses `image_picker` with `ImageSource.camera`. On some Android devices, the external/OEM system camera application crashes or fails to return correctly. Therefore, the new package must avoid using the external Android camera app for capture.

---

# 1. Package Name

Use:

```text
nw_media_picker
```

The package should expose a clean public API while hiding implementation details inside `lib/src`.

Expected package structure:

```text
nw_media_picker/
│
├── lib/
│   ├── nw_media_picker.dart
│   │
│   └── src/
│       ├── camera/
│       ├── gallery/
│       ├── adapters/
│       ├── processing/
│       ├── permissions/
│       ├── models/
│       ├── widgets/
│       ├── theme/
│       ├── utils/
│       └── exceptions/
│
├── example/
├── test/
├── integration_test/
├── pubspec.yaml
├── CHANGELOG.md
├── README.md
└── LICENSE
```

Do not expose internal implementation files unnecessarily.

Applications should normally only need:

```dart
import 'package:nw_media_picker/nw_media_picker.dart';
```

---

# 2. Core Platform Strategy

Implement different camera behavior depending on the platform.

## Android

For camera capture:

```text
Use Flutter's official `camera` package
↓
Use the endorsed CameraX Android implementation
↓
Display an in-app custom camera UI
↓
Do NOT launch the OEM/system camera application
```

For gallery selection:

```text
Use image_picker
```

The purpose of this architecture is to avoid instability caused by Samsung/Xiaomi/Oppo/Vivo/Realme/etc. external camera applications.

---

## iOS

For normal camera capture:

```text
Use image_picker with ImageSource.camera
```

The native Apple camera experience is acceptable for standard capture flows.

For gallery:

```text
Use image_picker
```

However, architect the package so that iOS camera capture can later be changed from `image_picker` to the custom `camera` implementation without changing the package's public API.

---

## Windows/Desktop

Initial version:

```text
Camera capture:
Unsupported

Gallery/file selection:
Supported
```

The package must detect available capabilities instead of forcing applications to write platform-specific checks everywhere.

Future Windows camera support should be possible through another adapter.

---

# 3. Most Important Architectural Requirement

The calling application must never need to know whether the package internally uses:

```text
camera
CameraX
image_picker
file_selector
AVFoundation
another future implementation
```

The public API must remain stable.

Use an adapter-based architecture.

For example:

```dart
abstract interface class CameraCaptureAdapter {
  Future<MediaResult?> capture({
    required BuildContext context,
    required CameraCaptureConfig config,
  });

  Future<bool> isAvailable();
}
```

Possible implementations:

```text
CameraCaptureAdapter

├── AndroidCameraCaptureAdapter
│      └── camera package / CameraX
│
├── IosSystemCameraCaptureAdapter
│      └── image_picker
│
└── UnsupportedCameraCaptureAdapter
       └── desktop fallback
```

Also create a gallery adapter:

```dart
abstract interface class GalleryPickerAdapter {
  Future<MediaResult?> pickImage({
    required GalleryPickerConfig config,
  });

  Future<List<MediaResult>> pickMultipleImages({
    required GalleryPickerConfig config,
  });
}
```

For v1, multi-select can either be implemented or prepared structurally, but the primary requirement is single-image selection.

---

# 4. Public API

The API should be extremely simple for the consuming application.

Target usage:

```dart
final result = await NWMediaPicker.pickImage(
  context,
);
```

Another example:

```dart
final result = await NWMediaPicker.pickImage(
  context,
  config: const MediaPickerConfig(
    sources: [
      MediaSource.camera,
      MediaSource.gallery,
    ],
  ),
);
```

Direct camera:

```dart
final result = await NWMediaPicker.camera(
  context,
);
```

Direct gallery:

```dart
final result = await NWMediaPicker.gallery();
```

Custom configuration:

```dart
final result = await NWMediaPicker.pickImage(
  context,
  config: const MediaPickerConfig(
    camera: CameraCaptureConfig(
      preferredLens: CameraLens.front,
      allowCameraSwitch: true,
      allowFlash: true,
      allowZoom: true,
      enableTapToFocus: true,
    ),
    processing: ImageProcessingConfig(
      quality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    ),
  ),
);
```

Avoid forcing developers to create service instances unless there is a strong architectural reason.

If instance-based API is useful for dependency injection/testing, support both patterns cleanly.

For example:

```dart
final picker = NWMediaPicker();

final result = await picker.pickImage(...);
```

But do not make the API unnecessarily complicated.

---

# 5. MediaResult

Do not return `XFile` directly as the primary result.

Create a normalized result model owned by this package.

Example:

```dart
class MediaResult {
  final String path;
  final MediaSource source;

  final String? mimeType;

  final int? width;
  final int? height;

  final int? sizeBytes;

  final String? originalFileName;

  final DateTime createdAt;

  const MediaResult({
    required this.path,
    required this.source,
    required this.createdAt,
    this.mimeType,
    this.width,
    this.height,
    this.sizeBytes,
    this.originalFileName,
  });
}
```

Optional helpers:

```dart
File get file => File(path);

bool get exists;

double? get sizeMB;

bool get isCameraCapture;
bool get isGallerySelection;
```

Be careful with `dart:io` exposure if cross-platform support makes this problematic.

If necessary, expose `path` and keep `File` helpers outside web-compatible APIs.

---

# 6. Source Enum

Create:

```dart
enum MediaSource {
  camera,
  gallery,
  files,
}
```

Do not reuse `ImageSource` directly in the package's public API.

---

# 7. Media Picker Config

Create a high-level configuration object:

```dart
class MediaPickerConfig {
  final List<MediaSource> sources;

  final CameraCaptureConfig camera;

  final GalleryPickerConfig gallery;

  final ImageProcessingConfig processing;

  final MediaPickerTheme? theme;

  final bool showPreviewAfterCapture;

  const MediaPickerConfig({
    this.sources = const [
      MediaSource.camera,
      MediaSource.gallery,
    ],
    this.camera = const CameraCaptureConfig(),
    this.gallery = const GalleryPickerConfig(),
    this.processing = const ImageProcessingConfig(),
    this.theme,
    this.showPreviewAfterCapture = true,
  });
}
```

Use immutable configuration objects.

Prefer `const` constructors wherever possible.

---

# 8. Camera Configuration

Create a package-level enum rather than exposing the camera package's enum.

Example:

```dart
enum CameraLens {
  front,
  back,
}
```

Configuration:

```dart
class CameraCaptureConfig {
  final CameraLens preferredLens;

  final bool allowCameraSwitch;

  final bool allowFlash;

  final bool allowZoom;

  final bool enableTapToFocus;

  final bool enableExposureControl;

  final bool enablePinchToZoom;

  final double? minimumZoom;

  final double? maximumZoom;

  final CameraResolution resolution;

  const CameraCaptureConfig({
    this.preferredLens = CameraLens.back,
    this.allowCameraSwitch = true,
    this.allowFlash = true,
    this.allowZoom = true,
    this.enableTapToFocus = true,
    this.enableExposureControl = false,
    this.enablePinchToZoom = true,
    this.minimumZoom,
    this.maximumZoom,
    this.resolution = CameraResolution.high,
  });
}
```

Package-level resolution:

```dart
enum CameraResolution {
  low,
  medium,
  high,
  veryHigh,
  max,
}
```

Internally map this to `ResolutionPreset`.

Do not leak `ResolutionPreset` through the public API.

---

# 9. Camera Experience Mode

Prepare the package for two possible camera experiences.

Create:

```dart
enum CameraExperience {
  platformDefault,
  custom,
}
```

Behavior:

### Android

```text
platformDefault → custom CameraX implementation anyway
custom          → custom CameraX implementation
```

Do not use external Android system camera for either mode in v1.

### iOS

```text
platformDefault → image_picker native camera
custom          → Flutter camera UI
```

It is acceptable if `custom` on iOS is implemented in v1 or prepared structurally for the next release.

Prefer implementing it if it does not substantially complicate the package.

This enables future specialized experiences such as document capture without redesigning the public API.

---

# 10. Gallery Configuration

Create:

```dart
class GalleryPickerConfig {
  final bool allowMultiple;

  final int? maxSelection;

  const GalleryPickerConfig({
    this.allowMultiple = false,
    this.maxSelection,
  });
}
```

For v1, single-image gallery selection is mandatory.

Multi-selection can be implemented if straightforward.

---

# 11. Image Processing Configuration

Create:

```dart
class ImageProcessingConfig {
  final int quality;

  final int? maxWidth;

  final int? maxHeight;

  final double? cropAspectRatio;

  final bool preserveMetadata;

  final bool correctOrientation;

  final bool stripUnnecessaryMetadata;

  const ImageProcessingConfig({
    this.quality = 85,
    this.maxWidth,
    this.maxHeight,
    this.cropAspectRatio,
    this.preserveMetadata = false,
    this.correctOrientation = true,
    this.stripUnnecessaryMetadata = true,
  });
}
```

Validate:

```text
quality must be between 1 and 100
dimensions must be > 0
crop ratio must be > 0
```

Do not perform unnecessary image conversion when no processing is required.

---

# 12. Image Processing Pipeline

After camera or gallery selection:

```text
Original Image
      ↓
Read metadata
      ↓
Correct orientation if needed
      ↓
Resize if needed
      ↓
Optional crop
      ↓
Compress
      ↓
Write optimized output
      ↓
Collect metadata
      ↓
Return MediaResult
```

The processing layer must not be coupled to the camera/gallery implementation.

Create something similar to:

```dart
abstract interface class ImageProcessor {
  Future<MediaResult> process(
    MediaResult input,
    ImageProcessingConfig config,
  );
}
```

Ensure the implementation does not cause large memory spikes for high-resolution images.

Be particularly careful with 12MP/48MP camera images.

Prefer efficient libraries and techniques.

Do not decode enormous images at full resolution unnecessarily if it can be avoided.

---

# 13. Default Image Optimization

Provide sensible defaults suitable for uploading photos from mobile apps.

Recommended defaults:

```text
quality: 85

maximum dimension:
around 1600–1920 px where appropriate
```

Do not forcibly convert every image if it is already under limits.

For example:

```text
Original:
4032 × 3024
6.5 MB

↓

Processed:
1600 × 1200
roughly 300 KB – 1 MB
depending on content
```

The exact file size does not need to be guaranteed.

---

# 14. Camera UI — Android Custom Camera

Build a production-quality but minimal custom camera screen.

Basic layout:

```text
┌────────────────────────────────────┐
│  X                         Flash   │
│                                    │
│                                    │
│                                    │
│          CAMERA PREVIEW            │
│                                    │
│                                    │
│                                    │
│                                    │
│                                    │
│               ◯                    │
│                                    │
│ Gallery                 Switch     │
└────────────────────────────────────┘
```

Required controls:

* Close
* Capture
* Flash
* Front/back camera switch
* Gallery shortcut
* Pinch-to-zoom
* Tap-to-focus

Optional:

* exposure control
* current zoom indicator

Use `SafeArea`.

The preview must maintain correct aspect ratio and must not stretch.

The camera UI should handle different phone aspect ratios correctly.

---

# 15. Camera Capture State

Implement an explicit internal state model.

For example:

```dart
enum CameraState {
  initializing,
  ready,
  capturing,
  processing,
  error,
  permissionDenied,
}
```

Prevent duplicate capture.

Example logic:

```dart
if (_isCapturing) {
  return;
}

_isCapturing = true;

try {
  final photo = await controller.takePicture();
} finally {
  _isCapturing = false;
}
```

The capture button should visibly disable while a capture is happening.

---

# 16. Camera Initialization

Camera initialization must be robust.

Expected sequence:

```text
Find available cameras
      ↓
Select configured preferred camera
      ↓
Initialize controller
      ↓
Check capabilities
      ↓
Set defaults
      ↓
Render preview
```

If preferred camera is unavailable:

```text
front requested
↓
front unavailable
↓
fallback to back
```

If there is only one camera:

```text
hide camera-switch control
```

---

# 17. Resolution Fallback

If initializing with the requested resolution fails, automatically retry with lower resolutions.

Example:

```text
veryHigh
 ↓ fails

high
 ↓ fails

medium
 ↓ fails

show recoverable camera error
```

Do not crash the page.

Log the failure internally.

---

# 18. Camera Lifecycle — CRITICAL

Camera lifecycle handling is a major requirement.

The package must safely handle:

```text
Camera Screen Open
      ↓
App moves to background
      ↓
Release or pause camera resources
      ↓
App returns foreground
      ↓
Reinitialize camera
      ↓
Restore usable UI
```

Handle at least:

```dart
AppLifecycleState.inactive
AppLifecycleState.paused
AppLifecycleState.resumed
AppLifecycleState.detached
```

The implementation must:

* avoid accessing disposed controllers
* avoid duplicate initialization
* avoid multiple controllers existing simultaneously
* avoid camera resource leaks
* recover after phone calls
* recover after app switching
* recover after permission changes where possible

Create explicit lifecycle handling inside the camera feature rather than expecting each consuming app to implement it.

---

# 19. Controller Safety

Never blindly access a camera controller.

Always guard operations.

Conceptually:

```dart
if (_controller == null) return;

if (!_controller!.value.isInitialized) return;

if (_isDisposing) return;
```

Use mounted checks before updating widget state.

Do not call:

```dart
setState(...)
```

after disposal.

---

# 20. Flash Support

Support:

```dart
enum MediaFlashMode {
  off,
  auto,
  on,
  torch,
}
```

Only display supported options.

Internally map this to the `camera` package flash mode.

Do not expose the underlying plugin enum.

Remember the current flash state while the camera screen remains open.

---

# 21. Zoom

Support pinch zoom.

Read actual device zoom limits:

```dart
getMinZoomLevel()
getMaxZoomLevel()
```

Clamp zoom appropriately.

Do not assume every camera supports identical zoom ranges.

Throttle updates if necessary to avoid excessive controller calls.

---

# 22. Tap to Focus

Implement tap-to-focus on the preview.

Convert tap coordinates to normalized camera coordinates correctly.

Optionally display a short focus indicator:

```text
┌────┐
│    │
└────┘
```

The indicator can fade after approximately one second.

Do not make this animation elaborate.

---

# 23. Permissions

Handle permissions gracefully.

Potential states:

```text
unknown
granted
denied
permanentlyDenied
restricted
```

Do not cause application crashes if permission is denied.

Show appropriate UI.

Example:

```text
Camera access is required to take a photo.

[Open Settings]
[Choose from Gallery]
[Cancel]
```

Do not repeatedly request permanently denied permissions.

For gallery permissions, follow modern platform-specific behavior.

Avoid requesting permissions that the underlying system picker does not require.

---

# 24. Capability API

Applications should be able to query available features.

Create:

```dart
class MediaCapabilities {
  final bool camera;
  final bool gallery;
  final bool multipleGallerySelection;
  final bool frontCamera;
  final bool backCamera;

  const MediaCapabilities({
    required this.camera,
    required this.gallery,
    required this.multipleGallerySelection,
    required this.frontCamera,
    required this.backCamera,
  });
}
```

Usage:

```dart
final capabilities =
    await NWMediaPicker.capabilities();
```

Example Android result:

```dart
MediaCapabilities(
  camera: true,
  gallery: true,
  multipleGallerySelection: true,
  frontCamera: true,
  backCamera: true,
)
```

Example Windows result:

```dart
MediaCapabilities(
  camera: false,
  gallery: true,
  multipleGallerySelection: true,
  frontCamera: false,
  backCamera: false,
)
```

The consuming application should not need:

```dart
if (Platform.isWindows) ...
```

for basic source selection.

---

# 25. Source Picker UI

When both camera and gallery are enabled, provide a reusable source chooser.

Example:

```text
Add Photo

Take Photo
Choose from Gallery

Cancel
```

Make this customizable.

API:

```dart
final result = await NWMediaPicker.pickImage(
  context,
);
```

should automatically show the chooser when multiple sources are configured.

If only one source is configured, open it directly.

---

# 26. Preview After Capture

Provide an optional preview screen.

Example:

```text
┌──────────────────────────────┐
│ X                            │
│                              │
│                              │
│           PHOTO              │
│                              │
│                              │
│                              │
│  Retake              Use    │
└──────────────────────────────┘
```

Configuration:

```dart
showPreviewAfterCapture: true
```

Behavior:

```text
Capture
 ↓
Preview
 ↓
Retake OR Use Photo
```

If user chooses retake:

```text
Return to active camera
```

If user chooses Use:

```text
Process image
↓
Return MediaResult
```

---

# 27. Optional Crop Architecture

Crop does not need to be deeply coupled to capture.

Structure it as:

```text
Capture
↓
Preview
↓
Optional crop
↓
Image processor
```

If cropping is enabled via:

```dart
cropAspectRatio: 1
```

provide an appropriate crop stage.

Do not make crop mandatory.

If no cropping dependency is chosen initially, create an abstraction such as:

```dart
abstract interface class ImageCropperAdapter {
  Future<String?> crop({
    required String imagePath,
    required double? aspectRatio,
  });
}
```

This allows the crop implementation to be introduced or changed later.

---

# 28. Theme

Do not hardcode any application's brand into the package.

Create:

```dart
class MediaPickerTheme {
  final Color primaryColor;
  final Color backgroundColor;
  final Color foregroundColor;

  final Color? overlayColor;

  final double captureButtonSize;

  const MediaPickerTheme({
    this.primaryColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.foregroundColor = Colors.white,
    this.overlayColor,
    this.captureButtonSize = 72,
  });
}
```

Applications can supply:

```dart
MediaPickerTheme(
  primaryColor: Color(0xFFD4212A),
)
```

but the package itself must remain generic.

Where reasonable, inherit from the host application's `ThemeData`.

---

# 29. Error Model

Do not expose raw exceptions throughout the consuming apps.

Create package-level exceptions.

For example:

```dart
enum MediaPickerErrorCode {
  permissionDenied,
  permissionPermanentlyDenied,
  cameraUnavailable,
  cameraInitializationFailed,
  captureFailed,
  galleryUnavailable,
  gallerySelectionFailed,
  processingFailed,
  unsupportedPlatform,
  cancelled,
  unknown,
}
```

Create:

```dart
class MediaPickerException implements Exception {
  final MediaPickerErrorCode code;
  final String message;
  final Object? cause;
}
```

Cancellation should preferably return:

```dart
null
```

instead of being treated as an error.

Actual failures should throw a normalized package exception or return a typed failure model.

Choose one consistent pattern and document it.

---

# 30. Logging

Do not directly print logs everywhere.

Create a logger abstraction.

For example:

```dart
abstract interface class MediaPickerLogger {
  void debug(String message);
  void info(String message);
  void warning(String message);
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });
}
```

Default:

```text
No-op or debugPrint in debug mode
```

Allow consuming applications to supply:

```text
Firebase Crashlytics logger
Sentry logger
custom logger
```

The package should never depend directly on Crashlytics or Sentry.

---

# 31. Analytics Hooks

Do not include analytics SDKs.

But optionally expose callbacks such as:

```dart
MediaPickerCallbacks(
  onCameraOpened: ...,
  onCaptureStarted: ...,
  onCaptureCompleted: ...,
  onCaptureFailed: ...,
  onGalleryOpened: ...,
  onGallerySelected: ...,
)
```

This allows host apps to track behavior without coupling analytics to the package.

---

# 32. Temporary File Management

The package must intentionally manage temporary files.

Do not let captured images accumulate indefinitely.

Create a predictable package-specific temporary directory.

Example:

```text
/cache/nw_media_picker/
```

Provide:

```dart
Future<void> NWMediaPicker.clearTemporaryFiles();
```

Potentially also:

```dart
Future<int> NWMediaPicker.getTemporaryCacheSize();
```

Do not delete the final result before the caller has had a chance to upload/copy it.

Document that returned paths may live in temporary storage and should be persisted by the application if long-term storage is required.

---

# 33. File Naming

Use unique names.

Example:

```text
nw_media_20260821_114530_123456.jpg
```

or UUID-based names.

Never overwrite previous captures unintentionally.

---

# 34. EXIF / Orientation

Ensure photos do not unexpectedly appear sideways.

Handle EXIF orientation properly.

Test:

```text
portrait capture
landscape capture
device rotated left
device rotated right
front camera
back camera
```

Do not blindly strip orientation metadata before applying the orientation correction.

---

# 35. Front Camera Mirroring

Test front-camera output carefully.

The preview can be mirrored if expected, but the final saved file should follow a predictable documented behavior.

Avoid accidental horizontal reversal if that differs from native expectations.

---

# 36. Memory Safety

This package will be used for product/shop/profile photography and may receive very large camera files.

Avoid loading unnecessary duplicate copies of an image into memory.

Do not repeatedly convert:

```text
File
→ bytes
→ decoded image
→ bytes
→ decoded image
```

unless needed.

Use asynchronous processing.

Avoid blocking the main UI thread for large image operations where possible.

If isolates are useful for processing, use them where appropriate.

---

# 37. Concurrency

Prevent:

```text
Two camera screens
Two simultaneous captures
Multiple processing jobs for the same media
```

Handle rapid button presses safely.

Use guards/mutex-like state where necessary.

---

# 38. Common Usage Presets

Do NOT hardcode business features.

However, create generic reusable presets.

For example:

```dart
class MediaPickerPresets {
  static const profilePhoto = MediaPickerConfig(...);

  static const squareImage = MediaPickerConfig(...);

  static const productPhoto = MediaPickerConfig(...);

  static const highQualityPhoto = MediaPickerConfig(...);

  static const documentPhoto = MediaPickerConfig(...);
}
```

These names should remain generic.

Possible configurations:

## Profile Photo

```text
front camera preferred
square crop
max dimension ~1000
quality ~85
```

## Product Photo

```text
back camera
square crop optional
max dimension ~1600
quality ~85
```

## High Quality

```text
back camera
no forced crop
max dimension ~1920–2200
quality ~90
```

## Document

```text
back camera
higher resolution
quality ~90
no aggressive compression
```

These are convenience presets only.

The package must work fully without using presets.

---

# 39. Example Application

Create a complete example app demonstrating:

```text
1. Pick photo
2. Camera only
3. Gallery only
4. Profile preset
5. Product preset
6. Custom theme
7. Permission handling
8. Capability check
9. Display returned metadata
10. Clear temporary files
```

Example home screen:

```text
NW Media Picker

[Pick Image]

[Take Photo]

[Choose Gallery Image]

[Profile Example]

[Product Example]

[Capability Test]

[Clear Cache]
```

When an image is returned, display:

```text
Preview

Source: camera
Width: 1600
Height: 1200
Size: 532 KB
Path: ...
```

---

# 40. README

Create a strong README with:

## Installation

Example:

```yaml
dependencies:
  nw_media_picker:
    git:
      url: <private-repository-url>
      ref: v1.0.0
```

Do not hardcode a real repository URL if none is supplied.

## Android setup

Include required permissions/configuration.

## iOS setup

Explain `Info.plist` requirements.

At minimum:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to take photos.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is required to select photos.</string>
```

Only require permissions actually needed by the chosen implementation.

## Basic examples

```dart
final image = await NWMediaPicker.pickImage(context);
```

## Camera example

```dart
final image = await NWMediaPicker.camera(context);
```

## Gallery example

```dart
final image = await NWMediaPicker.gallery();
```

## Custom configuration

Provide a complete example.

## Error handling

Show normalized exception handling.

## Lifecycle behavior

Document that camera lifecycle is handled by the package.

## Temporary files

Document file lifetime and persistence expectations.

---

# 41. Testing

Create meaningful tests.

## Unit Tests

Test:

```text
config validation

quality bounds

dimension validation

adapter selection

platform capability mapping

error normalization

file naming

result metadata

preset configurations
```

---

# 42. Widget Tests

Test:

```text
source picker UI

camera loading UI

permission denied UI

camera error UI

preview screen

retake behavior

capture button disabled state

theme application
```

Mock camera behavior where required.

---

# 43. Integration Tests

Where feasible, add integration tests for:

```text
camera initialization

camera lifecycle

capture

background/foreground recovery

gallery selection

processing
```

Device-specific camera tests may require manual QA, so also create a manual QA checklist.

---

# 44. Android Device QA Checklist

The primary motivation of this package is Android camera reliability.

Test on as many of these as possible:

```text
Samsung
Xiaomi / Redmi
Oppo
Vivo
Realme
OnePlus
Motorola
Pixel
Nothing
```

Test:

```text
Open camera

Take photo

Take 10 photos sequentially

Rapidly open/close camera

Switch front/back repeatedly

Enable/disable flash

Pinch zoom

Tap focus

Rotate phone

Background app while camera is open

Return after 5 seconds

Return after 1 minute

Lock/unlock screen

Receive phone call

Deny camera permission

Permanently deny camera permission

Change permission from Settings

Low-memory conditions

Take large-resolution photo

Cancel camera

Open gallery from camera

Capture after gallery cancellation
```

No scenario should crash the consuming application.

---

# 45. iOS QA

Test:

```text
Take photo using native camera picker

Cancel camera

Front camera preference

Back camera preference

Gallery pick

Cancel gallery

Photo permissions

Limited photo access

Background/foreground behavior

Large HEIC images

Portrait/landscape

Image orientation
```

Ensure HEIC input can be handled correctly by image processing.

If output is converted to JPEG, document this behavior.

---

# 46. Windows QA

Initial expectations:

```text
Camera capability = false

Gallery/file capability = true

Choosing image works

Unsupported camera calls return a normalized failure rather than crashing
```

---

# 47. Public API Stability

Treat the public API as a reusable library contract.

Do not expose:

```text
CameraController
XFile
ResolutionPreset
FlashMode
ImagePicker
platform plugin classes
```

unless there is an extremely strong reason.

The package should translate them into its own models.

This allows us to change dependencies later without breaking all consuming applications.

---

# 48. Dependency Philosophy

Use mature, actively maintained Flutter packages.

Primary expected dependencies:

```text
camera
image_picker
```

Potentially:

```text
path_provider
path
mime
image processing/compression package
permission handling package only if truly needed
```

Before adding dependencies:

1. Check whether Flutter/platform APIs already provide the functionality.
2. Avoid dependencies that duplicate each other.
3. Avoid abandoned packages.
4. Avoid packages requiring unnecessary native setup.
5. Keep dependency count reasonable.

Use current stable compatible versions rather than blindly copying versions from this prompt.

---

# 49. Separation of Concerns

The package must contain:

```text
Camera capture
Gallery selection
Permissions
Image processing
Media metadata
Picker UI
Preview UI
Error handling
Lifecycle handling
Temporary files
```

The package must NOT contain:

```text
HTTP uploads
Dio
Retrofit
Firebase
Firebase Storage
Shop IDs
Product IDs
User IDs
Authentication
Backend APIs
Business models
Order logic
Feature-specific UI
Analytics SDKs
Crash reporting SDKs
```

Correct flow:

```dart
final media = await NWMediaPicker.pickImage(context);

if (media != null) {
  await myRepository.uploadImage(media.path);
}
```

The package ends at:

```text
MediaResult
```

---

# 50. Code Quality

Use:

```text
sound null safety
strict lint rules
immutable models
const constructors
small focused classes
dependency inversion
clear interfaces
proper documentation
```

Avoid:

```text
massive classes
god services
static global mutable state
hardcoded platform logic scattered everywhere
unnecessary singletons
business-specific code
duplicated error handling
```

Use composition over inheritance where appropriate.

---

# 51. Documentation Comments

All public classes and methods must have Dart documentation.

Example:

```dart
/// Opens the configured camera experience and returns the captured image.
///
/// Returns `null` when the user cancels the operation.
///
/// Throws [MediaPickerException] when capture fails.
Future<MediaResult?> camera(...);
```

---

# 52. State Management

Do not add Riverpod, Bloc, Provider, GetX, or another external state management package just for this library.

Use:

```text
StatefulWidget
ValueNotifier
ChangeNotifier
or a small internal controller
```

unless there is a compelling technical reason otherwise.

The package should remain easy to integrate into applications regardless of their state-management solution.

---

# 53. Customization Hooks

Where practical, support builder overrides.

Potential examples:

```dart
MediaPickerConfig(
  sourcePickerBuilder: ...,
  cameraOverlayBuilder: ...,
  previewBuilder: ...,
)
```

Do not make this API overly complex in v1.

Theme customization should cover most use cases.

Architecture should make builder customization possible later.

---

# 54. Future-Proofing

Design internal interfaces so these can be added later without major breaking changes:

```text
video capture

multiple image capture

document scanner

automatic edge detection

OCR

face capture

barcode scanning

camera overlays

watermarks

image annotation

basic editor

multi-image gallery selection

desktop camera

web camera

upload progress integration
```

Do NOT implement all of them now.

Only ensure the architecture does not prevent them later.

---

# 55. V1 Scope

The first production version should focus on:

```text
✓ Android in-app camera using Flutter camera/CameraX
✓ iOS camera using native image_picker
✓ gallery selection
✓ Windows gallery/file selection
✓ unified MediaResult
✓ source chooser
✓ custom camera UI on Android
✓ camera switching
✓ flash
✓ zoom
✓ tap-to-focus
✓ lifecycle recovery
✓ preview
✓ retake
✓ image resizing
✓ compression
✓ orientation correction
✓ capability detection
✓ normalized errors
✓ customizable theme
✓ robust permissions
✓ tests
✓ example application
✓ README
```

Do not let secondary features delay or destabilize the core.

---

# 56. Suggested Internal Structure

A good initial structure could look like:

```text
lib/
├── nw_media_picker.dart
│
└── src/
    ├── core/
    │   ├── nw_media_picker_service.dart
    │   └── platform_resolver.dart
    │
    ├── adapters/
    │   ├── camera_capture_adapter.dart
    │   ├── gallery_picker_adapter.dart
    │   │
    │   ├── android/
    │   │   └── android_camera_adapter.dart
    │   │
    │   ├── ios/
    │   │   └── ios_camera_adapter.dart
    │   │
    │   └── desktop/
    │       └── unsupported_camera_adapter.dart
    │
    ├── camera/
    │   ├── camera_page.dart
    │   ├── camera_screen_controller.dart
    │   ├── camera_preview.dart
    │   ├── camera_controls.dart
    │   ├── camera_focus_indicator.dart
    │   └── camera_lifecycle_handler.dart
    │
    ├── gallery/
    │   └── image_picker_gallery_adapter.dart
    │
    ├── processing/
    │   ├── image_processor.dart
    │   ├── default_image_processor.dart
    │   └── media_metadata_reader.dart
    │
    ├── permissions/
    │   └── permission_service.dart
    │
    ├── models/
    │   ├── media_result.dart
    │   ├── media_source.dart
    │   ├── media_picker_config.dart
    │   ├── camera_capture_config.dart
    │   ├── gallery_picker_config.dart
    │   ├── image_processing_config.dart
    │   ├── media_capabilities.dart
    │   └── media_picker_error.dart
    │
    ├── widgets/
    │   ├── media_source_sheet.dart
    │   ├── media_preview_page.dart
    │   ├── permission_error_view.dart
    │   └── camera_error_view.dart
    │
    ├── theme/
    │   └── media_picker_theme.dart
    │
    ├── logging/
    │   └── media_picker_logger.dart
    │
    └── utils/
        ├── media_file_utils.dart
        └── media_temp_manager.dart
```

You may improve this structure if a better architecture becomes clear while implementing it.

Do not follow the structure mechanically if it creates unnecessary abstractions.

---

# 57. API Example — Desired Final Experience

The final application developer experience should be approximately this simple:

```dart
final photo = await NWMediaPicker.pickImage(
  context,
  config: const MediaPickerConfig(
    processing: ImageProcessingConfig(
      quality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    ),
  ),
);

if (photo == null) {
  return;
}

debugPrint(photo.path);
debugPrint('${photo.width} x ${photo.height}');
debugPrint('${photo.sizeBytes}');
```

Profile example:

```dart
final photo = await NWMediaPicker.pickImage(
  context,
  config: MediaPickerPresets.profilePhoto,
);
```

Camera directly:

```dart
final photo = await NWMediaPicker.camera(
  context,
);
```

Gallery:

```dart
final photo = await NWMediaPicker.gallery();
```

Capability:

```dart
final capabilities =
    await NWMediaPicker.capabilities();

if (capabilities.camera) {
  // camera option available
}
```

This level of simplicity is a primary success criterion.

---

# 58. Acceptance Criteria

Do not consider the implementation complete until all of these are true.

## Architecture

* [ ] Camera implementation is hidden behind an adapter.
* [ ] Gallery implementation is hidden behind an adapter.
* [ ] Public API does not expose third-party plugin types.
* [ ] Android camera capture does not launch an OEM external camera app.
* [ ] iOS normal camera capture uses native `image_picker`.
* [ ] Desktop camera unavailability is handled gracefully.
* [ ] Consuming apps do not need routine platform checks.

## Camera

* [ ] Android camera opens reliably.
* [ ] Photo capture works.
* [ ] Front/back switching works.
* [ ] Flash works.
* [ ] Pinch zoom works.
* [ ] Tap focus works.
* [ ] Duplicate captures are prevented.
* [ ] Correct preview aspect ratio is maintained.
* [ ] Camera is disposed safely.
* [ ] App background/resume is handled.
* [ ] Camera initialization failures recover gracefully.
* [ ] Resolution fallback exists.

## Image

* [ ] Orientation is correct.
* [ ] Optional resizing works.
* [ ] Compression works.
* [ ] Metadata is returned.
* [ ] Very large images do not crash due to memory usage.
* [ ] Temporary files are managed.

## UX

* [ ] Camera/gallery source chooser works.
* [ ] Preview works.
* [ ] Retake works.
* [ ] Cancellation returns null.
* [ ] Permission-denied UI works.
* [ ] Permanent permission-denied UI works.
* [ ] Camera-error fallback to gallery is available when appropriate.

## Package

* [ ] README is complete.
* [ ] Example app is complete.
* [ ] Public APIs have DartDocs.
* [ ] Lints pass.
* [ ] Unit tests pass.
* [ ] Widget tests pass.
* [ ] No application-specific business logic exists.

---

# 59. Implementation Process

Work in this order.

### Phase 1 — Research

Inspect the latest stable Flutter package APIs for:

```text
camera
image_picker
required image-processing dependency
```

Check Android/iOS platform requirements.

Do not assume dependency APIs from old examples.

---

### Phase 2 — Package Skeleton

Create:

```text
package
models
configs
error model
adapter interfaces
public exports
```

Before writing camera UI.

---

### Phase 3 — Gallery

Implement:

```text
single image gallery selection
MediaResult conversion
cancellation
errors
```

---

### Phase 4 — iOS System Camera

Implement:

```text
image_picker ImageSource.camera
front/back preference
MediaResult conversion
errors
```

---

### Phase 5 — Android Camera

Implement:

```text
CameraX-backed in-app camera
lifecycle
capture
switching
flash
zoom
focus
```

Reliability is more important than visual sophistication.

---

### Phase 6 — Processing

Implement:

```text
orientation
resize
compression
metadata
```

---

### Phase 7 — Picker UX

Implement:

```text
source chooser
camera preview
photo preview
retake
error views
```

---

### Phase 8 — Capabilities

Implement:

```text
camera availability
gallery availability
front/back availability
```

---

### Phase 9 — Tests

Add:

```text
unit
widget
integration/manual QA
```

---

### Phase 10 — Documentation

Complete:

```text
README
example
CHANGELOG
public DartDocs
```

---

# 60. Important Development Rule

When you encounter a design choice, prioritize in this order:

```text
1. Reliability
2. API stability
3. Cross-device compatibility
4. Maintainability
5. Memory efficiency
6. UX
7. Visual polish
```

The original problem being solved is camera instability on certain Android devices.

Do not create another implementation that looks polished but is fragile.

---

# 61. Do Not Do These Things

Do NOT:

```text
Use ImageSource.camera on Android.

Launch external OEM camera apps on Android.

Expose CameraController to consuming apps.

Make the app manage camera lifecycle.

Hardcode one app's branding.

Upload images from inside this package.

Depend on Firebase.

Add feature-specific models.

Use global mutable static controller state.

Ignore camera initialization exceptions.

Assume all Android devices expose the same camera capabilities.

Assume all images are JPEG.

Assume all devices support front/back cameras.

Assume all images have correct orientation.

Keep raw 5–15 MB camera files without processing when optimization is configured.

Block the UI with heavy synchronous image processing.

Add multiple large state-management dependencies.

Over-engineer future features before v1 is stable.
```

---

# 62. Deliverables

At completion, provide:

```text
1. Complete Flutter package source
2. Example Flutter application
3. README
4. CHANGELOG
5. Tests
6. Manual Android QA checklist
7. Architecture overview
8. Explanation of public API
9. Platform-specific setup instructions
10. Known limitations
11. Recommended future improvements
```

Also include a short architecture diagram in the README:

```text
                  NWMediaPicker
                       │
                Platform Resolver
                       │
          ┌────────────┼────────────┐
          │            │            │
       Android        iOS        Desktop
          │            │            │
       camera      image_picker    files
       CameraX      native UI       only
          │            │            │
          └────────────┼────────────┘
                       │
                Image Processor
                       │
                 MediaResult
```

---

# 63. Final Goal

The package should make application code look like:

```dart
final image = await NWMediaPicker.pickImage(context);

if (image == null) return;

await repository.upload(image.path);
```

while internally handling all of the difficult work:

```text
platform differences
camera lifecycle
CameraX
native iOS camera
permissions
camera crashes/errors
image processing
orientation
file sizes
temporary files
camera availability
front/back cameras
gallery
preview
retake
error normalization
```

Build it as infrastructure that can be depended on by multiple production Flutter applications for years.

Do not optimize for a demo.

Optimize for a stable reusable package.
