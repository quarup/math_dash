import 'package:flutter/material.dart';
import 'package:math_dash/presentation/player/player_launcher_screen.dart';

class MathDashApp extends StatelessWidget {
  const MathDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Dash',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const PlayerLauncherScreen(),
    );
  }
}
