import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/state/player_provider.dart';

// ---------------------------------------------------------------------------
// Coin balance of the active player, as shown in every AppBar counter.
//
// A plain mirror of the persisted balance: the proficiency notifier writes
// coins to Drift inside `recordAnswer` (so a payout can never be lost to a
// mid-animation exit) and invalidates `activePlayerProvider`, which refreshes
// this. `.value` (not `asData`) so a refetch in flight keeps showing the last
// known balance — AsyncLoading carries it over — instead of blinking to 0.
// Screens that animate a payout hold their displayed number back themselves
// until the coin lands (see `QuestionScreen`).
// ---------------------------------------------------------------------------

final totalCoinsProvider = Provider<int>(
  (ref) => ref.watch(activePlayerProvider).value?.coinBalance ?? 0,
);
