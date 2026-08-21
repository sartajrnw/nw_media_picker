// Integration tests run inside a full Flutter app, so they can exercise the
// real platform channels behind the package (camera enumeration, temp storage,
// capability detection).
//
// Device-specific camera capture/lifecycle behavior requires manual QA — see
// `MANUAL_QA.md` at the package root.
//
// Run with:  flutter test integration_test

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nw_media_picker/nw_media_picker.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capabilities() returns a coherent report on-device', (
    tester,
  ) async {
    final caps = await NWMediaPicker.capabilities();

    // Gallery selection is expected on every supported platform.
    expect(caps.gallery, isTrue);

    // If any lens is present, camera must be reported available (and vice
    // versa) — the flags must be internally consistent.
    final anyLens = caps.frontCamera || caps.backCamera;
    expect(caps.camera, anyLens);
  });

  testWidgets('temporary cache can be sized and cleared without error', (
    tester,
  ) async {
    final sizeBefore = await NWMediaPicker.getTemporaryCacheSize();
    expect(sizeBefore, greaterThanOrEqualTo(0));

    await NWMediaPicker.clearTemporaryFiles();

    final sizeAfter = await NWMediaPicker.getTemporaryCacheSize();
    expect(sizeAfter, greaterThanOrEqualTo(0));
  });
}
