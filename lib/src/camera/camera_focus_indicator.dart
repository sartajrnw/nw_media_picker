import 'package:flutter/material.dart';

/// A small square that briefly appears where the user tapped to focus, then
/// fades. Intentionally minimal, per the design guidance.
class CameraFocusIndicator extends StatefulWidget {
  /// Local position of the tap in the preview's coordinate space.
  final Offset position;

  /// Accent color for the indicator border.
  final Color color;

  /// Creates a focus indicator.
  const CameraFocusIndicator({
    super.key,
    required this.position,
    this.color = Colors.white,
  });

  @override
  State<CameraFocusIndicator> createState() => _CameraFocusIndicatorState();
}

class _CameraFocusIndicatorState extends State<CameraFocusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  static const double _size = 72;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - _size / 2,
      top: widget.position.dy - _size / 2,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.6, 1, curve: Curves.easeOut),
            ),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.25, end: 1).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut),
            ),
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                border: Border.all(color: widget.color, width: 1.5),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
