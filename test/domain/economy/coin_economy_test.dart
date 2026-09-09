import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/economy/coin_economy.dart';

void main() {
  group('tunable constants (documented defaults)', () {
    test('match the agreed spec', () {
      expect(kStreakStep, 0.2);
      expect(kStreakCap, 5);
      expect(kKeypadMultiplier, 1.5);
      expect(kMultipleChoiceMultiplier, 1.0);
      expect(kBlockTargetSeconds, 25);
      expect(kMinBlockQuestions, 1);
      expect(kMaxBlockQuestions, 6);
      expect(kBandBonusMultiplier, 2);
      expect(kMinCoinsPerCorrect, 1);
    });

    test('the cap reaches exactly full credit', () {
      expect(streakMultiplier(kStreakCap), closeTo(1.0, 1e-9));
    });
  });

  group('nextStreakLevel', () {
    test('a fresh player climbs 0 → 1 → 2 … on correct answers', () {
      var level = 0;
      for (final expected in [1, 2, 3, 4, 5]) {
        level = nextStreakLevel(level, correct: true);
        expect(level, expected);
      }
    });

    test('caps at kStreakCap', () {
      expect(nextStreakLevel(kStreakCap, correct: true), kStreakCap);
      expect(nextStreakLevel(kStreakCap + 3, correct: true), kStreakCap);
    });

    test('any wrong answer resets to 0', () {
      expect(nextStreakLevel(0, correct: false), 0);
      expect(nextStreakLevel(3, correct: false), 0);
      expect(nextStreakLevel(kStreakCap, correct: false), 0);
    });
  });

  group('streakMultiplier', () {
    test('ramps 0.2 per level', () {
      expect(streakMultiplier(0), 0.0);
      expect(streakMultiplier(1), closeTo(0.2, 1e-9));
      expect(streakMultiplier(3), closeTo(0.6, 1e-9));
      expect(streakMultiplier(5), closeTo(1.0, 1e-9));
    });

    test('clamps out-of-range levels', () {
      expect(streakMultiplier(-1), 0.0);
      expect(streakMultiplier(99), closeTo(1.0, 1e-9));
    });
  });

  group('coinsForCorrectAnswer', () {
    test('full streak, multiple choice pays expectedSeconds exactly', () {
      expect(
        coinsForCorrectAnswer(
          expectedSeconds: 40,
          usesKeypad: false,
          streakLevel: 5,
        ),
        40,
      );
    });

    test('keypad pays 1.5×', () {
      expect(
        coinsForCorrectAnswer(
          expectedSeconds: 40,
          usesKeypad: true,
          streakLevel: 5,
        ),
        60,
      );
    });

    test('ramps with the streak: 20% at level 1, 40% at level 2 …', () {
      for (final (level, coins) in [
        (1, 8),
        (2, 16),
        (3, 24),
        (4, 32),
        (5, 40),
      ]) {
        expect(
          coinsForCorrectAnswer(
            expectedSeconds: 40,
            usesKeypad: false,
            streakLevel: level,
          ),
          coins,
          reason: 'level $level',
        );
      }
    });

    test('rounds to the nearest coin', () {
      // 7 × 1.0 × 0.2 = 1.4 → 1; 7 × 1.5 × 0.2 = 2.1 → 2; 7 × 0.6 = 4.2 → 4.
      expect(
        coinsForCorrectAnswer(
          expectedSeconds: 7,
          usesKeypad: false,
          streakLevel: 1,
        ),
        1,
      );
      expect(
        coinsForCorrectAnswer(
          expectedSeconds: 7,
          usesKeypad: true,
          streakLevel: 1,
        ),
        2,
      );
      expect(
        coinsForCorrectAnswer(
          expectedSeconds: 7,
          usesKeypad: false,
          streakLevel: 3,
        ),
        4,
      );
    });

    test('never pays less than kMinCoinsPerCorrect', () {
      // A 4-second K question at level 1 is 0.8 coins → floored to 1.
      expect(
        coinsForCorrectAnswer(
          expectedSeconds: 4,
          usesKeypad: false,
          streakLevel: 1,
        ),
        kMinCoinsPerCorrect,
      );
      // Even a degenerate level-0 call pays the floor.
      expect(
        coinsForCorrectAnswer(
          expectedSeconds: 40,
          usesKeypad: false,
          streakLevel: 0,
        ),
        kMinCoinsPerCorrect,
      );
    });

    test('a K sum at full streak pays ~5, a G8 problem pays 40+', () {
      expect(
        coinsForCorrectAnswer(
          expectedSeconds: 5,
          usesKeypad: false,
          streakLevel: 5,
        ),
        5,
      );
      expect(
        coinsForCorrectAnswer(
          expectedSeconds: 45,
          usesKeypad: false,
          streakLevel: 5,
        ),
        greaterThanOrEqualTo(40),
      );
    });
  });

  group('blockSizeFor', () {
    test('quick K questions fill a block up to the cap', () {
      expect(blockSizeFor(5), 5); // 25 / 5
      expect(blockSizeFor(4), 6); // 25 / 4 = 6.25 → 7, clamped to 6
      expect(blockSizeFor(1), kMaxBlockQuestions);
    });

    test('one long problem is a block on its own', () {
      expect(blockSizeFor(25), 1);
      expect(blockSizeFor(40), 1);
      expect(blockSizeFor(90), 1);
    });

    test('rounds partial blocks up', () {
      expect(blockSizeFor(10), 3); // 2.5 → 3
      expect(blockSizeFor(12), 3); // 2.08 → 3
      expect(blockSizeFor(20), 2); // 1.25 → 2
      expect(blockSizeFor(24), 2);
    });

    test('never below the minimum', () {
      expect(blockSizeFor(1000), kMinBlockQuestions);
    });
  });

  group('bandCrossingBonus', () {
    test('pays 2× the expected seconds, unscaled by streak or format', () {
      expect(bandCrossingBonus(5), 10);
      expect(bandCrossingBonus(40), 80);
    });
  });
}
