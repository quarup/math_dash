import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_dash/data/database.dart';
import 'package:math_dash/presentation/home/home_screen.dart';
import 'package:math_dash/presentation/player/avatar_widget.dart';
import 'package:math_dash/presentation/player/player_creation_screen.dart';
import 'package:math_dash/state/player_provider.dart';

/// Entry point on every app launch.
/// Shows a profile picker when players exist, or the creation screen otherwise.
class PlayerLauncherScreen extends ConsumerWidget {
  const PlayerLauncherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allPlayersProvider);

    return allAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error loading players: $e')),
      ),
      data: (players) {
        if (players.isEmpty) {
          return const PlayerCreationScreen(isFirstPlayer: true);
        }
        return _PickerScreen(players: players);
      },
    );
  }
}

class _PickerScreen extends ConsumerWidget {
  const _PickerScreen({required this.players});

  final List<Player> players;

  void _select(BuildContext context, WidgetRef ref, Player player) {
    ref.read(activePlayerIdProvider.notifier).selected = player.id;
    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Who's playing?",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView.separated(
                  itemCount: players.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _PlayerCard(
                    player: players[i],
                    onTap: () => _select(context, ref, players[i]),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PlayerCreationScreen(),
                  ),
                ),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Add Player'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.player, required this.onTap});

  final Player player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AvatarWidget(config: player.avatar, size: 60),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Grade ${player.gradeLevel}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${player.totalStars}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
