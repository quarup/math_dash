import 'package:math_dash/domain/concepts/concept.dart';

const add1Digit = Concept(
  id: 'add_1digit',
  name: 'Single-digit addition',
  shortLabel: 'Addition',
  gradeLevel: 1,
  description: 'Adding two single-digit numbers (0–9)',
);

const sub1Digit = Concept(
  id: 'sub_1digit',
  name: 'Single-digit subtraction',
  shortLabel: 'Subtraction',
  gradeLevel: 1,
  description: 'Subtracting a single-digit number, no negatives',
);

const add2Digit = Concept(
  id: 'add_2digit',
  name: '2-digit addition',
  shortLabel: 'Add 2d',
  gradeLevel: 2,
  description: 'Adding two 2-digit numbers',
);

const sub2Digit = Concept(
  id: 'sub_2digit',
  name: '2-digit subtraction',
  shortLabel: 'Sub 2d',
  gradeLevel: 2,
  description: 'Subtracting a 2-digit number from another, no negatives',
);

const mul1Digit = Concept(
  id: 'mul_1digit',
  name: 'Single-digit multiplication',
  shortLabel: 'Multiply',
  gradeLevel: 3,
  description:
      'Multiplying two single-digit numbers (1–9), excluding ×0 and ×1',
);

const div1Digit = Concept(
  id: 'div_1digit',
  name: 'Single-digit division',
  shortLabel: 'Divide',
  gradeLevel: 3,
  description:
      'Exact division: divisor ∈ [2,9], quotient ∈ [1,9], no remainders',
);

const List<Concept> allConcepts = [
  add1Digit,
  sub1Digit,
  add2Digit,
  sub2Digit,
  mul1Digit,
  div1Digit,
];

Concept? findConceptById(String id) =>
    allConcepts.where((c) => c.id == id).firstOrNull;
