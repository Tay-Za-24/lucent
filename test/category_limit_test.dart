import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucent/data/models.dart';

import 'helpers.dart';

void main() {
  testWidgets(
    'Category editor sets, shows, changes and clears a monthly limit',
    (tester) async {
      final store = await openApp(tester);
      await onboard(tester);
      // Onboarding categories have no limit unless one is typed.
      expect(store.limits, isEmpty);

      await tapAndSettle(tester, nav('Settings'));
      await tapAndSettle(tester, find.text('Categories'));

      // New expense category with a limit typed in Myanmar digits and a comma.
      await tapAndSettle(tester, find.byTooltip('Add category'));
      expect(find.byKey(const Key('category-limit')), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Rent');
      await tester.enterText(
        find.byKey(const Key('category-limit')),
        '\u1045\u1040,\u1040\u1040\u1040',
      );
      await tapAndSettle(tester, find.text('Save'));
      final rent = store.categories.firstWhere((c) => c.name == 'Rent');
      expect(store.limits[rent.id], 50000);
      expect(find.text('Limit K 50,000 a month'), findsOneWidget);

      // The Budgets screen uses the same limit.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapAndSettle(tester, nav('Budgets'));
      expect(find.text('K 50,000 left'), findsOneWidget);
      await tapAndSettle(tester, nav('Settings'));
      await tapAndSettle(tester, find.text('Categories'));

      // Editing shows the current limit and can change it.
      await tapAndSettle(tester, find.text('Rent'));
      final field = tester.widget<TextField>(
        find.byKey(const Key('category-limit')),
      );
      expect(field.controller!.text, '50000');
      await tester.enterText(find.byKey(const Key('category-limit')), '60,000');
      await tapAndSettle(tester, find.text('Save'));
      expect(store.limits[rent.id], 60000);

      // Invalid input is rejected, empty clears the limit.
      await tapAndSettle(tester, find.text('Rent'));
      await tester.enterText(find.byKey(const Key('category-limit')), '0');
      await tapAndSettle(tester, find.text('Save'));
      expect(
        find.text('Enter an amount greater than zero, or leave it empty'),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(const Key('category-limit')), '');
      await tapAndSettle(tester, find.text('Save'));
      expect(store.limits.containsKey(rent.id), isFalse);

      // Income categories don't get the field.
      await tapAndSettle(tester, find.byTooltip('Add category'));
      await tapAndSettle(
        tester,
        find.descendant(
          of: find.byType(SegmentedButton<Kind>),
          matching: find.text('Income'),
        ),
      );
      expect(find.byKey(const Key('category-limit')), findsNothing);
      await tapAndSettle(tester, find.text('Cancel'));
      final salary = store.categories.firstWhere((c) => c.kind == Kind.income);
      await tapAndSettle(tester, find.text(salary.name));
      expect(find.byKey(const Key('category-limit')), findsNothing);
      await tapAndSettle(tester, find.text('Cancel'));

      // Two decimal places: 1,234.5 -> 123450 minor units.
      await tester.runAsync(() => store.setDecimals(2));
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.byTooltip('Add category'));
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Travel');
      await tester.enterText(
        find.byKey(const Key('category-limit')),
        '1,234.5',
      );
      await tapAndSettle(tester, find.text('Save'));
      final travel = store.categories.firstWhere((c) => c.name == 'Travel');
      expect(store.limits[travel.id], 123450);
    },
  );
}
