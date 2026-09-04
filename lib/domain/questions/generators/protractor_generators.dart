import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// G4 protractor generators using the new Protractor widget:
/// measure_angle_protractor, draw_angle_protractor.

// ─────────────────────────────────────────────────────────────────────────
// measure_angle_protractor (G4)
// ─────────────────────────────────────────────────────────────────────────

/// Show an angle drawn over a protractor (with tick labels); kid reads
/// the measure. CCSS 4.MD.C.6.
///
/// Angle drawn to the nearest 5°, in [15, 165] so the kid can't guess
/// "90 or 180" trivially. Misconception distractor: read the wrong scale
/// (180 − a, since protractors carry both directions of tick labels).
GeneratedQuestion measureAngleProtractor(Random rand) {
  int a;
  do {
    a = (rand.nextInt(31) + 3) * 5; // 15..165, step 5
  } while (a == 90); // skip trivial right angle
  return GeneratedQuestion(
    conceptId: 'measure_angle_protractor',
    prompt: 'What is the measure of this angle, in degrees?',
    diagram: ProtractorSpec(angleDeg: a),
    correctAnswer: '$a',
    distractors: integerDistractorsWith(
      a,
      rand,
      // Misconception: read the outer scale (which protractors print
      // for the other direction). 180 − a is the most common kid error.
      misconception: 180 - a,
    ),
    explanation: ['The second ray crosses the $a° tick.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// draw_angle_protractor (G4)
// ─────────────────────────────────────────────────────────────────────────

/// "An angle measures $a°. Which protractor figure shows it drawn
/// correctly?" — we don't have a 4-choice picture-MC infrastructure yet,
/// so this is shaped instead as the inverse of the measure task: the
/// diagram is labelled inside the wedge with the target angle, and the
/// kid types the measure value back. This drills the same "match angle
/// measure to figure" skill while staying inside the text-answer UI.
///
/// CCSS 4.MD.C.6.
GeneratedQuestion drawAngleProtractor(Random rand) {
  int a;
  do {
    a = (rand.nextInt(31) + 3) * 5; // 15..165, step 5
  } while (a == 90);
  final scaleWarning =
      'Use the scale whose 0 is on the first ray — the other scale '
      'wrongly gives ${180 - a}°.';
  return GeneratedQuestion(
    conceptId: 'draw_angle_protractor',
    // No label inside the wedge — printing the answer there reduced the
    // task to reading it back. The kid reads the scale where the second
    // ray crosses instead, so the 180−a wrong-scale trap is real.
    prompt:
        'A student drew this angle with a protractor. Read the scale: '
        'what angle did they draw, in degrees?',
    diagram: ProtractorSpec(angleDeg: a),
    correctAnswer: '$a',
    distractors: integerDistractorsWith(
      a,
      rand,
      misconception: 180 - a,
    ),
    explanation: [
      'One ray points at 0°; the other crosses the scale at $a°.',
      scaleWarning,
    ],
  );
}
