import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Regression: saving an income entry must show up on Home and Entries,
/// and a failed validation must show a visible message.
void main() {
  testWidgets('add income and expense, see them on Home and Entries', (tester) async {
    final store = await openApp(tester);
    await onboard(tester);
    Finder rich(String s) => find.text(s, findRichText: true);

    // Nothing typed: a visible message, the form stays open.
    await tapAndSettle(tester, find.byTooltip('Add entry'));
    await tapAndSettle(tester, find.text('Income'));
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Save'));
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Enter an amount greater than zero'),
      ),
      findsOneWidget,
    );
    expect(find.text('New entry'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '5,000');
    await tapAndSettle(tester, find.text('Salary'));
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Save'));
    expect(find.text('New entry'), findsNothing);
    expect(store.totalIn, 5000);
    expect(rich('+K 5,000'), findsOneWidget); // In on Home
    expect(rich('K\u20095,000'), findsOneWidget); // Net on Home (large, thin space)

    // Expense still works; typing the amount before switching type keeps it.
    await tapAndSettle(tester, find.byTooltip('Add entry'));
    await tapAndSettle(tester, find.text('Income'));
    await tester.enterText(find.byType(TextField).first, '1500');
    await tapAndSettle(tester, find.text('Expense'));
    await tapAndSettle(tester, find.text('Food'));
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Save'));
    expect(store.totalOut, 1500);
    expect(rich('K 1,500'), findsOneWidget); // Out
    expect(rich('K\u20093,500'), findsOneWidget); // Net

    await tapAndSettle(tester, nav('Entries'));
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
  });
}
