import 'package:flutter_test/flutter_test.dart';
import 'package:nw_media_picker/src/utils/media_file_utils.dart';

void main() {
  group('MediaFileUtils.buildUniqueFileName', () {
    test('produces the documented timestamped format', () {
      final name = MediaFileUtils.buildUniqueFileName(
        now: DateTime(2026, 8, 21, 11, 45, 30, 123, 456),
      );
      expect(name, startsWith('nw_media_20260821_114530_'));
      expect(name, endsWith('.jpg'));
    });

    test('honors custom prefix and extension', () {
      final name = MediaFileUtils.buildUniqueFileName(
        prefix: 'shot',
        extension: 'png',
        now: DateTime(2026, 1, 2, 3, 4, 5),
      );
      expect(name, 'shot_20260102_030405_000000.png');
    });

    test('strips a leading dot from the extension', () {
      final name = MediaFileUtils.buildUniqueFileName(
        extension: '.jpeg',
        now: DateTime(2026, 1, 2, 3, 4, 5),
      );
      expect(name, endsWith('.jpeg'));
      expect(name.contains('..'), isFalse);
    });

    test('names differ across distinct timestamps', () {
      final a = MediaFileUtils.buildUniqueFileName(
        now: DateTime(2026, 1, 1, 0, 0, 0, 0, 1),
      );
      final b = MediaFileUtils.buildUniqueFileName(
        now: DateTime(2026, 1, 1, 0, 0, 0, 0, 2),
      );
      expect(a, isNot(b));
    });
  });

  group('MediaFileUtils helpers', () {
    test('extensionOf lower-cases and drops the dot', () {
      expect(MediaFileUtils.extensionOf('/a/b/PHOTO.JPG'), 'jpg');
      expect(MediaFileUtils.extensionOf('/a/b/noext'), '');
    });

    test('mimeTypeForPath infers from extension', () {
      expect(MediaFileUtils.mimeTypeForPath('x.png'), 'image/png');
      expect(MediaFileUtils.mimeTypeForPath('x.jpg'), 'image/jpeg');
    });
  });
}
