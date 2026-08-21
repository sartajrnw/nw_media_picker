import 'package:flutter/material.dart';

import '../models/camera_enums.dart';
import '../theme/media_picker_theme.dart';

/// Top bar: close + flash controls.
class CameraTopBar extends StatelessWidget {
  /// Theme for colors.
  final MediaPickerTheme theme;

  /// Whether flash controls are shown.
  final bool showFlash;

  /// Current flash mode.
  final MediaFlashMode flashMode;

  /// Called when close is tapped.
  final VoidCallback onClose;

  /// Called when the flash button is tapped.
  final VoidCallback onFlashToggle;

  /// Creates the top bar.
  const CameraTopBar({
    super.key,
    required this.theme,
    required this.showFlash,
    required this.flashMode,
    required this.onClose,
    required this.onFlashToggle,
  });

  IconData get _flashIcon {
    switch (flashMode) {
      case MediaFlashMode.off:
        return Icons.flash_off;
      case MediaFlashMode.auto:
        return Icons.flash_auto;
      case MediaFlashMode.on:
        return Icons.flash_on;
      case MediaFlashMode.torch:
        return Icons.highlight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Close',
            icon: Icon(Icons.close, color: theme.foregroundColor),
            onPressed: onClose,
          ),
          if (showFlash)
            IconButton(
              tooltip: 'Flash: ${flashMode.name}',
              icon: Icon(_flashIcon, color: theme.foregroundColor),
              onPressed: onFlashToggle,
            ),
        ],
      ),
    );
  }
}

/// Bottom bar: gallery shortcut, capture button, camera switch.
class CameraBottomBar extends StatelessWidget {
  /// Theme for colors/sizes.
  final MediaPickerTheme theme;

  /// Whether the capture button is enabled.
  final bool captureEnabled;

  /// Whether a capture is currently in progress (shows a spinner).
  final bool capturing;

  /// Whether to show the camera-switch control.
  final bool showSwitch;

  /// Whether to show the gallery shortcut.
  final bool showGalleryShortcut;

  /// Called when capture is tapped.
  final VoidCallback onCapture;

  /// Called when switch is tapped.
  final VoidCallback onSwitch;

  /// Called when the gallery shortcut is tapped.
  final VoidCallback? onGallery;

  /// Creates the bottom bar.
  const CameraBottomBar({
    super.key,
    required this.theme,
    required this.captureEnabled,
    required this.capturing,
    required this.showSwitch,
    required this.showGalleryShortcut,
    required this.onCapture,
    required this.onSwitch,
    this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: showGalleryShortcut
                  ? IconButton(
                      tooltip: 'Gallery',
                      iconSize: 30,
                      icon: Icon(
                        Icons.photo_library_outlined,
                        color: theme.foregroundColor,
                      ),
                      onPressed: onGallery,
                    )
                  : const SizedBox(width: 48),
            ),
          ),
          _CaptureButton(
            size: theme.captureButtonSize,
            color: theme.primaryColor,
            enabled: captureEnabled,
            capturing: capturing,
            onTap: onCapture,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: showSwitch
                  ? IconButton(
                      tooltip: 'Switch camera',
                      iconSize: 30,
                      icon: Icon(
                        Icons.cameraswitch_outlined,
                        color: theme.foregroundColor,
                      ),
                      onPressed: onSwitch,
                    )
                  : const SizedBox(width: 48),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final double size;
  final Color color;
  final bool enabled;
  final bool capturing;
  final VoidCallback onTap;

  const _CaptureButton({
    required this.size,
    required this.color,
    required this.enabled,
    required this.capturing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = enabled && !capturing ? 1.0 : 0.5;
    return Semantics(
      button: true,
      enabled: enabled && !capturing,
      label: 'Capture photo',
      child: GestureDetector(
        onTap: enabled && !capturing ? onTap : null,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 4),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: capturing
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
