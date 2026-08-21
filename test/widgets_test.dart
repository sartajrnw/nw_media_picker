import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nw_media_picker/nw_media_picker.dart';
import 'package:nw_media_picker/src/widgets/camera_error_view.dart';
import 'package:nw_media_picker/src/widgets/media_preview_page.dart';
import 'package:nw_media_picker/src/widgets/media_source_sheet.dart';
import 'package:nw_media_picker/src/widgets/permission_error_view.dart';

void main() {
  group('MediaSourceSheet', () {
    testWidgets('shows an entry per source and returns the chosen one', (
      tester,
    ) async {
      MediaSource? chosen;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  chosen = await MediaSourceSheet.show(
                    context,
                    sources: const [MediaSource.camera, MediaSource.gallery],
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);

      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();
      expect(chosen, MediaSource.camera);
    });
  });

  group('MediaPreviewPage', () {
    testWidgets('Use returns true, Retake returns false', (tester) async {
      Future<bool?> pushPreview(WidgetTester tester) async {
        bool? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => MediaPreviewPage(
                        result: MediaResult(
                          path: '/nonexistent.jpg',
                          source: MediaSource.camera,
                          createdAt: DateTime(2026),
                        ),
                        theme: const MediaPickerTheme(),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        return result;
      }

      await pushPreview(tester);
      expect(find.text('Use Photo'), findsOneWidget);
      expect(find.text('Retake'), findsOneWidget);

      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();
      // Back on the launcher screen.
      expect(find.text('open'), findsOneWidget);
    });
  });

  group('PermissionErrorView', () {
    testWidgets('shows Open Settings only when permanently denied', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionErrorView(
              theme: const MediaPickerTheme(),
              permanentlyDenied: true,
              showGalleryOption: true,
              onOpenSettings: () {},
              onChooseFromGallery: () {},
              onCancel: () {},
            ),
          ),
        ),
      );
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('hides Open Settings when merely denied', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionErrorView(
              theme: const MediaPickerTheme(),
              permanentlyDenied: false,
              showGalleryOption: false,
              onOpenSettings: () {},
              onChooseFromGallery: () {},
              onCancel: () {},
            ),
          ),
        ),
      );
      expect(find.text('Open Settings'), findsNothing);
      expect(find.text('Choose from Gallery'), findsNothing);
    });
  });

  group('CameraErrorView', () {
    testWidgets('renders message and retry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraErrorView(
              theme: const MediaPickerTheme(),
              message: 'Unable to start the camera.',
              showGalleryOption: false,
              onRetry: () => retried = true,
              onChooseFromGallery: () {},
              onCancel: () {},
            ),
          ),
        ),
      );
      expect(find.text('Unable to start the camera.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });
}
