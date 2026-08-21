/// Configuration for gallery / file selection.
class GalleryPickerConfig {
  /// Whether multiple items may be selected.
  final bool allowMultiple;

  /// Optional cap on the number of items when [allowMultiple] is true.
  /// `null` means no explicit limit (the system picker may still impose one).
  final int? maxSelection;

  /// Creates an immutable gallery picker configuration.
  const GalleryPickerConfig({this.allowMultiple = false, this.maxSelection});

  /// Validates the configuration, throwing [ArgumentError] on invalid values.
  void validate() {
    if (maxSelection != null && maxSelection! < 1) {
      throw ArgumentError.value(
        maxSelection,
        'maxSelection',
        'must be >= 1 when provided',
      );
    }
  }

  /// Returns a copy with the given fields replaced.
  GalleryPickerConfig copyWith({bool? allowMultiple, int? maxSelection}) {
    return GalleryPickerConfig(
      allowMultiple: allowMultiple ?? this.allowMultiple,
      maxSelection: maxSelection ?? this.maxSelection,
    );
  }
}
