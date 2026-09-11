/// The single-currency coin economy (prd.md *Cosmetics System*, revised
/// 2026-09-08). One coin ≈ one expected second of study, so every price in
/// the city reads as minutes of math.
///
/// Every tunable lives here as a named constant, nowhere else. Pure Dart.
library;

import 'dart:math' as math;

/// Streak multiplier step: pay is `kStreakStep × min(streak, kStreakCap)` of
/// full credit, so the first correct after a miss pays 20%, the next 40%,
/// and so on (chess-puzzle style).
const double kStreakStep = 0.2;

/// Where the pay ramp tops out: at [kStreakCap] in a row the multiplier is
/// `kStreakStep × kStreakCap` = 1.0, i.e. full credit. The streak itself
/// keeps counting past this — it's shown to the player as "N in a row!" —
/// only the pay stops climbing.
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

/// Consecutive-correct count after an answer: +1 on a correct answer
/// (uncapped — the player sees how far they've gone), 0 on a wrong one.
/// Fresh players start at 0, so the opening pay ramp doubles as a tutorial.
int nextStreakCount(int current, {required bool correct}) =>
    correct ? current + 1 : 0;

/// Multiplier applied to full credit at [streakCount] (0 → 0.0, anything
/// at or past [kStreakCap] → 1.0).
double streakMultiplier(int streakCount) =>
    kStreakStep * streakCount.clamp(0, kStreakCap);

/// Coins paid for a correct answer.
///
/// [streakCount] is the player's streak *after* counting this answer (see
/// [nextStreakCount]) — so the first correct after a miss is paid at 20%.
/// `round(expectedSeconds × formatMult × kStreakStep × min(streak, cap))`,
/// floored at [kMinCoinsPerCorrect]. Wrong answers pay nothing (callers
/// don't call this for them).
int coinsForCorrectAnswer({
  required int expectedSeconds,
  required bool usesKeypad,
  required int streakCount,
}) {
  final formatMult = usesKeypad ? kKeypadMultiplier : kMultipleChoiceMultiplier;
  final raw = expectedSeconds * formatMult * streakMultiplier(streakCount);
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
