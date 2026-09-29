import 'package:flutter_test/flutter_test.dart';
import 'package:lucent/data/models.dart';
import 'package:lucent/data/store.dart';
import 'package:lucent/widgets/budget_ring.dart';
import 'package:lucent/widgets/common.dart';

import 'helpers.dart';

void main() {
  testWidgets('Budget display: progress bars by default, ring chart from Settings', (tester) async {
    final store = await openApp(tester);
    await onboard(tester);
    final food = store.activeCategories(Kind.expense).first.id;
    await tester.runAsync(() async {
      await store.saveEntry(
        kind: Kind.expense,
        amount: 300,
        categoryId: food,
        date: DateTime.now(),
      );
      await store.setLimit(food, 1000);
    });
    await tester.pumpAndSettle();

    await tapAndSettle(tester, nav('Budgets'));
    expect(find.byType(BudgetBar), findsOneWidget);
    expect(find.byType(BudgetRing), findsNothing);
    expect(find.text('K 700 left'), findsOneWidget);

    await tapAndSettle(tester, nav('Settings'));
    await tapAndSettle(tester, find.text('Ring chart'));
    expect(store.budgetDisplay, BudgetDisplay.ring);

    await tapAndSettle(tester, nav('Budgets'));
    expect(find.byType(BudgetRing), findsOneWidget);
    expect(find.byType(BudgetBar), findsNothing);
    expect(find.text('Spent'), findsOneWidget);
    expect(find.text('K 700 left'), findsWidgets);
  });
}
