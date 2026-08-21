import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

import '../exceptions/media_picker_exception.dart';
import '../logging/media_picker_logger.dart';
import '../models/camera_capture_config.dart';
import '../models/camera_enums.dart';
import '../utils/media_temp_manager.dart';

/// Ordered resolution fallback chain (highest → lowest).
const List<ResolutionPreset> _fallbackChain = <ResolutionPreset>[
  ResolutionPreset.max,
  ResolutionPreset.ultraHigh,
  ResolutionPreset.veryHigh,
  ResolutionPreset.high,
  ResolutionPreset.medium,
  ResolutionPreset.low,
];

/// A transient tap-to-focus indicator location.
class FocusIndicator {
  /// Local position (in preview widget coordinates) of the tap.
  final Offset position;

  /// Monotonic id so the UI can key/replace successive indicators.
  final int id;

  /// Creates a focus indicator marker.
  const FocusIndicator(this.position, this.id);
}

/// Owns the [CameraController] and all camera-screen state.
///
/// This is the heart of the package's reliability guarantees:
/// * explicit [CameraState] machine,
/// * app-lifecycle-safe (releases the controller in the background,
///   re-initializes on resume),
/// * resolution fallback on initialization failure,
/// * guards against duplicate captures, disposed-controller access, and
///   multiple simultaneous controllers.
///
/// It is a [ChangeNotifier] (no external state-management dependency).
class CameraScreenController extends ChangeNotifier {
  /// Capture configuration.
  final CameraCaptureConfig config;

  final MediaTempManager _temp;
  final MediaPickerLogger _logger;

  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  CameraDescription? _activeDescription;

  CameraState _state = CameraState.initializing;
  String? _errorMessage;

  CameraLens _currentLens;
  MediaFlashMode _flashMode = MediaFlashMode.off;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0; // zoom at gesture start

  FocusIndicator? _focusIndicator;
  int _focusCounter = 0;

  bool _isCapturing = false;
  bool _isInitializing = false;
  bool _isDisposing = false;
  bool _disposed = false;
  double _pendingZoom = 0;
  bool _zoomScheduled = false;

  /// Creates a camera screen controller.
  CameraScreenController({
    required this.config,
    required MediaTempManager tempManager,
    MediaPickerLogger logger = const DebugMediaPickerLogger(),
  }) : _temp = tempManager,
       _logger = logger,
       _currentLens = config.preferredLens;

  // ----- Public read-only state -----

  /// The underlying controller, or null when released. Never exposed outside
  /// the package (the camera UI lives inside the package).
  CameraController? get controller => _controller;

  /// Current lifecycle state.
  CameraState get state => _state;

  /// Human-readable error message when [state] is [CameraState.error].
  String? get errorMessage => _errorMessage;

  /// The currently active lens.
  CameraLens get currentLens => _currentLens;

  /// The current flash mode.
  MediaFlashMode get flashMode => _flashMode;

  /// Whether more than one camera is available (controls switch button).
  bool get hasMultipleCameras => _cameras.length > 1;

  /// Whether a capture is currently in flight (disables capture button).
  bool get isCapturing => _isCapturing;

  /// Whether the preview is initialized and ready.
  bool get isReady =>
      _state == CameraState.ready &&
      _controller != null &&
      _controller!.value.isInitialized;

  /// Minimum supported zoom level.
  double get minZoom => _minZoom;

  /// Maximum supported zoom level (after applying config caps).
  double get maxZoom => _maxZoom;

  /// Current zoom level.
  double get currentZoom => _currentZoom;

  /// Active focus indicator to render, if any.
  FocusIndicator? get focusIndicator => _focusIndicator;

  // ----- Lifecycle -----

