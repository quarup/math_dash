import 'package:flutter/material.dart';
import 'package:math_dash/domain/avatar/avatar_config.dart';

/// Renders a simple chibi-style character from an [AvatarConfig].
/// No external assets needed — everything is drawn with CustomPainter.
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({required this.config, this.size = 80, super.key});

  final AvatarConfig config;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AvatarPainter(config)),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter(this.config);

  final AvatarConfig config;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Hair (behind head) then head.
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.20),
          width: w * 0.86,
          height: h * 0.46,
        ),
        Paint()..color = config.hairColor,
      )
      ..drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.33),
          width: w * 0.78,
          height: h * 0.58,
        ),
        Paint()..color = config.skinTone,
      );

    // Eyes: white sclera, coloured iris, dark pupil.
    for (final cx in [w * 0.36, w * 0.64]) {
      final eyeCenter = Offset(cx, h * 0.315);
      canvas
        ..drawCircle(eyeCenter, w * 0.088, Paint()..color = Colors.white)
        ..drawCircle(eyeCenter, w * 0.066, Paint()..color = config.eyeColor)
        ..drawCircle(
          eyeCenter,
          w * 0.030,
          Paint()..color = const Color(0xFF1A1A1A),
        );
    }

    // Neck, shirt, and both legs — single cascade for body elements.
    canvas
      ..drawRect(
        Rect.fromLTWH(w * 0.43, h * 0.60, w * 0.14, h * 0.055),
        Paint()..color = config.skinTone,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.12, h * 0.645, w * 0.76, h * 0.175),
          Radius.circular(w * 0.08),
        ),
        Paint()..color = config.topColor,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.15, h * 0.815, w * 0.29, h * 0.185),
          Radius.circular(w * 0.04),
        ),
        Paint()..color = config.bottomColor,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.56, h * 0.815, w * 0.29, h * 0.185),
          Radius.circular(w * 0.04),
        ),
        Paint()..color = config.bottomColor,
      );
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => config != old.config;
}
