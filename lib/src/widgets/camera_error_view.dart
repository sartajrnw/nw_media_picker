import 'package:flutter/material.dart';

import '../theme/media_picker_theme.dart';

/// Shown when the camera fails to initialize (after resolution fallback).
///
/// Offers retry, an optional gallery fallback, and cancel — recoverable, never
/// a crash.
class CameraErrorView extends StatelessWidget {
  /// Visual theme.
  final MediaPickerTheme theme;

  /// Message to display.
  final String message;

  /// Whether to offer the gallery fallback.
  final bool showGalleryOption;

  /// Called to retry initialization.
  final VoidCallback onRetry;

  /// Called to choose from gallery instead.
  final VoidCallback onChooseFromGallery;

  /// Called to cancel.
  final VoidCallback onCancel;

  /// Creates a camera error view.
  const CameraErrorView({
    super.key,
    required this.theme,
    required this.message,
    required this.showGalleryOption,
    required this.onRetry,
    required this.onChooseFromGallery,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.foregroundColor, size: 56),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.foregroundColor, fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.primaryColor,
              ),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
            if (showGalleryOption) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onChooseFromGallery,
                child: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: theme.foregroundColor),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: onCancel,
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.foregroundColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
