import 'package:flutter_test/flutter_test.dart';
import 'package:nw_media_picker/nw_media_picker.dart';

void main() {
  group('MediaPickerPresets', () {
    test('all presets validate', () {
      for (final preset in <MediaPickerConfig>[
        MediaPickerPresets.profilePhoto,
        MediaPickerPresets.squareImage,
        MediaPickerPresets.productPhoto,
        MediaPickerPresets.highQualityPhoto,
        MediaPickerPresets.documentPhoto,
      ]) {
        expect(preset.validate, returnsNormally);
      }
    });

    test('profilePhoto prefers the front camera and circular crop', () {
      const preset = MediaPickerPresets.profilePhoto;
      expect(preset.camera.preferredLens, CameraLens.front);
      expect(preset.processing.cropAspectRatio, 1);
      expect(preset.processing.maxWidth, 1000);
      expect(preset.crop.enabled, isTrue);
      expect(preset.crop.shape, CropShape.oval);
    });

    test('squareImage enables an interactive square crop', () {
      const preset = MediaPickerPresets.squareImage;
      expect(preset.crop.enabled, isTrue);
      expect(preset.crop.aspectRatio, 1);
      expect(preset.crop.lockAspectRatio, isTrue);
    });

    test('productPhoto uses the back camera at ~1600px', () {
      const preset = MediaPickerPresets.productPhoto;
      expect(preset.camera.preferredLens, CameraLens.back);
      expect(preset.processing.maxWidth, 1600);
    });

    test('highQualityPhoto uses higher quality and no forced crop', () {
      const preset = MediaPickerPresets.highQualityPhoto;
      expect(preset.processing.quality, 90);
      expect(preset.processing.cropAspectRatio, isNull);
    });
  });
}
