import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_dash/domain/concepts/concept_registry.dart';
import 'package:math_dash/domain/questions/arithmetic_generator.dart';
import 'package:math_dash/domain/questions/question.dart';

void main() {
  group('ArithmeticGenerator', () {
    // Fixed seed so failures are reproducible.
    final gen = ArithmeticGenerator(random: Random(42));
    const iterations = 500;

    // Shared distractor validator.
    void expectValidDistractors(Question q) {
      final correct = int.parse(q.correctAnswer);
      expect(q.distractors, hasLength(3));
      expect(
        q.distractors.toSet(),
        hasLength(3),
        reason: 'distractors must be unique',
      );
      for (final d in q.distractors) {
        final v = int.parse(d);
        expect(v, isNot(correct), reason: 'must differ from answer');
        expect(v, greaterThanOrEqualTo(0), reason: 'must be non-negative');
      }
    }

    group('add_1digit', () {
      test('operands and sum are in spec range', () {
        for (var i = 0; i < iterations; i++) {
          final q = gen.generateForConcept(add1Digit.id);

          final parts = q.prompt.replaceAll(' = ?', '').split(' + ');
          final a = int.parse(parts[0]);
          final b = int.parse(parts[1]);
          final correct = int.parse(q.correctAnswer);

          expect(a, inInclusiveRange(0, 9));
          expect(b, inInclusiveRange(0, 9));
          expect(correct, a + b);
          expect(correct, inInclusiveRange(0, 18));
        }
      });

      test('distractors are valid', () {
        for (var i = 0; i < iterations; i++) {
          expectValidDistractors(gen.generateForConcept(add1Digit.id));
        }
      });
    });

    group('sub_1digit', () {
      test('operands and difference are in spec range', () {
        for (var i = 0; i < iterations; i++) {
          final q = gen.generateForConcept(sub1Digit.id);

          // U+2212 minus sign
          final parts = q.prompt.replaceAll(' = ?', '').split(' − ');
          final a = int.parse(parts[0]);
          final b = int.parse(parts[1]);
          final correct = int.parse(q.correctAnswer);

          expect(a, greaterThanOrEqualTo(b), reason: 'no negative results');
          expect(b, inInclusiveRange(0, 9));
          expect(a, inInclusiveRange(0, 18));
          expect(correct, a - b);
          expect(correct, greaterThanOrEqualTo(0));
        }
      });

      test('distractors are valid', () {
        for (var i = 0; i < iterations; i++) {
          expectValidDistractors(gen.generateForConcept(sub1Digit.id));
        }
      });
    });

    group('add_2digit', () {
      test('operands and sum are in spec range', () {
        for (var i = 0; i < iterations; i++) {
          final q = gen.generateForConcept(add2Digit.id);

          final parts = q.prompt.replaceAll(' = ?', '').split(' + ');
          final a = int.parse(parts[0]);
          final b = int.parse(parts[1]);
          final correct = int.parse(q.correctAnswer);

          expect(a, inInclusiveRange(10, 99));
          expect(b, inInclusiveRange(10, 99));
          expect(correct, a + b);
          expect(correct, inInclusiveRange(20, 198));
        }
      });

      test('distractors are valid', () {
        for (var i = 0; i < iterations; i++) {
          expectValidDistractors(gen.generateForConcept(add2Digit.id));
        }
      });
    });

    group('sub_2digit', () {
      test('both operands in [10,99], no negative result', () {
        for (var i = 0; i < iterations; i++) {
          final q = gen.generateForConcept(sub2Digit.id);

          final parts = q.prompt.replaceAll(' = ?', '').split(' − ');
          final a = int.parse(parts[0]);
          final b = int.parse(parts[1]);
          final correct = int.parse(q.correctAnswer);

          expect(a, inInclusiveRange(10, 99));
          expect(b, inInclusiveRange(10, 99));
          expect(a, greaterThanOrEqualTo(b), reason: 'no negative results');
          expect(correct, a - b);
          expect(correct, greaterThanOrEqualTo(0));
        }
      });

      test('distractors are valid', () {
        for (var i = 0; i < iterations; i++) {
          expectValidDistractors(gen.generateForConcept(sub2Digit.id));
        }
      });
    });

    group('mul_1digit', () {
      test('operands in [2,9], product correct', () {
        for (var i = 0; i < iterations; i++) {
          final q = gen.generateForConcept(mul1Digit.id);

          final parts = q.prompt.replaceAll(' = ?', '').split(' × ');
          final a = int.parse(parts[0]);
          final b = int.parse(parts[1]);
          final correct = int.parse(q.correctAnswer);

          // Spec: skip ×0 and ×1 (operands start at 2)
          expect(a, inInclusiveRange(2, 9));
          expect(b, inInclusiveRange(2, 9));
          expect(correct, a * b);
          expect(correct, inInclusiveRange(4, 81));
        }
      });

      test('distractors are valid', () {
        for (var i = 0; i < iterations; i++) {
          expectValidDistractors(gen.generateForConcept(mul1Digit.id));
        }
      });
    });

    group('div_1digit', () {
      test('exact division, no remainders', () {
        for (var i = 0; i < iterations; i++) {
          final q = gen.generateForConcept(div1Digit.id);

          final parts = q.prompt.replaceAll(' = ?', '').split(' ÷ ');
          final dividend = int.parse(parts[0]);
          final divisor = int.parse(parts[1]);
          final quotient = int.parse(q.correctAnswer);

          expect(divisor, inInclusiveRange(2, 9));
          expect(quotient, inInclusiveRange(1, 9));
          expect(dividend, divisor * quotient);
          expect(dividend % divisor, 0, reason: 'no remainder');
        }
      });

      test('distractors are valid', () {
        for (var i = 0; i < iterations; i++) {
          expectValidDistractors(gen.generateForConcept(div1Digit.id));
        }
      });
    });

    test('unknown concept throws ArgumentError', () {
      expect(
        () => gen.generateForConcept('unknown_concept'),
        throwsArgumentError,
      );
    });
  });
}
