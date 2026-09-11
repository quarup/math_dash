import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/concepts/dag_engine.dart';
import 'package:math_city/domain/economy/band_crossings.dart';
import 'package:math_city/domain/economy/coin_economy.dart';
import 'package:math_city/domain/economy/expected_seconds.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/state/city_provider.dart';
import 'package:math_city/state/introduced_concepts_provider.dart';
import 'package:math_city/state/player_provider.dart';

// ---------------------------------------------------------------------------
// Proficiency map — conceptId → p value for the active player.
// Backed by Drift; rebuilt when the active player changes.
// ---------------------------------------------------------------------------

class ProficiencyNotifier extends AsyncNotifier<Map<String, double>> {
  @override
  Future<Map<String, double>> build() async {
    final player = await ref.watch(activePlayerProvider.future);
    final db = ref.watch(appDatabaseProvider);
    return db.proficiencyMapForPlayer(player.id);
  }

  /// Records an answer: updates proficiency, advances the round clock, moves
  /// the answer streak, pays coins (answer + any band-crossing bonus) and
  /// runs the drip-feed. Returns everything the UI needs to animate as one
  /// [AnswerReward]. All persistence happens here, before the caller sees
  /// the reward, so a payout can't be lost to a mid-animation exit.
  ///
  /// Per plan.md Phase 5: unlock events fire only on *correct* answers
  /// (mastery is unreachable from a wrong answer anyway because the EMA
  /// update moves p toward 0). Band-crossing bonuses likewise only fire on
  /// upward moves.
  Future<AnswerReward> recordAnswer(
    String conceptId, {
    required bool correct,
    required bool usesKeypad,
  }) async {
    final player = await ref.read(activePlayerProvider.future);
    final db = ref.read(appDatabaseProvider);

    // One answered question = one round. Advance the clock first so the
    // population tick + beat evaluation below see the new value (building age
    // and bubble rotation both key off it).
    await db.incrementRoundsPlayed(player.id);

    final concept = findConceptById(conceptId)!;
    final engine = ref.read(dagEngineProvider);
    final effectiveGrade = engine.effectiveGradeFor(player.gradeLevel);
    final current =
        state.asData?.value[conceptId] ??
        initialProficiency(concept.primaryGrade, effectiveGrade);
    final updated = updateProficiency(current, correct: correct);

    await db.upsertProficiency(
      player.id,
      conceptId,
      updated,
      correct: correct,
    );

    // Streak: one step up per correct answer (capped), reset on a miss. Pay
    // is computed at the *new* level, so the first correct after a miss
    // earns 20%.
    final streak = nextStreakCount(player.streakCount, correct: correct);
    await db.setPlayerStreakCount(player.id, streak);

    final seconds = expectedSecondsFor(conceptId);
    var coins = 0;
    final bonuses = <BandCrossingBonus>[];
    if (correct) {
      coins = coinsForCorrectAnswer(
        expectedSeconds: seconds,
        usesKeypad: usesKeypad,
        streakCount: streak,
      );
      // Band-crossing bonus: paid once per concept per threshold.
      // `newlyCrossedBands` only returns crossings the player hasn't yet
      // been paid for (per `ConceptBandMilestones`), so re-crossings after
      // a dip don't double-pay.
      final awarded = await db.awardedBandIndicesFor(player.id, conceptId);
      final crossed = newlyCrossedBands(
        oldP: current,
        newP: updated,
        alreadyAwardedBandIndices: awarded,
      );
      for (final bandIndex in crossed) {
        await db.recordBandMilestone(player.id, conceptId, bandIndex);
        bonuses.add(
          BandCrossingBonus(
            conceptId: conceptId,
            band: bandReachedAt(bandIndex),
            coins: bandCrossingBonus(seconds),
          ),
        );
      }
      final total = coins + bonuses.fold<int>(0, (sum, b) => sum + b.coins);
      await db.incrementPlayerCoins(player.id, total);
    }

    UnlockEvent? unlock;
    final crossedMastery = current < 0.85 && updated >= 0.85;
    if (correct && crossedMastery) {
      // Run drip-feed against the *post-update* state.
      final freshProf = await db.proficiencyMapForPlayer(player.id);
      final introduced = await db.introducedConceptIdsForPlayer(player.id);
      final next = engine.pickNext(
        introduced: introduced,
        profMap: freshProf,
        playerGrade: player.gradeLevel,
      );
      if (next != null) {
        await ref.read(introducedConceptsProvider.notifier).introduce(next.id);
        unlock = UnlockEvent(
          newConcept: next,
          masteredConcept: concept,
        );
      }
    }

    // Playing math grows your city: nudge the population one tick toward the
    // capacity its buildings support, then re-evaluate story beats (population
    // and coin-spacing gates can newly pass). No-op until the player has
    // placed something.
    final cityActions = ref.read(cityActionsProvider);
    await cityActions.tickPopulation();
    await cityActions.fireBeats();

    // The round clock, streak and coin balance all moved. Refetch the active
    // player so every counter (AppBar coins, city currency bar, unlock
    // catalog, home-screen chips) reads the balance this answer produced.
    ref
      ..invalidate(activePlayerProvider)
      ..invalidate(allPlayersProvider)
      ..invalidateSelf();
    return AnswerReward(
      correct: correct,
      coins: coins,
      streakCount: streak,
      bandBonuses: bonuses,
      unlock: unlock,
    );
  }
}

