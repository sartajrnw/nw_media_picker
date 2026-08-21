import 'package:flutter_test/flutter_test.dart';
import 'package:nw_media_picker/nw_media_picker.dart';

void main() {
  group('MediaPickerException', () {
    test('carries code, message and cause', () {
      final cause = StateError('root');
      final e = MediaPickerException(
        MediaPickerErrorCode.captureFailed,
        'failed',
        cause: cause,
      );
      expect(e.code, MediaPickerErrorCode.captureFailed);
      expect(e.message, 'failed');
      expect(e.cause, same(cause));
    });

    test('convenience constructors set the right codes', () {
      expect(
        const MediaPickerException.permissionDenied().code,
        MediaPickerErrorCode.permissionDenied,
      );
      expect(
        const MediaPickerException.permissionPermanentlyDenied().code,
        MediaPickerErrorCode.permissionPermanentlyDenied,
      );
      expect(
        const MediaPickerException.unsupportedPlatform().code,
        MediaPickerErrorCode.unsupportedPlatform,
      );
    });

    test('toString includes the code name and message', () {
      const e = MediaPickerException(
        MediaPickerErrorCode.processingFailed,
        'bad pixels',
      );
      expect(e.toString(), contains('processingFailed'));
      expect(e.toString(), contains('bad pixels'));
    });

    test('is an Exception', () {
      expect(
        const MediaPickerException(MediaPickerErrorCode.unknown, 'x'),
        isA<Exception>(),
      );
    });
  });
}
