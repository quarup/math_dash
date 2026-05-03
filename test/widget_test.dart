import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_dash/app.dart';
import 'package:math_dash/data/database.dart';
import 'package:math_dash/state/player_provider.dart';

void main() {
  testWidgets('app launches and shows launcher screen', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MathDashApp(),
      ),
    );
    await tester.pump(); // let FutureProvider resolve

    // With no players, the launcher shows the creation screen.
    expect(find.text('New Player'), findsOneWidget);
  });
}
