# nw_media_picker

A generic, **application-agnostic** Flutter package for capturing and selecting
images with one stable API across mobile and desktop.

It exists to solve one problem well: **camera reliability on Android**. Some
OEM/system camera apps (Samsung, Xiaomi, Oppo, Vivo, Realme, …) crash or fail to
return a result when launched via `image_picker`'s `ImageSource.camera`. This
package uses Flutter's official `camera` package with the endorsed **CameraX**
implementation and an in-app camera UI on Android, so it **never launches the
OEM camera app**.

```dart
final image = await NWMediaPicker.pickImage(context);
if (image == null) return; // user cancelled
await repository.upload(image.path);
```

The package ends at `MediaResult`. It contains **no** uploads, Firebase,
analytics SDKs, or business logic.

---

## Architecture

```
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

Everything is adapter-based. Consuming apps never see `CameraController`,
`XFile`, `ResolutionPreset`, `FlashMode`, or `ImagePicker` — only the package's
own models. This lets the underlying dependencies change without breaking apps.

| Platform | Camera capture | Gallery |
|----------|----------------|---------|
| Android  | In-app CameraX camera (custom UI) | `image_picker` |
| iOS      | Native `image_picker` camera (default) or custom camera (`CameraExperience.custom`) | `image_picker` |
| Windows / macOS / Linux | Unsupported (graceful) | `image_picker` / file selector |

---

## Installation

This is currently distributed as a private git package:

```yaml
dependencies:
  nw_media_picker:
    git:
      url: <your-private-repository-url>
      ref: v0.1.0
```

Then:

```dart
import 'package:nw_media_picker/nw_media_picker.dart';
```

### Android setup

`minSdkVersion` must be **21+** (CameraX / image_picker requirement). Add the
camera permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

Gallery selection uses the modern Android Photo Picker and needs no storage
permission on supported versions.

### iOS setup

Add usage descriptions to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to take photos.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is required to select photos.</string>
```

Audio is disabled for capture, so **no microphone permission is required**.

---

## Usage

### Pick an image (source chooser)

When multiple sources are configured, a chooser sheet is shown automatically;
with a single source it opens directly.

```dart
final image = await NWMediaPicker.pickImage(context);
```

### Camera directly

```dart
final image = await NWMediaPicker.camera(context);
```

### Gallery directly

```dart
final image = await NWMediaPicker.gallery();
```

### Multiple gallery selection

```dart
final images = await NWMediaPicker.galleryMultiple(
  config: const MediaPickerConfig(
    gallery: GalleryPickerConfig(allowMultiple: true, maxSelection: 5),
  ),
);
```

### Custom configuration

```dart
final photo = await NWMediaPicker.pickImage(
  context,
  config: const MediaPickerConfig(
    camera: CameraCaptureConfig(
      preferredLens: CameraLens.front,
      allowFlash: true,
      enablePinchToZoom: true,
      enableTapToFocus: true,
      resolution: CameraResolution.veryHigh,
    ),
    processing: ImageProcessingConfig(
      quality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    ),
  ),
);
```

### Presets

Generic, business-agnostic convenience configs (the package works fully without
them):

```dart
await NWMediaPicker.pickImage(context, config: MediaPickerPresets.profilePhoto);
await NWMediaPicker.pickImage(context, config: MediaPickerPresets.productPhoto);
```

`profilePhoto`, `squareImage`, `productPhoto`, `highQualityPhoto`,
`documentPhoto`.

### Capability detection

No `if (Platform.isX)` needed in your app:

```dart
final caps = await NWMediaPicker.capabilities();
if (caps.camera) {
  // offer the camera option
}
```

### Custom theme

The package never hardcodes a brand. Supply colors, or let it inherit from your
app's `ThemeData`.

```dart
const MediaPickerConfig(
  theme: MediaPickerTheme(
    primaryColor: Color(0xFFD4212A),
    captureButtonSize: 80,
  ),
);
```

### Error handling

**Contract:** user cancellation returns `null`; genuine failures throw a
normalized `MediaPickerException`.

