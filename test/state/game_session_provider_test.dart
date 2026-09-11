import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/state/game_session_provider.dart';
import 'package:math_city/state/player_provider.dart';

AppDatabase _testDb() {
  // Each test gets an isolated in-memory DB; multiple instances intentional.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  // The coin counter mirrors the persisted balance: every screen that shows
  // coins (spin/question AppBars, city currency bar, home chips) must agree
  // after an earn or a spend, which is what once broke when only one
  // provider was invalidated.
  group('totalCoinsProvider', () {
    late AppDatabase db;
    late ProviderContainer container;
    late int playerId;

    setUp(() async {
      db = _testDb();
      final player = await db.createPlayer(
        name: 'Sam',
        gradeLevel: 2,
        avatarConfigJson: '{}',
      );
      playerId = player.id;
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      container.read(activePlayerIdProvider.notifier).selected = playerId;
      await container.read(activePlayerProvider.future);
    });
    tearDown(() => container.dispose());

    Future<void> refresh() async {
      container.invalidate(activePlayerProvider);
      await container.read(activePlayerProvider.future);
    }

    test('starts at zero for a new player', () {
      expect(container.read(totalCoinsProvider), 0);
    });

    test('reflects an earn once the player row is refetched', () async {
      await db.incrementPlayerCoins(playerId, 7);
      await refresh();
      expect(container.read(totalCoinsProvider), 7);
      expect(container.read(activePlayerProvider).value!.coinBalance, 7);
    });

    test('a spend after an earn nets out; lifetime stays monotone', () async {
      await db.incrementPlayerCoins(playerId, 10);
      await db.incrementPlayerCoins(playerId, -6);
      await refresh();

      expect(container.read(totalCoinsProvider), 4);
      final player = await db.getPlayerById(playerId);
      expect(player.coinBalance, 4);
      expect(player.lifetimeCoinsEarned, 10);
    });

    test('resets when a different player is selected', () async {
      await db.incrementPlayerCoins(playerId, 50);
      await refresh();
      expect(container.read(totalCoinsProvider), 50);

      final other = await db.createPlayer(
        name: 'Kim',
        gradeLevel: 1,
        avatarConfigJson: '{}',
      );
      container.read(activePlayerIdProvider.notifier).selected = other.id;
      await container.read(activePlayerProvider.future);
      expect(container.read(totalCoinsProvider), 0);
    });
  });
}
