import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nw_media_picker/nw_media_picker.dart';
import 'package:nw_media_picker/src/core/platform_resolver.dart';
import 'package:nw_media_picker/src/utils/media_temp_manager.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const logger = SilentMediaPickerLogger();
  final temp = MediaTempManager(logger: logger);

  MediaResult sampleRaw() => MediaResult(
    path: '/tmp/x.jpg',
    source: MediaSource.gallery,
    createdAt: DateTime(2026),
  );

  NWMediaPickerService serviceWith(
    FakeGalleryAdapter gallery, {
    PassThroughProcessor? processor,
    ImageCropperAdapter? cropper,
    MediaPickerCallbacks callbacks = const MediaPickerCallbacks(),
  }) {
    final resolver = PlatformResolver(
      tempManager: temp,
      permissionService: const PermissionService(logger: logger),
      logger: logger,
      platform: TargetPlatform.android,
      galleryAdapter: gallery,
    );
    return NWMediaPickerService(
      logger: logger,
      tempManager: temp,
      processor: processor ?? PassThroughProcessor(),
      resolver: resolver,
      cropper: cropper,
      callbacks: callbacks,
    );
  }

  const cropOn = MediaPickerConfig(crop: InteractiveCropConfig());

  group('gallery flow', () {
    test('returns null when the user cancels (adapter returns null)', () async {
      final service = serviceWith(FakeGalleryAdapter(single: null));
      expect(await service.gallery(), isNull);
    });

    test('processes and returns the selected image', () async {
      final processor = PassThroughProcessor();
      final service = serviceWith(
        FakeGalleryAdapter(single: sampleRaw()),
        processor: processor,
      );
      final result = await service.gallery();
      expect(result, isNotNull);
      expect(result!.source, MediaSource.gallery);
      expect(processor.calls, 1);
    });

    test('normalizes adapter errors into MediaPickerException', () async {
      final service = serviceWith(
        FakeGalleryAdapter(throwError: StateError('boom')),
      );
      expect(() => service.gallery(), throwsA(isA<MediaPickerException>()));
    });

    test('rethrows an already-normalized MediaPickerException as-is', () async {
      final service = serviceWith(
        FakeGalleryAdapter(
          throwError: const MediaPickerException(
            MediaPickerErrorCode.galleryUnavailable,
            'nope',
          ),
        ),
      );
      await expectLater(
        service.gallery(),
        throwsA(
          isA<MediaPickerException>().having(
            (e) => e.code,
            'code',
            MediaPickerErrorCode.galleryUnavailable,
          ),
        ),
      );
    });
  });

  group('multi gallery flow', () {
    test('returns empty list on cancel and fires onCancelled', () async {
      var cancelled = false;
      final service = serviceWith(
        FakeGalleryAdapter(multiple: const []),
        callbacks: MediaPickerCallbacks(onCancelled: () => cancelled = true),
      );
      final results = await service.galleryMultiple();
      expect(results, isEmpty);
      expect(cancelled, isTrue);
    });

    test('processes every selected item', () async {
      final processor = PassThroughProcessor();
      final service = serviceWith(
        FakeGalleryAdapter(multiple: [sampleRaw(), sampleRaw(), sampleRaw()]),
        processor: processor,
      );
      final results = await service.galleryMultiple();
      expect(results.length, 3);
      expect(processor.calls, 3);
    });
  });

  group('interactive crop flow', () {
    test('is skipped entirely when crop is disabled', () async {
      final cropper = FakeCropAdapter();
      final service = serviceWith(
        FakeGalleryAdapter(single: sampleRaw()),
        cropper: cropper,
      );
      final result = await service.gallery(); // default config: crop disabled
      expect(result, isNotNull);
      expect(cropper.calls, 0);
    });

    test('crops before processing and returns the cropped path', () async {
      final cropper = FakeCropAdapter(croppedPath: '/tmp/cropped.jpg');
      final service = serviceWith(
        FakeGalleryAdapter(single: sampleRaw()),
        cropper: cropper,
      );
      final result = await service.gallery(config: cropOn);
      expect(cropper.calls, 1);
      expect(result!.path, '/tmp/cropped.jpg');
      expect(result.mimeType, 'image/jpeg');
    });

    test('fires onCropStarted and onCropCompleted', () async {
      var started = false;
      MediaResult? completed;
      final service = serviceWith(
        FakeGalleryAdapter(single: sampleRaw()),
        cropper: FakeCropAdapter(),
        callbacks: MediaPickerCallbacks(
          onCropStarted: () => started = true,
          onCropCompleted: (r) => completed = r,
        ),
      );
      await service.gallery(config: cropOn);
      expect(started, isTrue);
      expect(completed, isNotNull);
    });

    test('cancelling the crop aborts the flow and fires onCancelled', () async {
      var cancelled = false;
      final service = serviceWith(
        FakeGalleryAdapter(single: sampleRaw()),
        cropper: FakeCropAdapter(returnsNull: true),
        callbacks: MediaPickerCallbacks(onCancelled: () => cancelled = true),
      );
      final result = await service.gallery(config: cropOn);
      expect(result, isNull);
      expect(cancelled, isTrue);
    });

    test('cancelReturnsOriginal keeps the uncropped image', () async {
      final processor = PassThroughProcessor();
      final service = serviceWith(
        FakeGalleryAdapter(single: sampleRaw()),
        processor: processor,
        cropper: FakeCropAdapter(returnsNull: true),
      );
      const config = MediaPickerConfig(
        crop: InteractiveCropConfig(cancelReturnsOriginal: true),
      );
      final result = await service.gallery(config: config);
      expect(result, isNotNull);
      expect(result!.path, '/tmp/x.jpg'); // original, untouched
      expect(processor.calls, 1);
    });

    test('crop failures surface as MediaPickerException', () async {
      final service = serviceWith(
        FakeGalleryAdapter(single: sampleRaw()),
        cropper: FakeCropAdapter(throwError: StateError('cropper boom')),
      );
      await expectLater(
        service.gallery(config: cropOn),
        throwsA(isA<MediaPickerException>()),
      );
    });

    test('multi-select crops each item and skips cancelled ones', () async {
      // Returns null once (cancel) then a real path for the rest.
      final cropper = _SequenceCropAdapter([null, '/tmp/c2.jpg', '/tmp/c3.jpg']);
      final processor = PassThroughProcessor();
      final service = serviceWith(
        FakeGalleryAdapter(multiple: [sampleRaw(), sampleRaw(), sampleRaw()]),
        processor: processor,
        cropper: cropper,
      );
      final results = await service.galleryMultiple(config: cropOn);
      expect(cropper.calls, 3);
      expect(results.length, 2); // the cancelled one was skipped
      expect(processor.calls, 2);
    });
  });

  group('capabilities', () {
    test('delegates to the resolver', () async {
      final service = serviceWith(FakeGalleryAdapter(available: true));
      final caps = await service.capabilities();
      expect(caps.gallery, isTrue);
    });
  });
}

/// A crop adapter that returns a scripted sequence of results across calls.
class _SequenceCropAdapter implements ImageCropperAdapter {
  final List<String?> _results;
  int calls = 0;

  _SequenceCropAdapter(this._results);

  @override
  Future<String?> crop({
    required String imagePath,
    required InteractiveCropConfig config,
  }) async {
    return _results[calls++];
  }
}
