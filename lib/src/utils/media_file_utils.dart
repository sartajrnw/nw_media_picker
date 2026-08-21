import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// Small, stateless helpers for file naming and metadata inference.
class MediaFileUtils {
  const MediaFileUtils._();

  /// Two-digit zero padding.
  static String _pad2(int v) => v.toString().padLeft(2, '0');

  /// Builds a unique, collision-resistant file name.
  ///
  /// Format: `nw_media_YYYYMMDD_HHMMSS_mmmuuu.<ext>` where the trailing group
  /// is milliseconds + microseconds for intra-second uniqueness. A [now] can be
  /// injected for deterministic tests.
  static String buildUniqueFileName({
    String prefix = 'nw_media',
    String extension = 'jpg',
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    final micros = t.microsecond.toString().padLeft(3, '0');
    final millis = t.millisecond.toString().padLeft(3, '0');
    final stamp =
        '${t.year}${_pad2(t.month)}${_pad2(t.day)}_'
        '${_pad2(t.hour)}${_pad2(t.minute)}${_pad2(t.second)}_'
        '$millis$micros';
    return '${prefix}_$stamp.$ext';
  }

  /// Best-effort MIME type from a file path/extension.
  static String? mimeTypeForPath(String path) => lookupMimeType(path);

  /// The lower-cased extension (without the dot) for [path], or empty string.
  static String extensionOf(String path) {
    final ext = p.extension(path);
    return ext.isEmpty ? '' : ext.substring(1).toLowerCase();
  }

  /// The file name portion of [path].
  static String fileNameOf(String path) => p.basename(path);

  /// Size of the file at [path] in bytes, or `null` if it cannot be read.
  static int? sizeBytesOf(String path) {
    try {
      final f = File(path);
      return f.existsSync() ? f.lengthSync() : null;
    } on FileSystemException {
      return null;
    }
  }
}
