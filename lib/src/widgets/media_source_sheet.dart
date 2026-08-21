import 'package:flutter/material.dart';

import '../models/media_source.dart';
import '../theme/media_picker_theme.dart';

/// A bottom-sheet source chooser shown when more than one source is enabled.
///
/// Returns the chosen [MediaSource], or `null` if dismissed.
class MediaSourceSheet extends StatelessWidget {
  /// The sources to offer.
  final List<MediaSource> sources;

  /// Optional theme (accent color for icons).
  final MediaPickerTheme? theme;

  /// Sheet title.
  final String title;

  /// Creates a source chooser sheet.
  const MediaSourceSheet({
    super.key,
    required this.sources,
    this.theme,
    this.title = 'Add Photo',
  });

  /// Shows the sheet and returns the chosen source (or null if cancelled).
  static Future<MediaSource?> show(
    BuildContext context, {
    required List<MediaSource> sources,
    MediaPickerTheme? theme,
    String title = 'Add Photo',
  }) {
    return showModalBottomSheet<MediaSource>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          MediaSourceSheet(sources: sources, theme: theme, title: title),
    );
  }

  String _labelFor(MediaSource source) {
    switch (source) {
      case MediaSource.camera:
        return 'Take Photo';
      case MediaSource.gallery:
        return 'Choose from Gallery';
      case MediaSource.files:
        return 'Choose from Files';
    }
  }

  IconData _iconFor(MediaSource source) {
    switch (source) {
      case MediaSource.camera:
        return Icons.photo_camera_outlined;
      case MediaSource.gallery:
        return Icons.photo_library_outlined;
      case MediaSource.files:
        return Icons.folder_open_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = theme?.primaryColor ?? Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final source in sources)
            ListTile(
              leading: Icon(_iconFor(source), color: accent),
              title: Text(_labelFor(source)),
              onTap: () => Navigator.of(context).pop(source),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
