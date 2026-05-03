import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_dash/data/database.dart';
import 'package:math_dash/domain/avatar/avatar_config.dart';
import 'package:math_dash/presentation/player/avatar_widget.dart';
import 'package:math_dash/presentation/player/player_launcher_screen.dart';
import 'package:math_dash/presentation/spin/spin_screen.dart';
import 'package:math_dash/state/game_session_provider.dart';
import 'package:math_dash/state/player_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stars = ref.watch(totalStarsProvider);
    final playerAsync = ref.watch(activePlayerProvider);
    final theme = Theme.of(context);

    final playerName = playerAsync.asData?.value.name ?? '';
    final avatarConfig =
        playerAsync.asData?.value.avatar ?? const AvatarConfig();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Math Dash',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Player banner
              _PlayerBanner(
                name: playerName,
                avatarConfig: avatarConfig,
                stars: stars,
                onSwitch: () {
                  ref.read(activePlayerIdProvider.notifier).selected = null;
                  unawaited(
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const PlayerLauncherScreen(),
                      ),
                      (route) => false,
                    ),
                  );
                },
              ),

              const Spacer(),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SpinScreen(),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Spin!'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerBanner extends StatelessWidget {
  const _PlayerBanner({
    required this.name,
    required this.avatarConfig,
    required this.stars,
    required this.onSwitch,
  });

  final String name;
  final AvatarConfig avatarConfig;
  final int stars;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AvatarWidget(config: avatarConfig, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$stars stars',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onSwitch,
              child: const Text('Switch'),
            ),
          ],
        ),
      ),
    );
  }
}
