import 'package:flutter_test/flutter_test.dart';
import 'package:nw_media_picker/nw_media_picker.dart';

void main() {
  group('MediaResult', () {
    final result = MediaResult(
      path: '/tmp/a.jpg',
      source: MediaSource.camera,
      createdAt: DateTime(2026, 8, 21),
      sizeBytes: 2 * 1024 * 1024,
      width: 1600,
      height: 1200,
      mimeType: 'image/jpeg',
    );

    test('sizeMB derives from sizeBytes', () {
      expect(result.sizeMB, closeTo(2.0, 0.0001));
    });

    test('sizeMB is null when sizeBytes is unknown', () {
      final bare = MediaResult(
        path: '/tmp/a.jpg',
        source: MediaSource.camera,
        createdAt: DateTime(2026),
      );
      expect(bare.sizeMB, isNull);
    });

    test('source flags', () {
      expect(result.isCameraCapture, isTrue);
      expect(result.isGallerySelection, isFalse);
    });

    test('copyWith replaces only provided fields', () {
      final updated = result.copyWith(path: '/tmp/b.jpg', width: 800);
      expect(updated.path, '/tmp/b.jpg');
      expect(updated.width, 800);
      expect(updated.height, 1200);
      expect(updated.source, MediaSource.camera);
    });
  });

  group('MediaSource extension', () {
    test('isCamera / isGallery / isFiles', () {
      expect(MediaSource.camera.isCamera, isTrue);
      expect(MediaSource.gallery.isGallery, isTrue);
      expect(MediaSource.files.isFiles, isTrue);
    });
  });

  group('MediaCapabilities.none', () {
    test('is all-false', () {
      const caps = MediaCapabilities.none;
      expect(caps.camera, isFalse);
      expect(caps.gallery, isFalse);
      expect(caps.frontCamera, isFalse);
      expect(caps.backCamera, isFalse);
      expect(caps.multipleGallerySelection, isFalse);
    });
  });
}
