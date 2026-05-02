import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_dash/app.dart';
import 'package:math_dash/data/database.dart';
import 'package:math_dash/state/game_session_provider.dart';
import 'package:math_dash/state/proficiency_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = openAppDatabase();
  final player = await db.ensureDefaultPlayer();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        totalStarsProvider.overrideWith(
          () => TotalStarsNotifier(player.totalStars),
        ),
      ],
      child: const MathDashApp(),
    ),
  );
}
