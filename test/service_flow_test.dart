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
      callbacks: callbacks,
    );
  }

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

  group('capabilities', () {
    test('delegates to the resolver', () async {
      final service = serviceWith(FakeGalleryAdapter(available: true));
      final caps = await service.capabilities();
      expect(caps.gallery, isTrue);
    });
  });
}
