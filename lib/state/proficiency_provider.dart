import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_dash/data/database.dart';
import 'package:math_dash/domain/concepts/concept.dart';
import 'package:math_dash/domain/concepts/concept_registry.dart';
import 'package:math_dash/domain/proficiency/proficiency_band.dart';

// ---------------------------------------------------------------------------
// Database provider — overridden in main() with the real AppDatabase instance.
// ---------------------------------------------------------------------------

final appDatabaseProvider = Provider<AppDatabase>(
  (_) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);

// ---------------------------------------------------------------------------
// Default player — loaded once on startup; seeded if the table is empty.
// ---------------------------------------------------------------------------

final defaultPlayerProvider = FutureProvider<Player>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.ensureDefaultPlayer();
});

// ---------------------------------------------------------------------------
// Proficiency map — conceptId → p value for the default player.
// Backed by Drift; can be mutated via [ProficiencyNotifier.recordAnswer].
// ---------------------------------------------------------------------------

class ProficiencyNotifier extends AsyncNotifier<Map<String, double>> {
  @override
  Future<Map<String, double>> build() async {
    final player = await ref.watch(defaultPlayerProvider.future);
    final db = ref.watch(appDatabaseProvider);
    return db.proficiencyMapForPlayer(player.id);
  }

  Future<void> recordAnswer(String conceptId, {required bool correct}) async {
    final player = await ref.read(defaultPlayerProvider.future);
    final db = ref.read(appDatabaseProvider);

    final current =
        state.asData?.value[conceptId] ??
        initialProficiency(
          findConceptById(conceptId)!.gradeLevel,
          player.gradeLevel,
        );

    final updated = updateProficiency(current, correct: correct);
    await db.upsertProficiency(
      player.id,
      conceptId,
      updated,
      correct: correct,
    );

    ref.invalidateSelf();
  }
}

final proficiencyProvider =
    AsyncNotifierProvider<ProficiencyNotifier, Map<String, double>>(
      ProficiencyNotifier.new,
    );

// ---------------------------------------------------------------------------
// Wheel concepts — concepts in challenging or comfortable band.
// Falls back to all concepts if none qualify (should not happen in practice).
// ---------------------------------------------------------------------------

final wheelConceptsProvider = FutureProvider<List<Concept>>((ref) async {
  final profMap = await ref.watch(proficiencyProvider.future);
  final player = await ref.watch(defaultPlayerProvider.future);

  final onWheel = allConcepts.where((c) {
    final p =
        profMap[c.id] ?? initialProficiency(c.gradeLevel, player.gradeLevel);
    final band = bandForProficiency(p);
    return band == ProficiencyBand.challenging ||
        band == ProficiencyBand.comfortable;
  }).toList();

  return onWheel.isEmpty ? allConcepts : onWheel;
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
      profMap[conceptId] ?? initialProficiency(concept.gradeLevel, playerGrade);
  return bandForProficiency(p);
}
