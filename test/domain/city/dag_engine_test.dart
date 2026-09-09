import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/dag_engine.dart';
import 'package:math_city/domain/city/unlock_rule.dart';

void main() {
  const engine = BuildingDagEngine();

  // Every demand beat that gates a building's catalog card. Reading all of
  // them (with the mayor's office placed) unlocks the whole Phase-7 set.
  const allDemandBeats = <String>{
    'demand_first_home',
    'demand_school',
    'demand_apartment',
    'demand_clinic',
    'demand_power',
    'demand_waste',
    'demand_grocery',
    'demand_coffee_shop',
    'demand_more_parks',
  };

  group('availableToBuy', () {
    test("a fresh player can only buy the mayor's office", () {
      final available = engine.availableToBuy(
        const UnlockContext(
          lifetimeCoinsEarned: 0,
          population: 0,
          placedBuildingTypeIds: <String>{},
          readBeatIds: <String>{},
        ),
      );
      expect(available.map((b) => b.id), ['mayors_office']);
    });

    test(
      "placing the mayor's office alone unlocks nothing new — buildings stay "
      'gated behind their demand beat being read',
      () {
        final available = engine.availableToBuy(
          const UnlockContext(
            lifetimeCoinsEarned: 0,
            population: 0,
            placedBuildingTypeIds: <String>{'mayors_office'},
            readBeatIds: <String>{},
          ),
        );
        expect(available.map((b) => b.id), ['mayors_office']);
      },
    );

    test('reading a demand beat unlocks just that building', () {
      final available = engine.availableToBuy(
        const UnlockContext(
          lifetimeCoinsEarned: 0,
          population: 0,
          placedBuildingTypeIds: <String>{'mayors_office'},
          readBeatIds: <String>{'demand_first_home'},
        ),
      );
      expect(available.map((b) => b.id), ['mayors_office', 'single_home']);
    });

    test('mayor placed + every demand read makes all 10 available', () {
      final available = engine.availableToBuy(
        const UnlockContext(
          lifetimeCoinsEarned: 0,
          population: 0,
          placedBuildingTypeIds: <String>{'mayors_office'},
          readBeatIds: allDemandBeats,
        ),
      );
      expect(available, hasLength(10));
    });
  });
}
