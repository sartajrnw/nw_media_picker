import 'dart:io';

import 'package:flutter/material.dart';

import '../models/media_result.dart';
import '../theme/media_picker_theme.dart';

/// Full-screen preview shown after a capture.
///
/// Pops `true` when the user accepts the photo ("Use"), and `false` when they
/// choose to retake. Also used standalone by the service.
class MediaPreviewPage extends StatelessWidget {
  /// The (raw) captured media to preview.
  final MediaResult result;

  /// Visual theme.
  final MediaPickerTheme theme;

  /// Label for the accept action.
  final String useLabel;

  /// Label for the retake action.
  final String retakeLabel;

  /// Creates a preview page.
  const MediaPreviewPage({
    super.key,
    required this.result,
    required this.theme,
    this.useLabel = 'Use Photo',
    this.retakeLabel = 'Retake',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Close',
                icon: Icon(Icons.close, color: theme.foregroundColor),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            Expanded(
              child: Center(
                child: InteractiveViewer(
                  child: Image.file(
                    File(result.path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) => Icon(
                      Icons.broken_image_outlined,
                      color: theme.foregroundColor,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: Icon(Icons.refresh, color: theme.foregroundColor),
                    label: Text(
                      retakeLabel,
                      style: TextStyle(color: theme.foregroundColor),
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.check),
                    label: Text(useLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
