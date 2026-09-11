import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/economy/band_crossings.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';

void main() {
  group('bandCrossingThresholds', () {
    test('v1 ships exactly 2 bands', () {
      // Sanity-check the v1 contract — if this changes, update curriculum
      // budget math in plan.md / prd.md.
      expect(bandCrossingThresholds, [0.5, 0.85]);
    });

    test('thresholds are sorted ascending', () {
      for (var i = 1; i < bandCrossingThresholds.length; i++) {
        expect(
          bandCrossingThresholds[i] > bandCrossingThresholds[i - 1],
          isTrue,
        );
      }
    });
  });

  group('bandReachedAt', () {
    test('index 0 enters comfortable, index 1 enters mastered', () {
      expect(bandReachedAt(0), ProficiencyBand.comfortable);
      expect(bandReachedAt(1), ProficiencyBand.mastered);
    });
  });

  group('newlyCrossedBands', () {
    test('no-op update returns empty', () {
      expect(
        newlyCrossedBands(
          oldP: 0.4,
          newP: 0.4,
          alreadyAwardedBandIndices: <int>{},
        ),
        isEmpty,
      );
    });

    test('downward move returns empty', () {
      expect(
        newlyCrossedBands(
          oldP: 0.6,
          newP: 0.55,
          alreadyAwardedBandIndices: <int>{},
        ),
        isEmpty,
      );
    });

    test('upward move that does not cross any threshold returns empty', () {
      expect(
        newlyCrossedBands(
          oldP: 0.6,
          newP: 0.7,
          alreadyAwardedBandIndices: <int>{},
        ),
        isEmpty,
      );
    });

    test('crossing the lower threshold returns [0]', () {
      expect(
        newlyCrossedBands(
          oldP: 0.4,
          newP: 0.55,
          alreadyAwardedBandIndices: <int>{},
        ),
        [0],
      );
    });

    test('crossing the upper threshold returns [1]', () {
      expect(
        newlyCrossedBands(
          oldP: 0.8,
          newP: 0.9,
          alreadyAwardedBandIndices: <int>{},
        ),
        [1],
      );
    });

    test('crossing both thresholds in one big jump returns [0, 1]', () {
      expect(
        newlyCrossedBands(
          oldP: 0.4,
          newP: 0.9,
          alreadyAwardedBandIndices: <int>{},
        ),
        [0, 1],
      );
    });

    test('re-crossing an already-awarded band returns empty', () {
      // Player crossed 0.5 before, then dipped below 0.5, now climbs above
      // 0.5 again. Should NOT pay again.
      expect(
        newlyCrossedBands(
          oldP: 0.4,
          newP: 0.6,
          alreadyAwardedBandIndices: <int>{0},
        ),
        isEmpty,
      );
    });

    test('partially-awarded set returns only the un-awarded crossings', () {
      // Already got band 0; big jump from 0.4 to 0.9 should award only
      // band 1.
      expect(
        newlyCrossedBands(
          oldP: 0.4,
          newP: 0.9,
          alreadyAwardedBandIndices: <int>{0},
        ),
        [1],
      );
    });

    test('threshold-exact value counts as crossed', () {
      // 0.5 is the threshold. oldP=0.4, newP=0.5 should cross (per the
      // `newP >= threshold` inequality).
      expect(
        newlyCrossedBands(
          oldP: 0.4,
          newP: 0.5,
          alreadyAwardedBandIndices: <int>{},
        ),
        [0],
      );
    });
  });
}
