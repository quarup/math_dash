/// The single-currency coin economy (prd.md *Cosmetics System*, revised
/// 2026-09-08). One coin ≈ one expected second of study, so every price in
/// the city reads as minutes of math.
///
/// Every tunable lives here as a named constant, nowhere else. Pure Dart.
library;

import 'dart:math' as math;

/// Streak multiplier step: pay is `kStreakStep × streakLevel` of full
/// credit, so the first correct after a miss pays 20%, the next 40%, and so
/// on (chess-puzzle style).
const double kStreakStep = 0.2;

/// Streak level cap. At the cap the multiplier is `kStreakStep × kStreakCap`
/// = 1.0, i.e. full credit.
const int kStreakCap = 5;

/// Free-form (keypad) answers pay this much more than multiple choice for the
/// same concept — typing the answer genuinely takes longer than recognising
/// it among four options.
const double kKeypadMultiplier = 1.5;

/// Multiple-choice format multiplier (the baseline).
const double kMultipleChoiceMultiplier = 1;

/// A correct answer never pays less than this, whatever the streak.
const int kMinCoinsPerCorrect = 1;

/// Expected seconds of work a wheel spin should hand out as one block of
/// questions.
const int kBlockTargetSeconds = 25;

/// Block size clamp: never fewer than one question per spin, never more than
/// six (a K counting block would otherwise be a dozen taps long).
const int kMinBlockQuestions = 1;
const int kMaxBlockQuestions = 6;

/// One-time bonus when a concept's proficiency first crosses a band
/// boundary, as a multiple of the concept's expected seconds. Paid in full —
/// no streak or format scaling — because it celebrates learning, not speed.
const int kBandBonusMultiplier = 2;

/// Streak level after an answer. Correct answers climb one step up to
/// [kStreakCap]; a wrong answer resets to 0. Fresh players start at 0, so the
/// opening ramp doubles as a tutorial.
int nextStreakLevel(int current, {required bool correct}) =>
    correct ? math.min(current + 1, kStreakCap) : 0;

/// Multiplier applied to full credit at [streakLevel] (0 → 0.0, cap → 1.0).
double streakMultiplier(int streakLevel) =>
    kStreakStep * streakLevel.clamp(0, kStreakCap);

/// Coins paid for a correct answer.
///
/// [streakLevel] is the player's streak *after* counting this answer (see
/// [nextStreakLevel]) — so the first correct after a miss is paid at level 1.
/// `round(expectedSeconds × formatMult × kStreakStep × streakLevel)`, floored
/// at [kMinCoinsPerCorrect]. Wrong answers pay nothing (callers don't call
/// this for them).
int coinsForCorrectAnswer({
  required int expectedSeconds,
  required bool usesKeypad,
  required int streakLevel,
}) {
  final formatMult = usesKeypad ? kKeypadMultiplier : kMultipleChoiceMultiplier;
  final raw = expectedSeconds * formatMult * streakMultiplier(streakLevel);
  return math.max(kMinCoinsPerCorrect, raw.round());
}

/// How many questions one wheel spin of a concept yields: enough to add up
/// to [kBlockTargetSeconds] of expected work, clamped to
/// [[kMinBlockQuestions], [kMaxBlockQuestions]] — five quick K sums, or a
/// single long-division problem.
int blockSizeFor(int expectedSeconds) {
  final n = (kBlockTargetSeconds / expectedSeconds).ceil();
  return n.clamp(kMinBlockQuestions, kMaxBlockQuestions);
}

/// One-time coins for a concept's proficiency first crossing a band boundary.
int bandCrossingBonus(int expectedSeconds) =>
    kBandBonusMultiplier * expectedSeconds;