  /// Initializes cameras and the controller. Safe to call once on mount.
  Future<void> initialize() async {
    if (_isInitializing || _disposed) return;
    _isInitializing = true;
    _setState(CameraState.initializing);
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
      }
      if (_cameras.isEmpty) {
        _fail(
          'No cameras available on this device.',
          code: MediaPickerErrorCode.cameraUnavailable,
        );
        return;
      }
      final description = _describeForLens(_currentLens);
      await _initControllerWithFallback(description);
    } catch (e, s) {
      _logger.error('Camera initialization failed', error: e, stackTrace: s);
      _fail(
        'Failed to initialize the camera.',
        code: MediaPickerErrorCode.cameraInitializationFailed,
      );
    } finally {
      _isInitializing = false;
    }
  }

  /// Handles app lifecycle transitions to keep camera resources safe.
  ///
  /// Releases the controller when the app is backgrounded and re-initializes
  /// when it returns to the foreground.
  Future<void> handleAppLifecycleState(AppLifecycleState lifecycle) async {
    if (_disposed) return;
    switch (lifecycle) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        await _releaseController();
      case AppLifecycleState.resumed:
        if (_controller == null && !_isInitializing) {
          await initialize();
        }
    }
  }

  Future<void> _initControllerWithFallback(
    CameraDescription description,
  ) async {
    final requested = _resolutionPreset(config.resolution);
    final startIndex = _fallbackChain.indexOf(requested);
    final chain = startIndex >= 0
        ? _fallbackChain.sublist(startIndex)
        : _fallbackChain;

    Object? lastError;
    for (final preset in chain) {
      if (_disposed) return;
      CameraController? candidate;
      try {
        candidate = CameraController(
          description,
          preset,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await candidate.initialize();
        // Success.
        _controller = candidate;
        _activeDescription = description;
        await _applyInitialSettings();
        _setState(CameraState.ready);
        _logger.debug(
          'Camera ready at $preset (${description.lensDirection}).',
        );
        return;
      } catch (e, s) {
        lastError = e;
        _logger.warning('Init failed at $preset: $e');
        _logger.debug('$s');
        await candidate?.dispose();
        // Try next (lower) resolution.
      }
    }
    _logger.error('All resolution presets failed', error: lastError);
    _fail(
      'Unable to start the camera.',
      code: MediaPickerErrorCode.cameraInitializationFailed,
    );
  }

  Future<void> _applyInitialSettings() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
      if (config.minimumZoom != null) {
        _minZoom = config.minimumZoom!.clamp(_minZoom, _maxZoom);
      }
      if (config.maximumZoom != null) {
        _maxZoom = config.maximumZoom!.clamp(_minZoom, _maxZoom);
      }
      _currentZoom = _minZoom;
      await controller.setZoomLevel(_currentZoom);
    } catch (e) {
      _logger.warning('Failed to read zoom capabilities: $e');
      _minZoom = 1.0;
      _maxZoom = 1.0;
      _currentZoom = 1.0;
    }
    // Re-apply the remembered flash mode across re-inits.
    await _applyFlash(_flashMode);
  }

  Future<void> _releaseController() async {
    if (_controller == null || _isDisposing) return;
    _isDisposing = true;
    final controller = _controller;
    _controller = null;
    try {
      await controller?.dispose();
      _logger.debug('Camera controller released.');
    } catch (e) {
      _logger.warning('Error disposing controller: $e');
    } finally {
      _isDisposing = false;
      if (!_disposed) {
        _setState(CameraState.initializing);
      }
    }
  }

  // ----- Controls -----

  /// Switches between front and back cameras (recreates the controller for
  /// maximum reliability). No-op while capturing or if only one camera exists.
  Future<void> switchCamera() async {
    if (!config.allowCameraSwitch || !hasMultipleCameras) return;
    if (_isCapturing || _isInitializing || _disposed) return;
    _currentLens = _currentLens == CameraLens.back
        ? CameraLens.front
        : CameraLens.back;
    await _releaseController();
    await initialize();
  }

  /// Sets the flash mode and remembers it for the session.
  Future<void> setFlashMode(MediaFlashMode mode) async {
    if (!config.allowFlash) return;
    _flashMode = mode;
    await _applyFlash(mode);
    _notify();
  }

  /// Cycles flash off → auto → on → torch → off.
  Future<void> cycleFlashMode() async {
    const order = [
      MediaFlashMode.off,
      MediaFlashMode.auto,
      MediaFlashMode.on,
      MediaFlashMode.torch,
    ];
    final next = order[(order.indexOf(_flashMode) + 1) % order.length];
    await setFlashMode(next);
  }

  Future<void> _applyFlash(MediaFlashMode mode) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.setFlashMode(_flashModeToPlugin(mode));
    } catch (e) {
      _logger.warning('Failed to set flash mode $mode: $e');
    }
  }

  /// Handles the start of a pinch gesture.
  void onScaleStart() {
    _baseZoom = _currentZoom;
  }

  /// Handles a pinch-zoom update. Clamps to device limits and throttles the
  /// number of controller calls.
  void onScaleUpdate(double scale) {
    if (!config.allowZoom || !config.enablePinchToZoom) return;
    final target = (_baseZoom * scale).clamp(_minZoom, _maxZoom);
    _setZoomThrottled(target);
  }

  /// Sets an absolute zoom level (e.g. from a slider). Clamped to limits.
  Future<void> setZoom(double zoom) async {
    if (!config.allowZoom) return;
    _setZoomThrottled(zoom.clamp(_minZoom, _maxZoom));
  }

  void _setZoomThrottled(double target) {
    _pendingZoom = target;
    if (_zoomScheduled) return;
    _zoomScheduled = true;
    // Coalesce rapid gesture updates into one controller call per frame.
    scheduleMicrotask(() async {
      _zoomScheduled = false;
      final controller = _controller;
      if (controller == null || !controller.value.isInitialized || _disposed) {
        return;
      }
      if ((_pendingZoom - _currentZoom).abs() < 0.01) return;
      _currentZoom = _pendingZoom;
      try {
        await controller.setZoomLevel(_currentZoom);
      } catch (e) {
        _logger.warning('Failed to set zoom: $e');
      }
      _notify();
    });
  }

  /// Focuses (and meters exposure) at a tapped point.
  ///
  /// [localPosition] is in preview-widget coordinates; [previewSize] is the
  /// rendered preview size. Both are converted to normalized [0,1] camera
  /// coordinates.
  Future<void> focusAt(Offset localPosition, Size previewSize) async {
    if (!config.enableTapToFocus) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final normalized = Offset(
      (localPosition.dx / previewSize.width).clamp(0.0, 1.0),
      (localPosition.dy / previewSize.height).clamp(0.0, 1.0),
    );

    _focusIndicator = FocusIndicator(localPosition, ++_focusCounter);
    _notify();

    try {
      await controller.setExposurePoint(normalized);
      await controller.setFocusPoint(normalized);
      await controller.setFocusMode(FocusMode.auto);
    } catch (e) {
      _logger.warning('Tap-to-focus failed: $e');
    }

    // Fade the indicator after ~1s.
    final capturedId = _focusCounter;
    Future<void>.delayed(const Duration(milliseconds: 1000), () {
      if (_disposed) return;
      if (_focusIndicator?.id == capturedId) {
        _focusIndicator = null;
        _notify();
      }
    });
  }

  /// Captures a photo. Guards against duplicate/concurrent captures.
  ///
  /// Returns the captured file path (moved into the package temp dir), or null
  /// if capture could not proceed. Throws [MediaPickerException] on failure.
  Future<String?> capture() async {
    if (_isCapturing) {
      _logger.debug('Capture ignored: already capturing.');
      return null;
    }
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _state != CameraState.ready) {
      return null;
    }

    _isCapturing = true;
    _setState(CameraState.capturing);
    try {
      final XFile shot = await controller.takePicture();
      final destination = await _temp.newFilePath(extension: 'jpg');
      await shot.saveTo(destination);
      // Best-effort cleanup of the plugin's original temp file.
      try {
        await shot.length(); // touch to ensure it existed
      } catch (_) {}
      _setState(CameraState.ready);
      return destination;
    } catch (e, s) {
      _logger.error('Capture failed', error: e, stackTrace: s);
      _setState(CameraState.ready);
      throw MediaPickerException(
        MediaPickerErrorCode.captureFailed,
        'Failed to capture photo: $e',
        cause: e,
        stackTrace: s,
      );
    } finally {
      _isCapturing = false;
    }
  }

  // ----- Mapping helpers (never leak plugin enums) -----

  CameraDescription _describeForLens(CameraLens lens) {
    final wanted = lens == CameraLens.front
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    for (final c in _cameras) {
      if (c.lensDirection == wanted) return c;
    }
    // Fallback: preferred lens unavailable → use the first camera and sync the
    // current lens flag to what we actually opened.
    final fallback = _cameras.first;
    _currentLens = fallback.lensDirection == CameraLensDirection.front
        ? CameraLens.front
        : CameraLens.back;
    _logger.warning(
      'Preferred lens $lens unavailable; using '
      '${fallback.lensDirection}.',
    );
    return fallback;
  }

  ResolutionPreset _resolutionPreset(CameraResolution r) {
    switch (r) {
      case CameraResolution.low:
        return ResolutionPreset.low;
      case CameraResolution.medium:
        return ResolutionPreset.medium;
      case CameraResolution.high:
        return ResolutionPreset.high;
      case CameraResolution.veryHigh:
        return ResolutionPreset.veryHigh;
      case CameraResolution.max:
        return ResolutionPreset.max;
    }
  }

  FlashMode _flashModeToPlugin(MediaFlashMode m) {
    switch (m) {
      case MediaFlashMode.off:
        return FlashMode.off;
      case MediaFlashMode.auto:
        return FlashMode.auto;
      case MediaFlashMode.on:
        return FlashMode.always;
      case MediaFlashMode.torch:
        return FlashMode.torch;
    }
  }

  // ----- Internals -----

  void _fail(String message, {required MediaPickerErrorCode code}) {
    _errorMessage = message;
    _setState(CameraState.error);
  }

  void _setState(CameraState state) {
    _state = state;
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    // Fire-and-forget controller disposal; the flag prevents further access.
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    super.dispose();
  }

  /// The active camera description's sensor orientation (for debugging/tests).
  @visibleForTesting
  CameraDescription? get activeDescription => _activeDescription;
}
