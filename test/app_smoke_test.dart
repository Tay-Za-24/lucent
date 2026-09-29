import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucent/data/store.dart';
import 'package:lucent/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Walks through setup, adding an entry and setting a budget, to catch
/// layout or runtime errors without a phone.
void main() {
  testWidgets('onboarding, add entry, budget', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    databaseFactory = databaseFactoryFfiNoIsolate;
    final store = (await tester.runAsync(() => AppStore.open(path: inMemoryDatabasePath)))!;
    await tester.pumpWidget(LucentApp(store: store));

    Finder nav(String label) =>
        find.descendant(of: find.byType(NavigationBar), matching: find.text(label));
    Future<void> tap(Finder f) async {
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    await tap(find.text('Get started'));
    await tap(find.text('Continue'));
    await tap(find.text('Add').first);
    await tester.enterText(find.byType(TextField).last, 'Food');
    await tap(find.text('Save'));
    await tap(find.text('Add').last);
    await tester.enterText(find.byType(TextField).last, 'Salary');
    await tap(find.text('Save'));
    await tap(find.text('Start using Lucent'));
    expect(find.text('Net'), findsOneWidget);

    await tap(find.byTooltip('Add entry'));
    await tester.enterText(find.byType(TextField).first, '1500');
    await tap(find.text('Food'));
    await tap(find.widgetWithText(FilledButton, 'Save'));
    expect(store.totalOut, 1500);

    await tap(nav('Budgets'));
    await tap(find.text('Food'));
    await tester.enterText(find.byType(TextField).last, '2000');
    await tap(find.text('Save'));
    expect(find.text('K 500 left'), findsOneWidget);

    await tap(nav('Entries'));
    expect(find.text('Food'), findsOneWidget);
    await tap(nav('Settings'));
    await tap(find.text('Dark'));
    await tap(nav('Home'));
    expect(find.text('K 500 left'), findsOneWidget);
  });
}
