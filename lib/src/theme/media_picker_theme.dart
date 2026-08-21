import 'package:flutter/material.dart';

/// Visual theming for the package's built-in UI (camera screen, source sheet,
/// preview, error views).
///
/// The package never hardcodes any application's brand. Apps supply their own
/// colors, or rely on the defaults, or let the package inherit from the host
/// [ThemeData] via [MediaPickerTheme.fromTheme].
@immutable
class MediaPickerTheme {
  /// Accent color used for primary actions and highlights (e.g. capture ring).
  final Color primaryColor;

  /// Background color for full-screen surfaces (camera, preview).
  final Color backgroundColor;

  /// Foreground color for icons/text on [backgroundColor].
  final Color foregroundColor;

  /// Optional scrim/overlay color drawn above the preview.
  final Color? overlayColor;

  /// Diameter, in logical pixels, of the capture button.
  final double captureButtonSize;

  /// Creates a media picker theme.
  const MediaPickerTheme({
    this.primaryColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.foregroundColor = Colors.white,
    this.overlayColor,
    this.captureButtonSize = 72,
  });

  /// Derives a sensible theme from the host application's [ThemeData].
  ///
  /// The camera and preview surfaces stay dark (that is the expected camera
  /// UX) while the accent color follows the app's [ColorScheme.primary].
  factory MediaPickerTheme.fromTheme(ThemeData theme) {
    return MediaPickerTheme(
      primaryColor: theme.colorScheme.primary,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    );
  }

  /// Returns a copy with the given fields replaced.
  MediaPickerTheme copyWith({
    Color? primaryColor,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? overlayColor,
    double? captureButtonSize,
  }) {
    return MediaPickerTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      overlayColor: overlayColor ?? this.overlayColor,
      captureButtonSize: captureButtonSize ?? this.captureButtonSize,
    );
  }
}
