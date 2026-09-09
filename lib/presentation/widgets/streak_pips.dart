import 'package:flutter/material.dart';
import 'package:math_city/domain/economy/coin_economy.dart';
import 'package:math_city/presentation/theme/app_palette.dart';

/// The answer streak as a row of [kStreakCap] pips, filled up to [level].
/// Reads at a glance in an AppBar (tiny) or on the summary card (larger).
class StreakPips extends StatelessWidget {
  const StreakPips({required this.level, this.dotSize = 8, super.key});

  final int level;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final on = palette.streakOrange;
    final off = theme.colorScheme.onSurface.withValues(alpha: 0.18);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < kStreakCap; i++)
          Padding(
            padding: EdgeInsets.only(
              right: i == kStreakCap - 1 ? 0 : dotSize * 0.4,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: i < level ? on : off,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
