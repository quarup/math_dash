import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/unlock_rule.dart';

/// Pure-Dart engine that decides which building types are *available to buy*
/// given a snapshot of the player + city state. Availability is the whole
/// story: a building whose unlock rule passes shows in the build catalog and
/// is bought directly for its coin price (no research step).
///
/// Distinct from `lib/domain/concepts/dag_engine.dart` — that one drives the
/// math-concept drip-feed for the wheel; this one drives the building DAG.
class BuildingDagEngine {
  const BuildingDagEngine();

  /// All building types whose `unlockRule` is satisfied by `ctx`.
  /// Returned in registry order; deduplicated by id (which is implicit since
  /// the registry contains each id once).
  List<BuildingType> availableToBuy(UnlockContext ctx) {
    return buildingRegistry.where((b) => b.unlockRule.evaluate(ctx)).toList();
  }
}
