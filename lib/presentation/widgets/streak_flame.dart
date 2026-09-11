import 'package:flutter/material.dart';
import 'package:math_city/domain/economy/coin_economy.dart';

/// The answer streak as a single flame whose heat tracks the count: ash-grey
/// and slumped at 0, a small amber tongue at 1, brightening through orange
/// to red with extra tongues, a white-hot core and a glow from
/// [kStreakCap] on. Reads at a glance at AppBar size (~24 px) and as the
/// hero of the block-summary card.
class StreakFlame extends StatelessWidget {
  const StreakFlame({required this.count, this.size = 24, super.key});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _FlamePainter(count: count),
  );
}

/// Flame plus the count, for the question screen's AppBar. The number is
/// omitted at 0 so a fresh miss just shows the cold flame.
class StreakBadge extends StatelessWidget {
  const StreakBadge({required this.count, this.size = 24, super.key});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreakFlame(count: count, size: size),
        if (count > 0) ...[
          SizedBox(width: size * 0.15),
          Text(
            '$count',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

/// Kid-facing streak line for the summary card.
String streakHeadline(int count) => switch (count) {
  0 => 'Start a new streak!',
  1 => '1 in a row — keep going!',
  _ => '$count in a row!',
};

class _FlamePainter extends CustomPainter {
  const _FlamePainter({required this.count});

  final int count;

  static const _ash = Color(0xFFB9B9B9);
  static const _ashCore = Color(0xFFE0E0E0);
  static const _amber = Color(0xFFF2A33A);
  static const _orange = Color(0xFFF57C00);
  static const _red = Color(0xFFE53935);
  static const _coreYellow = Color(0xFFFFD54F);
  static const _coreWhite = Color(0xFFFFF8E1);

  /// Heat in [0, 1]: reaches 1 at [kStreakCap] and stays there.
  double get _heat => (count / kStreakCap).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final heat = _heat;
    final cold = count == 0;

    // Cold: a small, slumped grey flame. Hot: taller and fuller. A tongue
    // of width d stands 1.55 d tall, so the main flame's width is chosen to
    // keep the tip inside the box.
    final scale = cold ? 0.72 : 0.82 + 0.18 * heat;
    final base = Offset(w / 2, h * 0.96);
    final d = w * 0.58 * scale;

    final body = cold
        ? _ash
        : Color.lerp(_amber, _orange, (heat * 2).clamp(0.0, 1.0))!;
    final bodyHot = Color.lerp(body, _red, ((heat - 0.5) * 2).clamp(0.0, 1.0))!;
    final core = cold ? _ashCore : Color.lerp(_coreYellow, _coreWhite, heat)!;

    // Soft glow behind a full-heat flame, kept inside the box so it reads
    // as heat around the flame rather than a smudge on the card.
    if (heat >= 1) {
      canvas.drawCircle(
        base.translate(0, -h * 0.4),
        w * 0.3,
        Paint()
          ..color = _amber.withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.1),
      );
    }

    // Side tongues appear as the streak builds (from 3 and 5).
    if (count >= 3) {
      canvas.drawPath(
        _tongue(base.translate(-w * 0.24, -h * 0.02), d * 0.5),
        Paint()..color = bodyHot.withValues(alpha: 0.85),
      );
    }
    if (count >= kStreakCap) {
      canvas.drawPath(
        _tongue(base.translate(w * 0.25, -h * 0.05), d * 0.42),
        Paint()..color = bodyHot.withValues(alpha: 0.85),
      );
    }

    canvas
      ..drawPath(_tongue(base, d), Paint()..color = bodyHot)
      ..drawPath(
        _tongue(base.translate(0, -h * 0.03), d * 0.52),
        Paint()..color = core,
      );
  }

  /// A teardrop flame of width [d], bottom-centred on [foot], with a tip
  /// that leans slightly right so it doesn't read as a symmetric drop.
  Path _tongue(Offset foot, double d) {
    final r = d / 2;
    final tip = foot.translate(r * 0.18, -d * 1.55);
    return Path()
      ..moveTo(foot.dx, foot.dy)
      ..cubicTo(
        foot.dx - r * 1.25,
        foot.dy - d * 0.35,
        foot.dx - r * 0.55,
        foot.dy - d * 1.0,
        tip.dx,
        tip.dy,
      )
      ..cubicTo(
        foot.dx + r * 0.75,
        foot.dy - d * 0.95,
        foot.dx + r * 1.25,
        foot.dy - d * 0.35,
        foot.dx,
        foot.dy,
      )
      ..close();
  }

  @override
  bool shouldRepaint(_FlamePainter oldDelegate) => oldDelegate.count != count;
}
