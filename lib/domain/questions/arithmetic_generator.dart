import 'dart:math';

import 'package:math_dash/domain/concepts/concept_registry.dart';
import 'package:math_dash/domain/questions/question.dart';

/// Generates algorithmic arithmetic questions for all Phase 1 + Phase 2
/// concepts.
///
/// Distractor strategy (per plan.md Domain Specs):
///   - off-by-one (correct ± 1)
///   - random values within ±5 of correct
/// Results are always non-negative.
class ArithmeticGenerator {
  ArithmeticGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  Question generateForConcept(String conceptId) {
    return switch (conceptId) {
      'add_1digit' => _generateAdd1(),
      'sub_1digit' => _generateSub1(),
      'add_2digit' => _generateAdd2(),
      'sub_2digit' => _generateSub2(),
      'mul_1digit' => _generateMul1(),
      'div_1digit' => _generateDiv1(),
      _ => throw ArgumentError('Unknown concept: $conceptId'),
    };
  }

  Question _generateAdd1() {
    final a = _random.nextInt(10); // 0–9
    final b = _random.nextInt(10); // 0–9
    final correct = a + b;
    return Question(
      conceptId: add1Digit.id,
      prompt: '$a + $b = ?',
      correctAnswer: correct.toString(),
      distractors: _buildDistractors(correct),
      explanation: '$a + $b = $correct',
    );
  }

  Question _generateSub1() {
    // Ensure minuend ≥ subtrahend so difference is never negative.
    final b = _random.nextInt(10); // 0–9
    final a = b + _random.nextInt(10); // a ∈ [b, b+9] ⊆ [0, 18]
    final correct = a - b;
    return Question(
      conceptId: sub1Digit.id,
      prompt: '$a − $b = ?', // U+2212 minus sign
      correctAnswer: correct.toString(),
      distractors: _buildDistractors(correct),
      explanation: '$a − $b = $correct',
    );
  }

  Question _generateAdd2() {
    final a = _random.nextInt(90) + 10; // 10–99
    final b = _random.nextInt(90) + 10; // 10–99
    final correct = a + b;
    return Question(
      conceptId: add2Digit.id,
      prompt: '$a + $b = ?',
      correctAnswer: correct.toString(),
      distractors: _buildDistractors(correct),
      explanation: '$a + $b = $correct',
    );
  }

  Question _generateSub2() {
    // Both operands in [10, 99]; minuend ≥ subtrahend so diff ≥ 0.
    final b = _random.nextInt(90) + 10; // 10–99
    final a = b + _random.nextInt(100 - b); // a ∈ [b, 99]
    final correct = a - b;
    return Question(
      conceptId: sub2Digit.id,
      prompt: '$a − $b = ?', // U+2212 minus sign
      correctAnswer: correct.toString(),
      distractors: _buildDistractors(correct),
      explanation: '$a − $b = $correct',
    );
  }

  Question _generateMul1() {
    // Skip trivial ×0 and ×1 per spec.
    final a = _random.nextInt(8) + 2; // 2–9
    final b = _random.nextInt(8) + 2; // 2–9
    final correct = a * b;
    return Question(
      conceptId: mul1Digit.id,
      prompt: '$a × $b = ?',
      correctAnswer: correct.toString(),
      distractors: _buildDistractors(correct),
      explanation: '$a × $b = $correct',
    );
  }

  Question _generateDiv1() {
    // Generate as quotient × divisor = dividend (guarantees no remainder).
    final divisor = _random.nextInt(8) + 2; // 2–9
    final quotient = _random.nextInt(9) + 1; // 1–9
    final dividend = divisor * quotient;
    return Question(
      conceptId: div1Digit.id,
      prompt: '$dividend ÷ $divisor = ?',
      correctAnswer: quotient.toString(),
      distractors: _buildDistractors(quotient),
      explanation: '$dividend ÷ $divisor = $quotient',
    );
  }

  /// Returns exactly three distractors: distinct, non-negative, != [correct].
  List<String> _buildDistractors(int correct) {
    final candidates = <int>{
      correct + 1,
      if (correct - 1 >= 0) correct - 1,
    };

    // Random values within ±5, non-negative.
    for (var attempt = 0; attempt < 40 && candidates.length < 8; attempt++) {
      final offset = _random.nextInt(5) + 1;
      final sign = _random.nextBool() ? 1 : -1;
      final v = correct + sign * offset;
      if (v >= 0) candidates.add(v);
    }

    candidates.remove(correct);

    // Fallback: sequential positives (guarantees we always return 3).
    for (var fallback = 1; candidates.length < 3; fallback++) {
      if (fallback != correct) candidates.add(fallback);
    }

    final list = candidates.toList()..shuffle(_random);
    return list.take(3).map((n) => n.toString()).toList();
  }
}
