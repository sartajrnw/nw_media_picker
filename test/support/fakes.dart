import 'package:nw_media_picker/nw_media_picker.dart';

/// A gallery adapter whose behavior is fully scripted for tests.
class FakeGalleryAdapter implements GalleryPickerAdapter {
  MediaResult? single;
  List<MediaResult> multiple;
  Object? throwError;
  bool available;

  FakeGalleryAdapter({
    this.single,
    this.multiple = const [],
    this.throwError,
    this.available = true,
  });

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<MediaResult?> pickImage({required GalleryPickerConfig config}) async {
    if (throwError != null) throw throwError!;
    return single;
  }

  @override
  Future<List<MediaResult>> pickMultipleImages({
    required GalleryPickerConfig config,
  }) async {
    if (throwError != null) throw throwError!;
    return multiple;
  }
}

/// An image processor that returns its input unchanged (no native calls).
class PassThroughProcessor implements ImageProcessor {
  int calls = 0;

  @override
  Future<MediaResult> process(
    MediaResult input,
    ImageProcessingConfig config,
  ) async {
    calls++;
    return input;
  }
}
