import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_dash/domain/avatar/avatar_config.dart';
import 'package:math_dash/presentation/home/home_screen.dart';
import 'package:math_dash/presentation/player/avatar_widget.dart';
import 'package:math_dash/state/player_provider.dart';

class PlayerCreationScreen extends ConsumerStatefulWidget {
  /// [isFirstPlayer] hides the back button when no players exist yet.
  const PlayerCreationScreen({this.isFirstPlayer = false, super.key});

  final bool isFirstPlayer;

  @override
  ConsumerState<PlayerCreationScreen> createState() =>
      _PlayerCreationScreenState();
}

class _PlayerCreationScreenState extends ConsumerState<PlayerCreationScreen> {
  final _nameController = TextEditingController();
  AvatarConfig _config = const AvatarConfig();
  int _grade = 2;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);

    final db = ref.read(appDatabaseProvider);
    final player = await db.createPlayer(
      name: name,
      gradeLevel: _grade,
      avatarConfigJson: _config.toJsonString(),
    );

    ref.read(activePlayerIdProvider.notifier).selected = player.id;
    ref.invalidate(allPlayersProvider);

    if (!mounted) return;
    unawaited(
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (route) => false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameOk = _nameController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('New Player'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !widget.isFirstPlayer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar preview
              Center(child: AvatarWidget(config: _config, size: 120)),
              const SizedBox(height: 24),

              // Name field
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Grade picker
              Text('Grade', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(8, (i) {
                  final g = i + 1;
                  return ChoiceChip(
                    label: Text('$g'),
                    selected: _grade == g,
                    onSelected: (_) => setState(() => _grade = g),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Colour pickers
              _colorRow(
                'Skin',
                kSkinTones,
                _config.skinToneIndex,
                (i) => setState(
                  () => _config = _config.copyWith(skinToneIndex: i),
                ),
              ),
              _colorRow(
                'Hair',
                kHairColors,
                _config.hairColorIndex,
                (i) => setState(
                  () => _config = _config.copyWith(hairColorIndex: i),
                ),
              ),
              _colorRow(
                'Eyes',
                kEyeColors,
                _config.eyeColorIndex,
                (i) => setState(
                  () => _config = _config.copyWith(eyeColorIndex: i),
                ),
              ),
              _colorRow(
                'Top',
                kTopColors,
                _config.topColorIndex,
                (i) => setState(
                  () => _config = _config.copyWith(topColorIndex: i),
                ),
              ),
              _colorRow(
                'Pants',
                kBottomColors,
                _config.bottomColorIndex,
                (i) => setState(
                  () => _config = _config.copyWith(bottomColorIndex: i),
                ),
              ),
              const SizedBox(height: 28),

              FilledButton(
                onPressed: nameOk && !_saving ? _create : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: theme.textTheme.titleLarge,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create!'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _colorRow(
  String label,
  List<Color> colors,
  int selectedIndex,
  ValueChanged<int> onSelect,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 46,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        ...List.generate(colors.length, (i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.black12,
                  width: selected ? 3 : 1,
                ),
                boxShadow: selected
                    ? [
                        const BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ],
    ),
  );
}
