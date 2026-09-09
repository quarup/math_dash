import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/category.dart';
import 'package:math_city/domain/city/unlock_rule.dart';

void main() {
  group('buildingRegistry', () {
    test('all IDs are unique', () {
      final ids = buildingRegistry.map((b) => b.id).toSet();
      expect(ids.length, buildingRegistry.length);
    });

    test('covers all 4 categories', () {
      final categories = buildingRegistry.map((b) => b.category).toSet();
      expect(categories, BuildingCategory.values.toSet());
    });

    test("mayor's office is free + ungated", () {
      final mayors = findBuildingTypeById('mayors_office');
      expect(mayors, isNotNull);
      expect(mayors!.coinCost, 0);
      expect(
        mayors.unlockRule.evaluate(
          const UnlockContext(
            lifetimeCoinsEarned: 0,
            population: 0,
            placedBuildingTypeIds: <String>{},
            readBeatIds: <String>{},
          ),
        ),
        isTrue,
      );
    });

    test('single home costs one minute of study (60 coins)', () {
      final home = findBuildingTypeById('single_home');
      expect(home, isNotNull);
      expect(home!.coinCost, 60);
    });

    test('prices read as whole half-minutes of study, none below a minute', () {
      for (final b in buildingRegistry) {
        if (b.id == 'mayors_office') continue;
        expect(b.coinCost % 30, 0, reason: '${b.id} cost ${b.coinCost}');
        expect(b.coinCost, greaterThanOrEqualTo(60), reason: b.id);
      }
    });

    test('the dearest building is a couple of hours of study', () {
      final dearest = buildingRegistry
          .map((b) => b.coinCost)
          .reduce((a, b) => a > b ? a : b);
      expect(dearest, 7200);
    });

    test('lifetime gates are hour-scale milestones', () {
      for (final b in buildingRegistry) {
        final gate = b.unlockRule.minLifetimeCoins;
        if (gate == null) continue;
        expect(gate, greaterThanOrEqualTo(3600), reason: b.id);
        expect(gate % 1800, 0, reason: b.id);
      }
    });

    test('every prereq building referenced by an unlock rule exists', () {
      final ids = buildingRegistry.map((b) => b.id).toSet();
      for (final b in buildingRegistry) {
        for (final prereq in b.unlockRule.requiredBuildingsPlaced) {
          expect(
            ids,
            contains(prereq),
            reason: '${b.id} requires unknown building $prereq',
          );
        }
      }
    });

    test(
      "every non-mayor building chains back to the mayor's office (no "
      'orphans, no cycles)',
      () {
        final byId = {for (final b in buildingRegistry) b.id: b};
        for (final b in buildingRegistry) {
          if (b.id == 'mayors_office') continue;
          // Walk prereq edges; we must reach mayors_office within the
          // registry size (a cycle or orphan would exhaust the budget).
          var frontier = b.unlockRule.requiredBuildingsPlaced;
          var found = false;
          for (
            var hops = 0;
            hops < buildingRegistry.length && frontier.isNotEmpty;
            hops++
          ) {
            if (frontier.contains('mayors_office')) {
              found = true;
              break;
            }
            frontier = frontier
                .expand((id) => byId[id]!.unlockRule.requiredBuildingsPlaced)
                .toSet();
          }
          expect(
            found,
            isTrue,
            reason: '${b.id} does not chain back to mayors_office',
          );
        }
      },
    );

    test('every non-mayor building is gated on reading a demand beat', () {
      for (final b in buildingRegistry) {
        if (b.id == 'mayors_office') continue;
        expect(
          b.unlockRule.requiredBeatsRead,
          isNotEmpty,
          reason: '${b.id} should be discovery-gated via requiredBeatsRead',
        );
      }
    });

    test('buildings with sprite art have positive variant counts', () {
      // Spot-check the Phase-9 wiring: numVariants matches the processed
      // assets/buildings/<id>_v<n>.png files for a sample of buildings.
      expect(findBuildingTypeById('single_home')!.numVariants, 6);
      expect(findBuildingTypeById('duplex')!.numVariants, 4);
      expect(findBuildingTypeById('high_rise')!.numVariants, 3);
      expect(findBuildingTypeById('water_tower')!.numVariants, 2);
      expect(findBuildingTypeById('amusement_park')!.numVariants, 2);
      expect(findBuildingTypeById('mid_rise_apartment')!.numVariants, 2);
      expect(findBuildingTypeById('stadium')!.numVariants, 1);
    });

    test('the full §3 catalog is now sprite-backed', () {
      // Phase 9 finished the art pass: every wired building has ≥1 variant
      // (the box+emoji placeholder is no longer used by any registered type).
      for (final b in buildingRegistry) {
        expect(
          b.numVariants,
          greaterThan(0),
          reason: '${b.id} should have processed sprite art',
        );
      }
    });
  });
}
