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

  group('InteractiveCropConfig', () {
    test('valid by default', () {
      expect(const InteractiveCropConfig().validate, returnsNormally);
    });

    test('rejects compressQuality out of range', () {
      expect(
        const InteractiveCropConfig(compressQuality: 0).validate,
        throwsArgumentError,
      );
      expect(
        const InteractiveCropConfig(compressQuality: 101).validate,
        throwsArgumentError,
      );
    });

    test('rejects non-positive aspect ratio', () {
      expect(
        const InteractiveCropConfig(aspectRatio: 0).validate,
        throwsArgumentError,
      );
    });

    test('rejects lockAspectRatio without an aspect ratio', () {
      expect(
        const InteractiveCropConfig(lockAspectRatio: true).validate,
        throwsArgumentError,
      );
    });

    test('square and circle presets are aspect-locked at 1:1', () {
      expect(InteractiveCropConfig.square.aspectRatio, 1);
      expect(InteractiveCropConfig.square.lockAspectRatio, isTrue);
      expect(InteractiveCropConfig.circle.shape, CropShape.oval);
    });

    test('disabled preset is disabled', () {
      expect(InteractiveCropConfig.disabled.enabled, isFalse);
    });

    test('copyWith replaces fields', () {
      const base = InteractiveCropConfig();
      final updated = base.copyWith(aspectRatio: 1.5, showGrid: false);
      expect(updated.aspectRatio, 1.5);
      expect(updated.showGrid, isFalse);
      expect(updated.compressQuality, base.compressQuality);
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

    test('cascades validation to the crop config', () {
      const config = MediaPickerConfig(
        crop: InteractiveCropConfig(compressQuality: 0),
      );
      expect(config.validate, throwsArgumentError);
    });

    test('crop is disabled by default', () {
      expect(const MediaPickerConfig().crop.enabled, isFalse);
    });
  });
}
