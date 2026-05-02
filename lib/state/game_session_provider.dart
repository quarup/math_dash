import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_dash/state/proficiency_provider.dart';

class TotalStarsNotifier extends Notifier<int> {
  TotalStarsNotifier([this._initial = 0]);

  final int _initial;

  @override
  int build() => _initial;

  void add(int stars) {
    state += stars;
    // Persist asynchronously; player ID 1 is the default player (Phase 2).
    // Phase 3 will make this dynamic when multi-player is added.
    unawaited(
      ref.read(appDatabaseProvider).updatePlayerStars(1, state),
    );
  }
}

final NotifierProvider<TotalStarsNotifier, int> totalStarsProvider =
    NotifierProvider<TotalStarsNotifier, int>(TotalStarsNotifier.new);
