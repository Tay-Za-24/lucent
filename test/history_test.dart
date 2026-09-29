import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lucent/data/models.dart';

import 'helpers.dart';

void main() {
  testWidgets('History lists past months and opens a read-only detail', (tester) async {
    final store = await openApp(tester);
    await onboard(tester);
    final now = DateTime.now();
    final last = DateTime(now.year, now.month - 1, 12);
    final food = store.activeCategories(Kind.expense).first.id;
    final salary = store.activeCategories(Kind.income).first.id;
    await tester.runAsync(() async {
      await store.saveEntry(kind: Kind.income, amount: 9000, categoryId: salary, date: last);
      await store.saveEntry(kind: Kind.expense, amount: 2500, categoryId: food, date: last);
    });
    await tester.pumpAndSettle();

    // Home shows only the current month: no month arrows, past entries not counted.
    expect(find.byTooltip('Previous month'), findsNothing);
    expect(store.totalIn, 0);

    await tapAndSettle(tester, nav('History'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    final title = DateFormat('MMMM yyyy').format(last);
    expect(find.text(title), findsOneWidget);
    expect(find.text('+K 6,500', findRichText: true), findsOneWidget);

    await tapAndSettle(tester, find.text(title));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('K 2,500 spent', findRichText: true), findsOneWidget);
    // Read-only: tapping an entry does not open the editor.
    await tapAndSettle(tester, find.text('Salary'));
    expect(find.text('Edit entry'), findsNothing);
  });
}
