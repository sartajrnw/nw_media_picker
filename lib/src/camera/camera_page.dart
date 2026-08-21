import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../logging/media_picker_logger.dart';
import '../models/camera_capture_config.dart';
import '../models/media_picker_config.dart';
import '../models/media_result.dart';
import '../models/media_source.dart';
import '../permissions/permission_service.dart';
import '../theme/media_picker_theme.dart';
import '../utils/media_file_utils.dart';
import '../utils/media_temp_manager.dart';
import '../widgets/camera_error_view.dart';
import '../widgets/media_preview_page.dart';
import '../widgets/permission_error_view.dart';
import 'camera_controls.dart';
import 'camera_focus_indicator.dart';
import 'camera_screen_controller.dart';
import '../models/camera_enums.dart';

/// Full-screen in-app camera page (the Android CameraX experience).
///
/// Pops with a **raw** (unprocessed) [MediaResult] on success, or `null` on
/// cancellation. The camera source is normally [MediaSource.camera]; if the
/// user picks from the gallery shortcut it may be [MediaSource.gallery].
class CameraPage extends StatefulWidget {
  /// Capture configuration.
  final CameraCaptureConfig config;

  /// Visual theme.
  final MediaPickerTheme theme;

  /// Temp file manager.
  final MediaTempManager tempManager;

  /// Permission service.
  final PermissionService permissionService;

  /// Whether to show the in-app preview (retake/use) after capture.
  final bool showPreviewAfterCapture;

  /// Optional gallery shortcut: opens the gallery and returns a raw result.
  final Future<MediaResult?> Function()? onPickFromGallery;

  /// Optional custom preview builder.
  final PreviewBuilder? previewBuilder;

  /// Logger.
  final MediaPickerLogger logger;

  /// Creates the camera page.
  const CameraPage({
    super.key,
    required this.config,
    required this.theme,
    required this.tempManager,
    required this.permissionService,
    this.showPreviewAfterCapture = true,
    this.onPickFromGallery,
    this.previewBuilder,
    this.logger = const DebugMediaPickerLogger(),
  });

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  late final CameraScreenController _controller;
  MediaPermissionStatus _permission = MediaPermissionStatus.unknown;
  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = CameraScreenController(
      config: widget.config,
      tempManager: widget.tempManager,
      logger: widget.logger,
    );
    _controller.addListener(_onControllerChanged);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final status = await widget.permissionService.ensureCamera();
    if (!mounted) return;
    setState(() {
      _permission = status;
      _permissionChecked = true;
    });
    if (status.isUsable) {
      await _controller.initialize();
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_permission.isUsable) return;
    _controller.handleAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  // ----- Actions -----

  Future<void> _onCapture() async {
    try {
      final path = await _controller.capture();
      if (path == null || !mounted) return;
      final raw = MediaResult(
        path: path,
        source: MediaSource.camera,
        createdAt: DateTime.now(),
        mimeType: 'image/jpeg',
        sizeBytes: MediaFileUtils.sizeBytesOf(path),
        originalFileName: MediaFileUtils.fileNameOf(path),
      );

      if (!widget.showPreviewAfterCapture) {
        _finish(raw);
        return;
      }

      final accepted = await _showPreview(raw);
      if (!mounted) return;
      if (accepted) {
        _finish(raw);
      } else {
        // Retake: resume the live camera (already alive underneath).
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Capture failed. Please try again.');
    }
  }

  Future<bool> _showPreview(MediaResult raw) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) {
          if (widget.previewBuilder != null) {
            return widget.previewBuilder!(
              context,
              raw,
              () => Navigator.of(context).pop(true),
              () => Navigator.of(context).pop(false),
            );
          }
          return MediaPreviewPage(result: raw, theme: widget.theme);
        },
      ),
    );
    return result ?? false;
  }

  Future<void> _onGalleryShortcut() async {
    final pick = widget.onPickFromGallery;
    if (pick == null) return;
    final result = await pick();
    if (result != null && mounted) {
      _finish(result);
    }
  }

  void _finish(MediaResult raw) => Navigator.of(context).pop(raw);

  void _cancel() => Navigator.of(context).pop(null);

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ----- Build -----

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (!_permissionChecked) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_permission.isUsable) {
      return PermissionErrorView(
        theme: widget.theme,
        permanentlyDenied: _permission.isBlocked,
        showGalleryOption: widget.onPickFromGallery != null,
        onOpenSettings: () => widget.permissionService.openSettings(),
        onChooseFromGallery: _onGalleryShortcut,
        onCancel: _cancel,
      );
    }

    switch (_controller.state) {
      case CameraState.error:
        return CameraErrorView(
          theme: widget.theme,
          message:
              _controller.errorMessage ?? 'The camera could not be started.',
          showGalleryOption: widget.onPickFromGallery != null,
          onRetry: () => _controller.initialize(),
          onChooseFromGallery: _onGalleryShortcut,
          onCancel: _cancel,
        );
      case CameraState.permissionDenied:
        return PermissionErrorView(
          theme: widget.theme,
          permanentlyDenied: true,
          showGalleryOption: widget.onPickFromGallery != null,
          onOpenSettings: () => widget.permissionService.openSettings(),
          onChooseFromGallery: _onGalleryShortcut,
          onCancel: _cancel,
        );
      case CameraState.initializing:
      case CameraState.ready:
      case CameraState.capturing:
      case CameraState.processing:
        return _buildCamera();
    }
  }

  Widget _buildCamera() {
    final theme = widget.theme;
    final ready = _controller.isReady;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (ready) _buildPreview() else _buildLoading(),
        Column(
          children: [
            CameraTopBar(
              theme: theme,
              showFlash: widget.config.allowFlash,
              flashMode: _controller.flashMode,
              onClose: _cancel,
              onFlashToggle: _controller.cycleFlashMode,
            ),
            const Spacer(),
            if (widget.config.allowZoom &&
                _controller.maxZoom > _controller.minZoom + 0.01)
              _buildZoomIndicator(theme),
            CameraBottomBar(
              theme: theme,
              captureEnabled: ready,
              capturing: _controller.isCapturing,
              showSwitch:
                  widget.config.allowCameraSwitch &&
                  _controller.hasMultipleCameras,
              showGalleryShortcut: widget.onPickFromGallery != null,
              onCapture: _onCapture,
              onSwitch: _controller.switchCamera,
              onGallery: _onGalleryShortcut,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(widget.theme.foregroundColor),
      ),
    );
  }

  Widget _buildPreview() {
    final controller = _controller.controller!;
    final orientation = MediaQuery.of(context).orientation;
    final previewRatio = controller.value.aspectRatio;
    final aspect = orientation == Orientation.portrait
        ? 1 / previewRatio
        : previewRatio;

    return Center(
      child: AspectRatio(
        aspectRatio: aspect,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (_) => _controller.onScaleStart(),
              onScaleUpdate: (details) =>
                  _controller.onScaleUpdate(details.scale),
              onTapUp: (details) =>
                  _controller.focusAt(details.localPosition, size),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controller),
                  if (_controller.focusIndicator != null)
                    CameraFocusIndicator(
                      key: ValueKey(_controller.focusIndicator!.id),
                      position: _controller.focusIndicator!.position,
                      color: widget.theme.primaryColor,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildZoomIndicator(MediaPickerTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${_controller.currentZoom.toStringAsFixed(1)}x',
          style: TextStyle(color: theme.foregroundColor, fontSize: 12),
        ),
      ),
    );
  }
}