final proficiencyProvider =
    AsyncNotifierProvider<ProficiencyNotifier, Map<String, double>>(
      ProficiencyNotifier.new,
    );

// ---------------------------------------------------------------------------
// Wheel concepts — introduced ∩ generator-registered, in challenging or
// comfortable band, minus concepts the player has outgrown (≥2 grades below
// and already comfortable — see `isRetiredFromWheel`), sized between
// [kMinWheelSegments] and [kMaxWheelSegments].
//
// Below the max, every eligible concept is on the wheel (sorted ascending
// by difficulty for a stable layout). At or above the max, we randomly
// sample [kMaxWheelSegments] each round so the player gets variety
// without a 12-segment wheel becoming unreadable on a phone.
// ---------------------------------------------------------------------------

const int kMaxWheelSegments = 8;
const int kMinWheelSegments = 4;

final wheelConceptsProvider = FutureProvider<List<Concept>>((ref) async {
  final profMap = await ref.watch(proficiencyProvider.future);
  final introduced = await ref.watch(introducedConceptsProvider.future);
  final registry = ref.watch(generatorRegistryProvider);
  final player = await ref.watch(activePlayerProvider.future);
  final engine = ref.watch(dagEngineProvider);
  final effectiveGrade = engine.effectiveGradeFor(player.gradeLevel);

  bool playable(Concept c) =>
      introduced.contains(c.id) && registry.isImplemented(c.id);

  ProficiencyBand bandOf(Concept c) => bandForProficiency(
    profMap[c.id] ?? initialProficiency(c.primaryGrade, effectiveGrade),
  );

  bool retired(Concept c) => isRetiredFromWheel(
    conceptGrade: c.primaryGrade,
    playerGrade: effectiveGrade,
    band: bandOf(c),
  );

  bool eligible(Concept c) {
    if (!playable(c) || retired(c)) return false;
    final band = bandOf(c);
    return band == ProficiencyBand.challenging ||
        band == ProficiencyBand.comfortable;
  }

  final concepts = allConcepts.where(eligible).toList()
    ..sort(compareConceptDifficulty);

  // Fallback: if no concepts qualify (e.g. all introduced are mastered),
  // surface the introduced+implemented set so the wheel still spins —
  // still skipping outgrown concepts unless they're literally all there is.
  if (concepts.isEmpty) {
    final all = allConcepts.where(playable).toList();
    final unretired = all.where((c) => !retired(c)).toList();
    return (unretired.isEmpty ? all : unretired)
      ..sort(compareConceptDifficulty);
  }

  // ≤ kMaxWheelSegments: surface them all in difficulty order.
  if (concepts.length <= kMaxWheelSegments) return concepts;

  // > kMaxWheelSegments: random-sample kMaxWheelSegments each round so the
  // player sees variety. The provider rebuilds whenever proficiency or the
  // introduced set changes — i.e., once per answered question — which is
  // also when we want a fresh sample.
  final shuffled = List<Concept>.of(concepts)..shuffle(Random());
  return shuffled.take(kMaxWheelSegments).toList()
    ..sort(compareConceptDifficulty);
});

// ---------------------------------------------------------------------------
// Helper — resolves the band for a concept given the current proficiency map
// and the player's grade level.  Used by SpinScreen when navigating to the
// question screen.
// ---------------------------------------------------------------------------

ProficiencyBand bandForConcept(
  String conceptId,
  Map<String, double> profMap,
  int playerGrade,
) {
  final concept = findConceptById(conceptId)!;
  final p =
      profMap[conceptId] ??
      initialProficiency(concept.primaryGrade, playerGrade);
  return bandForProficiency(p);
}
