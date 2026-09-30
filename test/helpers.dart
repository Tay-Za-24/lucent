import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucent/data/store.dart';
import 'package:lucent/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens the app on a fresh in-memory database, phone-sized.
Future<AppStore> openApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  databaseFactory = databaseFactoryFfiNoIsolate;
  final store = (await tester.runAsync(() => AppStore.open(path: inMemoryDatabasePath)))!;
  await tester.pumpWidget(LucentApp(store: store));
  return store;
}

Future<void> tapAndSettle(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Finder nav(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// Goes through onboarding creating "Food" (expense) and "Salary" (income).
Future<void> onboard(WidgetTester tester) async {
  await tapAndSettle(tester, find.text('Get started'));
  await tapAndSettle(tester, find.text('Continue'));
  await tapAndSettle(tester, find.text('Add').first);
  await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Food');
  await tapAndSettle(tester, find.text('Save'));
  await tapAndSettle(tester, find.text('Add').last);
  await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Salary');
  await tapAndSettle(tester, find.text('Save'));
  await tapAndSettle(tester, find.text('Start using Lucent'));
}
