# Changelog

## Unreleased

### Added
- **Interactive cropping** via `InteractiveCropConfig` (backed by
  `image_cropper`): a full-screen crop editor shown after capture/selection and
  before processing, on Android and iOS. Supports fixed/free aspect ratio,
  aspect-ratio lock, rectangular or oval (circular) mask, preset ratios, quality,
  and theme-aware toolbar colors. Presets `InteractiveCropConfig.square`,
  `.circle`, and `.disabled`; `MediaPickerConfig.crop` wires it in (disabled by
  default). New `onCropStarted` / `onCropCompleted` callbacks.
- `ImageCropperCropAdapter` (plugin-backed) and `PassthroughCropAdapter`
  (desktop no-op) implementing the now-active `ImageCropperAdapter` interface.
- `profilePhoto` (circular) and `squareImage` presets now enable interactive
  cropping.

> **Android:** apps enabling interactive cropping must register `UCropActivity`
> in their `AndroidManifest.xml` — see the README.

## 0.1.0

Initial release.

### Added
- Unified, adapter-based public API (`NWMediaPicker`) that hides the underlying
  plugins (`camera`, `image_picker`, `flutter_image_compress`).
- **Android:** in-app CameraX camera with a custom UI — never launches the OEM
  camera app. Front/back switch, flash (off/auto/on/torch), pinch-to-zoom,
  tap-to-focus, resolution fallback, and app-lifecycle-safe controller handling.
- **iOS:** native `image_picker` camera by default, with an opt-in custom camera
  (`CameraExperience.custom`).
- **Desktop:** graceful "camera unsupported" behavior; gallery/file selection
  supported.
- Single and multiple gallery selection.
- Normalized `MediaResult` (no `XFile` leakage) with metadata.
- Memory-safe image processing pipeline (native resize/compress, header-only
  dimension reads, orientation correction, optional center-crop). Output is
  JPEG.
- Source chooser sheet, post-capture preview (retake/use), and permission /
  camera error views.
- Capability detection (`MediaCapabilities`).
- Normalized error model (`MediaPickerException` / `MediaPickerErrorCode`);
  cancellation returns `null`.
- Pluggable `MediaPickerLogger` and analytics `MediaPickerCallbacks` (no
  Crashlytics/Sentry/analytics dependency).
- Configurable, brand-agnostic `MediaPickerTheme`.
- Business-agnostic presets (`MediaPickerPresets`).
- Predictable temporary-file management (`clearTemporaryFiles`,
  `getTemporaryCacheSize`).
- Example app, unit + widget + integration tests, and a manual QA checklist.
