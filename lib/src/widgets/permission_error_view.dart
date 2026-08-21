import 'package:flutter/material.dart';

import '../theme/media_picker_theme.dart';

/// Shown when camera (or photo) permission is unavailable.
///
/// Offers to open Settings (for permanent denials), fall back to the gallery,
/// or cancel — never crashing the host app.
class PermissionErrorView extends StatelessWidget {
  /// Visual theme.
  final MediaPickerTheme theme;

  /// Whether the permission is permanently denied (Settings is the only path).
  final bool permanentlyDenied;

  /// Whether to offer the "Choose from Gallery" fallback.
  final bool showGalleryOption;

  /// Message override.
  final String message;

  /// Called to open system settings.
  final VoidCallback onOpenSettings;

  /// Called to choose from gallery instead.
  final VoidCallback onChooseFromGallery;

  /// Called to cancel.
  final VoidCallback onCancel;

  /// Creates a permission error view.
  const PermissionErrorView({
    super.key,
    required this.theme,
    required this.permanentlyDenied,
    required this.showGalleryOption,
    required this.onOpenSettings,
    required this.onChooseFromGallery,
    required this.onCancel,
    this.message = 'Camera access is required to take a photo.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_photography_outlined,
              color: theme.foregroundColor,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.foregroundColor, fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (permanentlyDenied)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                ),
                onPressed: onOpenSettings,
                child: const Text('Open Settings'),
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