```dart
try {
  final image = await NWMediaPicker.camera(context);
  if (image == null) return; // cancelled
  await repository.upload(image.path);
} on MediaPickerException catch (e) {
  switch (e.code) {
    case MediaPickerErrorCode.permissionPermanentlyDenied:
      // guide the user to Settings
      break;
    case MediaPickerErrorCode.cameraUnavailable:
    case MediaPickerErrorCode.captureFailed:
      // show a retry / fallback
      break;
    default:
      // log e.cause
  }
}
```

### Dependency injection / testing

The static `NWMediaPicker` API is backed by a shared `NWMediaPickerService`. For
DI/testing, construct a service directly and call the same-named instance
methods:

```dart
final picker = NWMediaPickerService(
  logger: myLogger,
  callbacks: MediaPickerCallbacks(onCaptureCompleted: track),
);
final result = await picker.pickImage(context);
```

To customize the shared static instance app-wide (e.g. a Crashlytics logger),
call once at startup:

```dart
NWMediaPicker.configure(logger: CrashlyticsMediaPickerLogger());
```

### Logging & analytics

The package depends on **no** crash/analytics SDK. Plug in your own:

* `MediaPickerLogger` — forward logs to Crashlytics/Sentry/custom.
* `MediaPickerCallbacks` — observe `onCameraOpened`, `onCaptureCompleted`,
  `onGallerySelected`, etc., and forward to your analytics.

---

## Image processing

After capture/selection the image runs through a memory-safe pipeline:

```
read dimensions (header only) → correct orientation → resize → optional crop
→ compress → collect metadata → MediaResult
```

* Resizing/compression run **natively** (`flutter_image_compress`) reading from
  disk — the full-resolution bitmap is never decoded onto the Dart heap, so
  12MP/48MP images do not spike memory.
* Source dimensions are read **header-only**; no full decode.
* If the config would not change the image, the original file is returned
  untouched.
* **Output is always JPEG.** HEIC input (iOS) is converted to JPEG.
* Orientation is baked into the pixels so photos never appear sideways.

Recommended defaults: `quality: 85`, longest side ~1600–1920px. Example: a
4032×3024 / 6.5 MB capture becomes ~1600×1200 / ~300 KB–1 MB.

---

## Lifecycle behavior

Camera lifecycle is handled **inside the package** — consuming apps do not need
to implement any of it. The camera screen:

* releases the controller when the app is backgrounded and re-initializes on
  resume,
* guards against disposed-controller access, duplicate initialization, and
  multiple simultaneous controllers,
* recovers after phone calls, app switching, and (where possible) permission
  changes,
* prevents duplicate/concurrent captures and disables the capture button while
  a capture is in flight,
* falls back to lower resolutions if initialization fails, showing a recoverable
  error instead of crashing.

---

## Temporary files

Captured/processed files live under a predictable package directory
(`<cache>/nw_media_picker/`) with unique names, so they can be cleared
deterministically.

```dart
await NWMediaPicker.clearTemporaryFiles();
final bytes = await NWMediaPicker.getTemporaryCacheSize();
```

> Returned `MediaResult.path`s may live in **temporary** storage. If your app
> needs the file long-term, copy/persist it before clearing the cache. The
> package does not delete a result before you have a chance to use it.

---

## Known limitations (v1)

* Desktop (Windows/macOS/Linux) camera capture is unsupported (gallery works).
* Interactive cropping is not bundled; `cropAspectRatio` performs an automatic
  center-crop. An `ImageCropperAdapter` interface is provided so an interactive
  cropper can be added later without an API change.
* iOS custom camera reuses the CameraX-backed page via
  `CameraExperience.custom`; the default remains the native camera.
* Output is always JPEG.

## Recommended future improvements

* Interactive crop adapter (e.g. `image_cropper`).
* Video capture, document scanner, edge detection, OCR, barcode scanning.
* Desktop/web camera adapters.
* Isolate-based processing for platforms without a native compressor.

---

## Testing

* Unit + widget tests: `flutter test`
* On-device integration checks: `cd example && flutter test integration_test`
* Manual device QA: see [`MANUAL_QA.md`](MANUAL_QA.md) — required for release,
  since real camera hardware cannot be covered by automated tests.

## License

See [LICENSE](LICENSE).
