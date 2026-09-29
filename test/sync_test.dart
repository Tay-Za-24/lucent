import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucent/data/models.dart';
import 'package:lucent/data/store.dart';
import 'package:lucent/data/sync.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

late Directory tmp;
int _n = 0;

Future<AppStore> newStore({int decimals = 0, String currency = 'K'}) async {
  final s = await AppStore.open(path: '${tmp.path}/db${_n++}.db');
  await s.setCurrency(currency);
  await s.setDecimals(decimals);
  return s;
}

/// Simulates the wire: bundle -> JSON text -> bundle.
Future<Map<String, Object?>> wire(AppStore s) async =>
    jsonDecode(jsonEncode(await s.exportBook())) as Map<String, Object?>;

Future<int> count(AppStore s, String table, [String where = '1']) async =>
    (await s.db.rawQuery('SELECT COUNT(*) c FROM $table WHERE $where')).first['c'] as int;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });
  setUp(() => tmp = Directory.systemTemp.createTempSync('lucent_sync'));
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<AppStore> seeded() async {
    final a = await newStore();
    final food = await a.addCategory('Food', Kind.expense, 1);
    final pay = await a.addCategory('Salary', Kind.income, 2);
    await a.saveEntry(kind: Kind.expense, amount: 5000, categoryId: food.id, date: DateTime.now());
    await a.saveEntry(kind: Kind.income, amount: 90000, categoryId: pay.id, date: DateTime.now(), note: 'Sept');
    await a.setLimit(food.id, 20000);
    return a;
  }

  test('bundle survives JSON and passes validation', () async {
    final a = await seeded();
    final b = await wire(a);
    final recs = validateBundle(b);
    expect(recs['categories'], hasLength(2));
    expect(recs['entries'], hasLength(2));
    expect(recs['budgets'], hasLength(1));
    expect((b['currency'] as Map)['symbol'], 'K');
    expect(recs['entries']!.every((e) => e['device_id'] == a.deviceId && (e['updated_at'] as int) > 0), isTrue);
  });

  test('damaged bundles are rejected', () async {
    final b = await wire(await seeded());
    ((b['records'] as Map)['entries'] as List).first['amount'] = -3;
    expect(() => validateBundle(b), throwsA(isA<BundleError>()));
    expect(() => validateBundle({'format': 'x'}), throwsA(isA<BundleError>()));
  });

  test('import into an empty book, then again: no duplicates', () async {
    final a = await seeded();
    final b = await newStore(currency: r'$', decimals: 2);
    final sum = await b.importBook(await wire(a));
    expect(sum.message, startsWith('Received 2 entries'));
    expect(b.currency, 'K'); // empty book adopts the sender's currency
    expect(b.decimals, 0);
    expect(b.monthEntries, hasLength(2));
    expect(b.limits.values, [20000]);
    final again = await b.importBook(await wire(a));
    expect(again.result['entries'].unchanged, 2);
    expect(await count(b, 'entries'), 2);
    expect(await count(b, 'categories'), 2);
    expect(await count(b, 'budgets'), 1);
  });

  test('newer edit wins in both directions, older is ignored', () async {
    final a = await seeded();
    final b = await newStore();
    await b.importBook(await wire(a));
    final e = a.monthEntries.firstWhere((x) => x.kind == Kind.expense);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await b.saveEntry(id: e.id, kind: e.kind, amount: 7777, categoryId: e.categoryId, date: e.date);
    // a's copy is older: importing it into b changes nothing.
    await b.importBook(await wire(a));
    expect(b.monthEntries.firstWhere((x) => x.id == e.id).amount, 7777);
    // b's newer copy wins on a.
    final r = await a.importBook(await wire(b));
    expect(r.result['entries'].updated, 1);
    expect(a.monthEntries.firstWhere((x) => x.id == e.id).amount, 7777);
  });

  test('soft deletes travel and stay deleted', () async {
    final a = await seeded();
    final b = await newStore();
    await b.importBook(await wire(a));
    final e = a.monthEntries.first;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await a.deleteEntry(e.id);
    expect(await count(a, 'entries', 'deleted_at IS NOT NULL'), 1);
    final r = await b.importBook(await wire(a));
    expect(r.result['entries'].deleted, 1);
    expect(b.monthEntries.map((x) => x.id), isNot(contains(e.id)));
    // b's old live copy doesn't resurrect it on a.
    await a.importBook(await wire(b));
    expect(a.monthEntries.map((x) => x.id), isNot(contains(e.id)));
  });

  test('same-named categories from separate setups merge, budgets stay single', () async {
    final a = await seeded();
    final b = await newStore();
    final myFood = await b.addCategory(' food ', Kind.expense, 3);
    await b.setLimit(myFood.id, 1000);
    final r = await b.importBook(await wire(a));
    expect(r.result['categories'].matched, 1);
    expect(b.activeCategories(Kind.expense).map((c) => c.id), [myFood.id]);
    expect(b.spentIn(myFood.id), 5000);
    expect(await count(b, 'budgets', "category_id = '${myFood.id}'"), 1);
    await b.importBook(await wire(a));
    expect(await count(b, 'categories'), 2);
    expect(await count(b, 'entries'), 2);
  });

  test('different decimal places are refused and nothing changes', () async {
    final a = await seeded();
    final b = await newStore(decimals: 2);
    final c = await b.addCategory('Food', Kind.expense, 0);
    await b.saveEntry(kind: Kind.expense, amount: 150, categoryId: c.id, date: DateTime.now());
    await expectLater(b.importBook(await wire(a)), throwsA(isA<BundleError>()));
    expect(await count(b, 'entries'), 1);
  });

  test('different currency symbol imports with a warning', () async {
    final a = await seeded();
    final b = await newStore(currency: 'MMK');
    final c = await b.addCategory('Rent', Kind.expense, 0);
    await b.saveEntry(kind: Kind.expense, amount: 100, categoryId: c.id, date: DateTime.now());
    final r = await b.importBook(await wire(a));
    expect(r.warning, contains('"K"'));
    expect(b.currency, 'MMK');
    expect(b.monthEntries, hasLength(3));
  });
}
