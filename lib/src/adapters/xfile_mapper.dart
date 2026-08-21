import 'package:cross_file/cross_file.dart';

import '../models/media_result.dart';
import '../models/media_source.dart';
import '../utils/media_file_utils.dart';

/// Internal helper translating a plugin [XFile] into a package [MediaResult].
///
/// This is the single boundary where third-party file types are converted into
/// the package's own model, so no plugin type ever leaks to consumers.
class XFileMapper {
  const XFileMapper._();

  /// Builds a raw (unprocessed) [MediaResult] from [file].
  ///
  /// [now] can be injected for deterministic tests.
  static Future<MediaResult> toMediaResult(
    XFile file, {
    required MediaSource source,
    DateTime? now,
  }) async {
    int? size;
    try {
      size = await file.length();
    } catch (_) {
      size = MediaFileUtils.sizeBytesOf(file.path);
    }
    return MediaResult(
      path: file.path,
      source: source,
      createdAt: now ?? DateTime.now(),
      mimeType: file.mimeType ?? MediaFileUtils.mimeTypeForPath(file.path),
      sizeBytes: size,
      originalFileName: file.name,
    );
  }
}
