import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/economy/expected_seconds.dart';

void main() {
  group('expectedSecondsByConcept coverage', () {
    test('every registered concept has an entry', () {
      final missing = [
        for (final c in allConcepts)
          if (!expectedSecondsByConcept.containsKey(c.id)) c.id,
      ];
      expect(missing, isEmpty, reason: 'add these to expected_seconds.dart');
    });

    test('no entry points at a concept that does not exist', () {
      final known = allConcepts.map((c) => c.id).toSet();
      final stale = [
        for (final id in expectedSecondsByConcept.keys)
          if (!known.contains(id)) id,
      ];
      expect(stale, isEmpty, reason: 'remove these from expected_seconds.dart');
    });

    test('every estimate is a positive number of seconds', () {
      for (final entry in expectedSecondsByConcept.entries) {
        expect(entry.value, greaterThan(0), reason: entry.key);
      }
    });

    test('expectedSecondsFor throws on an unknown id', () {
      expect(() => expectedSecondsFor('no_such_concept'), throwsArgumentError);
    });

    test('grade bands trend the way the draft formula says', () {
      // The table was hand-adjusted from a K–1 ≈ 5 s / G2–3 ≈ 10 s /
      // G4–5 ≈ 20 s / G6–8 ≈ 35 s draft; the per-grade means must still
      // climb monotonically or an edit has gone badly wrong somewhere.
      final sums = <int, int>{};
      final counts = <int, int>{};
      for (final c in allConcepts) {
        sums[c.primaryGrade] =
            (sums[c.primaryGrade] ?? 0) + expectedSecondsFor(c.id);
        counts[c.primaryGrade] = (counts[c.primaryGrade] ?? 0) + 1;
      }
      double mean(int g) => sums[g]! / counts[g]!;
      expect(mean(0), lessThan(mean(2)));
      expect(mean(2), lessThan(mean(4)));
      expect(mean(4), lessThan(mean(6)));
      expect(mean(6), lessThan(mean(8)));
      expect(mean(0), lessThan(10));
      expect(mean(8), greaterThan(30));
    });
  });
}
