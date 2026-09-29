import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucent/data/db.dart';
import 'package:lucent/data/goal.dart';
import 'package:lucent/data/models.dart';
import 'package:lucent/data/store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers.dart';

void main() {
  group('percentage goal', () {
    test('is worked out from the month\'s income', () {
      const g = SavingsGoal(GoalKind.percent, 20);
      expect(g.target(1500000), 300000);
      final p = GoalProgress(g, 1500000, 350000);
      expect(p.reached, isTrue);
      expect(p.toGo, 0);
      expect(p.fraction, 1.0);
    });

    test('rounds to the nearest minor unit (whole units or cents)', () {
      const g = SavingsGoal(GoalKind.percent, 15);
      expect(g.target(333), 50); // 49.95 -> 50
      expect(g.target(12345), 1852); // 123.45 at 2 dp -> 18.52 (18.5175)
    });

    test('zero income needs income, not "reached"', () {
      final p = GoalProgress(const SavingsGoal(GoalKind.percent, 20), 0, 0);
      expect(p.needsIncome, isTrue);
      expect(p.reached, isFalse);
      expect(p.target, 0);
      expect(p.fraction, 0);
    });

    test('negative net shows an empty bar and the full gap', () {
      final p = GoalProgress(
        const SavingsGoal(GoalKind.amount, 200000),
        100000,
        -50000,
      );
      expect(p.fraction, 0);
      expect(p.toGo, 250000);
      expect(p.reached, isFalse);
    });
  });

  test('0.2.0 database (schema 1) upgrades and keeps its data', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    final dir = await Directory.systemTemp.createTemp('lucent_mig');
    final path = '${dir.path}/lucent.db';
    final now = DateTime.now();
    final key = monthKey(now);

    final v1 = await openLucentDb(path: path, version: 1);
    await v1.insert('settings', {'key': 'onboarded', 'value': '1'});
    await v1.insert('settings', {'key': 'currency', 'value': 'K'});
    await v1.insert('categories', {
      'id': 'c1',
      'name': 'Food',
      'kind': 'expense',
      'color': 0,
      'archived': 0,
      'created_at': 1,
    });
    await v1.insert('categories', {
      'id': 'c2',
      'name': 'Salary',
      'kind': 'income',
      'color': 1,
      'archived': 0,
      'created_at': 2,
    });
    await v1.insert('entries', {
      'id': 'e1',
      'kind': 'expense',
      'amount': 4000,
      'category_id': 'c1',
      'date': '$key-01',
      'created_at': 1,
    });
    await v1.insert('entries', {
      'id': 'e2',
      'kind': 'income',
      'amount': 10000,
      'category_id': 'c2',
      'date': '$key-01',
      'created_at': 2,
    });
    await v1.insert('budgets', {
      'id': 'b1',
      'category_id': 'c1',
      'month': key,
      'amount': 5000,
    });
    await v1.close();

    final s = await AppStore.open(path: path);
    expect(s.onboarded, isTrue);
    expect(s.categories.map((c) => c.name), ['Food', 'Salary']);
    expect(s.totalIn, 10000);
    expect(s.totalOut, 4000);
    expect(s.limits['c1'], 5000);
    expect(s.goal, isNull);
    expect(s.goalProgress, isNull);

    await s.setGoal(const SavingsGoal(GoalKind.percent, 50));
    expect(s.goalProgress!.target, 5000);
    expect(s.goalProgress!.saved, 6000);
    expect(s.goalProgress!.reached, isTrue);

    // Amount goals follow a change of decimal places like other amounts.
    await s.setGoal(const SavingsGoal(GoalKind.amount, 2000));
    await s.setDecimals(2);
    expect(s.goal, const SavingsGoal(GoalKind.amount, 200000));

    final db = await openLucentDb(path: path);
    expect(await db.getVersion(), dbVersion);
    await db.close();
    await dir.delete(recursive: true);
  });

  testWidgets('Home shows saved against the goal', (tester) async {
    final store = await openApp(tester);
    await onboard(tester);
    final salary = store.activeCategories(Kind.income).first.id;
    final food = store.activeCategories(Kind.expense).first.id;
    await tester.runAsync(() async {
      await store.saveEntry(
        kind: Kind.income,
        amount: 100000,
        categoryId: salary,
        date: DateTime.now(),
      );
      await store.saveEntry(
        kind: Kind.expense,
        amount: 30000,
        categoryId: food,
        date: DateTime.now(),
      );
    });
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Set goal'));
    await tapAndSettle(tester, find.text('% of income'));
    await tester.enterText(find.byKey(const Key('goal-value')), '20');
    await tester.runAsync(() async {
      await tester.tap(find.text('Save'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(store.goal, const SavingsGoal(GoalKind.percent, 20));
    expect(find.text('Goal reached'), findsOneWidget);
    expect(find.textContaining('K 70,000 of K 20,000 saved'), findsOneWidget);
  });
}
