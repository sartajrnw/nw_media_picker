import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../logging/media_picker_logger.dart';
import 'media_file_utils.dart';

/// Owns the package's temporary working directory and its lifecycle.
///
/// All intermediate and output files the package writes live under a single
/// predictable directory (`<cache>/nw_media_picker/`) so they can be cleared
/// deterministically without touching unrelated app files.
///
/// Returned [String] paths may point inside this temporary directory —
/// applications that need long-term storage must copy/persist the file.
class MediaTempManager {
  /// Name of the package's subdirectory inside the system cache dir.
  static const String directoryName = 'nw_media_picker';

  final MediaPickerLogger _logger;

  Directory? _cachedDir;

  /// Creates a temp manager with an optional [logger].
  MediaTempManager({MediaPickerLogger logger = const DebugMediaPickerLogger()})
    : _logger = logger;

  /// Resolves (creating if needed) the package temporary directory.
  Future<Directory> directory() async {
    final cached = _cachedDir;
    if (cached != null && await cached.exists()) return cached;

    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, directoryName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachedDir = dir;
    return dir;
  }

  /// Allocates a fresh, unique output file path inside the temp directory.
  ///
  /// The file is not created; only the path is reserved.
  Future<String> newFilePath({
    String prefix = 'nw_media',
    String extension = 'jpg',
    DateTime? now,
  }) async {
    final dir = await directory();
    final name = MediaFileUtils.buildUniqueFileName(
      prefix: prefix,
      extension: extension,
      now: now,
    );
    return p.join(dir.path, name);
  }

  /// Deletes all files in the package temporary directory.
  Future<void> clear() async {
    try {
      final dir = await directory();
      if (!await dir.exists()) return;
      await for (final entity in dir.list()) {
        try {
          await entity.delete(recursive: true);
        } on FileSystemException catch (e) {
          _logger.warning('Failed to delete temp entity ${entity.path}: $e');
        }
      }
      _logger.debug('Cleared temporary media directory.');
    } on FileSystemException catch (e, s) {
      _logger.error('Failed to clear temp directory', error: e, stackTrace: s);
    }
  }

  /// Total size, in bytes, of the package temporary directory.
  Future<int> size() async {
    var total = 0;
    try {
      final dir = await directory();
      if (!await dir.exists()) return 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          try {
            total += await entity.length();
          } on FileSystemException {
            // Skip files that vanished mid-iteration.
          }
        }
      }
    } on FileSystemException catch (e, s) {
      _logger.error('Failed to size temp directory', error: e, stackTrace: s);
    }
    return total;
  }
}
