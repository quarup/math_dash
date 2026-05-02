import 'package:flutter_test/flutter_test.dart';
import 'package:math_dash/domain/concepts/concept_registry.dart';

void main() {
  group('ConceptRegistry', () {
    test('allConcepts contains all Phase 1 and Phase 2 concepts', () {
      final ids = allConcepts.map((c) => c.id).toSet();
      expect(
        ids,
        containsAll([
          'add_1digit',
          'sub_1digit',
          'add_2digit',
          'sub_2digit',
          'mul_1digit',
          'div_1digit',
        ]),
      );
      expect(allConcepts, hasLength(6));
    });

    test('findConceptById returns the correct concept', () {
      expect(findConceptById('add_1digit'), same(add1Digit));
      expect(findConceptById('sub_1digit'), same(sub1Digit));
      expect(findConceptById('add_2digit'), same(add2Digit));
      expect(findConceptById('sub_2digit'), same(sub2Digit));
      expect(findConceptById('mul_1digit'), same(mul1Digit));
      expect(findConceptById('div_1digit'), same(div1Digit));
    });

    test('findConceptById returns null for unknown id', () {
      expect(findConceptById('unknown'), isNull);
      expect(findConceptById(''), isNull);
    });

    test('all concepts have unique ids', () {
      final ids = allConcepts.map((c) => c.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('all concepts have a positive gradeLevel', () {
      for (final c in allConcepts) {
        expect(c.gradeLevel, greaterThan(0));
      }
    });
  });
}
