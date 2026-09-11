import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_city/presentation/theme/app_palette.dart';
import 'package:math_city/presentation/widgets/coin_icon.dart';

/// A coin (with its `+N`) arcing from [from] to [to] in global coordinates,
/// shrinking and fading as it lands. Insert in an [Overlay]; remove the
/// entry after [duration].
class CoinFlight extends StatefulWidget {
  const CoinFlight({
    required this.from,
    required this.to,
    required this.amount,
    this.duration = const Duration(milliseconds: 650),
    super.key,
  });

  final Offset from;
  final Offset to;
  final int amount;
  final Duration duration;

  @override
  State<CoinFlight> createState() => _CoinFlightState();
}

class _CoinFlightState extends State<CoinFlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: widget.duration, vsync: this);
    unawaited(_ctrl.forward());
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) {
        final t = _anim.value;
        final linear = Offset.lerp(widget.from, widget.to, t)!;
        // Arc upward at the midpoint.
        final arcY = math.sin(t * math.pi) * -80.0;
        final pos = Offset(linear.dx, linear.dy + arcY);
        final scale = 1.0 - 0.5 * t;
        final opacity = t > 0.8 ? (1.0 - t) / 0.2 : 1.0;

        return Positioned(
          left: pos.dx,
          top: pos.dy,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: IgnorePointer(
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: CoinAmount(
                    amount: widget.amount,
                    prefix: '+',
                    iconSize: 36,
                    style: TextStyle(
                      color: palette.coinGoldDeep,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      // Overlay entries sit outside the Scaffold's
                      // DefaultTextStyle, which would otherwise underline.
                      decoration: TextDecoration.none,
                      shadows: const [
                        Shadow(color: Color(0x66000000), blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
