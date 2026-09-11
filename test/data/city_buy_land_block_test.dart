import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  Future<(AppDatabase, Player, City)> freshCity() async {
    final db = AppDatabase(NativeDatabase.memory());
    final player = await db.createPlayer(
      name: 'Pat',
      gradeLevel: 3,
      avatarConfigJson: '{}',
    );
    final city = await db.cityForPlayer(player.id);
    return (db, player, city);
  }

  group('buyCityLandBlock', () {
    test('records ownership and spends coins', () async {
      final (db, player, city) = await freshCity();
      await db.incrementPlayerCoins(player.id, 100);

      await db.buyCityLandBlock(
        cityId: city.id,
        playerId: player.id,
        blockX: 2,
        blockY: 0,
        coinCost: 80,
      );

      final owned = await db.ownedBlocksForCity(city.id);
      expect(owned.contains((2, 0)), isTrue);
      expect(owned, hasLength(10)); // 9 starting + 1 bought

      final after = await db.getPlayerById(player.id);
      expect(after.coinBalance, 20); // 100 - 80
      expect(after.lifetimeCoinsEarned, 100); // unchanged by a spend
    });

    test(
      'double-buying the same block is rejected by the primary key',
      () async {
        final (db, player, city) = await freshCity();
        await db.buyCityLandBlock(
          cityId: city.id,
          playerId: player.id,
          blockX: 2,
          blockY: 0,
          coinCost: 0,
        );
        expect(
          () => db.buyCityLandBlock(
            cityId: city.id,
            playerId: player.id,
            blockX: 2,
            blockY: 0,
            coinCost: 0,
          ),
          throwsA(anything),
        );
      },
    );
  });
}
