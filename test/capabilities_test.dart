import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nw_media_picker/nw_media_picker.dart';
import 'package:nw_media_picker/src/core/platform_resolver.dart';
import 'package:nw_media_picker/src/utils/media_temp_manager.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PlatformResolver resolverFor(TargetPlatform platform) {
    return PlatformResolver(
      tempManager: MediaTempManager(logger: const SilentMediaPickerLogger()),
      permissionService: const PermissionService(
        logger: SilentMediaPickerLogger(),
      ),
      logger: const SilentMediaPickerLogger(),
      platform: platform,
      galleryAdapter: FakeGalleryAdapter(available: true),
    );
  }

  test('desktop reports no camera, gallery available', () async {
    final resolver = resolverFor(TargetPlatform.windows);
    final caps = await resolver.capabilities();
    expect(caps.camera, isFalse);
    expect(caps.frontCamera, isFalse);
    expect(caps.backCamera, isFalse);
    expect(caps.gallery, isTrue);
    expect(caps.multipleGallerySelection, isTrue);
  });

  test('desktop is not treated as mobile', () {
    expect(resolverFor(TargetPlatform.linux).isMobile, isFalse);
    expect(resolverFor(TargetPlatform.macOS).isMobile, isFalse);
  });

  test('android/iOS are treated as mobile', () {
    expect(resolverFor(TargetPlatform.android).isMobile, isTrue);
    expect(resolverFor(TargetPlatform.iOS).isMobile, isTrue);
  });

  test('resolves the desktop camera adapter as unavailable', () async {
    final resolver = resolverFor(TargetPlatform.windows);
    final adapter = resolver.resolveCameraAdapter(
      config: const CameraCaptureConfig(),
      theme: const MediaPickerTheme(),
      showPreviewAfterCapture: true,
    );
    expect(await adapter.isAvailable(), isFalse);
  });
}
