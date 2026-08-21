import 'package:flutter_test/flutter_test.dart';
import 'package:nw_media_picker/nw_media_picker.dart';

void main() {
  group('ImageProcessingConfig', () {
    test('accepts valid values', () {
      const config = ImageProcessingConfig(quality: 85, maxWidth: 1600);
      expect(config.validate, returnsNormally);
    });

    test('rejects quality below 1', () {
      const config = ImageProcessingConfig(quality: 0);
      expect(config.validate, throwsArgumentError);
    });

    test('rejects quality above 100', () {
      const config = ImageProcessingConfig(quality: 101);
      expect(config.validate, throwsArgumentError);
    });

    test('rejects non-positive dimensions', () {
      expect(
        const ImageProcessingConfig(maxWidth: 0).validate,
        throwsArgumentError,
      );
      expect(
        const ImageProcessingConfig(maxHeight: -10).validate,
        throwsArgumentError,
      );
    });

    test('rejects non-positive crop ratio', () {
      expect(
        const ImageProcessingConfig(cropAspectRatio: 0).validate,
        throwsArgumentError,
      );
    });

    test('requiresProcessing is false for a true pass-through', () {
      expect(ImageProcessingConfig.none.requiresProcessing, isFalse);
    });

    test('requiresProcessing is true when resizing/compressing', () {
      const config = ImageProcessingConfig(maxWidth: 1600);
      expect(config.requiresProcessing, isTrue);
    });
  });

  group('CameraCaptureConfig', () {
    test('valid by default', () {
      expect(const CameraCaptureConfig().validate, returnsNormally);
    });

    test('rejects non-positive zoom bounds', () {
      expect(
        const CameraCaptureConfig(minimumZoom: 0).validate,
        throwsArgumentError,
      );
      expect(
        const CameraCaptureConfig(maximumZoom: -1).validate,
        throwsArgumentError,
      );
    });

    test('rejects min zoom greater than max zoom', () {
      expect(
        const CameraCaptureConfig(minimumZoom: 5, maximumZoom: 2).validate,
        throwsArgumentError,
      );
    });
  });

  group('GalleryPickerConfig', () {
    test('rejects maxSelection < 1', () {
      expect(
        const GalleryPickerConfig(maxSelection: 0).validate,
        throwsArgumentError,
      );
    });

    test('accepts null maxSelection', () {
      expect(
        const GalleryPickerConfig(allowMultiple: true).validate,
        returnsNormally,
      );
    });
  });

  group('MediaPickerConfig', () {
    test('rejects empty sources', () {
      expect(
        const MediaPickerConfig(sources: []).validate,
        throwsArgumentError,
      );
    });

    test('exposes source flags', () {
      const config = MediaPickerConfig(sources: [MediaSource.camera]);
      expect(config.hasCamera, isTrue);
      expect(config.hasGallery, isFalse);
    });

    test('cascades validation to nested configs', () {
      const config = MediaPickerConfig(
        processing: ImageProcessingConfig(quality: 200),
      );
      expect(config.validate, throwsArgumentError);
    });
  });
}
