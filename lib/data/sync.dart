/// Export of the whole book as a JSON "bundle", and merging a bundle from
/// another device into this one.
///
/// Merge rules (per record, matched by its ID):
///  - unknown ID: added (deleted records are kept as deleted, so the
///    deletion is remembered);
///  - known ID: the copy with the later last-modified time (`updated_at`)
///    wins, including its deleted state; on a tie this device's copy stays;
///  - a new category with the same kind and name as one of ours (e.g. both
///    phones created "Food" during setup) is merged into ours instead of
///    creating a duplicate;
///  - budgets are one per category and month, so they are also matched on
///    that pair.
/// Everything is validated first and applied in one database transaction:
/// a bad bundle changes nothing.
library;

import 'package:sqflite/sqflite.dart';

import 'db.dart';

const bundleFormat = 'lucent-bundle';
const bundleSchema = 1;

/// A bundle that can't be imported; [message] is shown to the user.
class BundleError implements Exception {
  BundleError(this.message);
  final String message;
  @override
  String toString() => message;
}

typedef _Check = bool Function(Object? v);
bool _str(Object? v) => v is String && v.isNotEmpty;
bool _strOrNull(Object? v) => v == null || v is String;
bool _int(Object? v) => v is int;
bool _intOrNull(Object? v) => v == null || v is int;
bool _kind(Object? v) => v == 'expense' || v == 'income';
bool _bool01(Object? v) => v == 0 || v == 1;
bool _date(Object? v) =>
    v is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v) && DateTime.tryParse(v) != null;
bool _month(Object? v) => v is String && RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(v);

const Map<String, _Check> _meta = {
  'updated_at': _int,
  'device_id': _strOrNull,
  'deleted_at': _intOrNull,
};

/// Columns of each shared table and how to check them.
final Map<String, Map<String, _Check>> _schema = {
  'categories': {
    'id': _str,
    'name': _str,
    'kind': _kind,
    'color': _int,
    'archived': _bool01,
    'created_at': _int,
    ..._meta,
  },
  'entries': {
    'id': _str,
    'kind': _kind,
    'amount': (v) => v is int && v > 0,
    'category_id': _str,
    'date': _date,
    'note': _strOrNull,
    'created_at': _int,
    ..._meta,
  },
  'budgets': {
    'id': _str,
    'category_id': _str,
    'month': _month,
    'amount': (v) => v == null || (v is int && v >= 0),
    ..._meta,
  },
  'savings_goals': {
    'month': _month,
    'kind': (v) => v == 'amount' || v == 'percent' || v == 'none',
    'value': (v) => v is int && v >= 0,
    ..._meta,
  },
};

String _keyOf(String table) => table == 'savings_goals' ? 'month' : 'id';

/// Everything in the book (including deleted records) plus the currency.
Future<Map<String, Object?>> exportBundle(DatabaseExecutor db) async {
  final s = {
    for (final r in await db.query('settings')) r['key'] as String: r['value'] as String,
  };
  return {
    'format': bundleFormat,
    'schema': bundleSchema,
    'created_at': DateTime.now().millisecondsSinceEpoch,
    'source': {'device_id': s['device_id']},
    'currency': {'symbol': s['currency'] ?? 'K', 'decimals': int.tryParse(s['decimals'] ?? '') ?? 0},
    'records': {
      for (final t in syncTables)
        t: await db.query(t, columns: _schema[t]!.keys.toList(), orderBy: _keyOf(t)),
    },
  };
}

/// Checks the shape of every record; throws [BundleError] on the first problem.
/// Returns the records by table.
Map<String, List<Map<String, Object?>>> validateBundle(Map<String, Object?> b) {
  if (b['format'] != bundleFormat) throw BundleError('This is not Lucent data.');
  if (b['schema'] != bundleSchema) {
    throw BundleError('The other device runs a different Lucent version. Update both and try again.');
  }
  final c = b['currency'];
  if (c is! Map || c['symbol'] is! String || (c['decimals'] != 0 && c['decimals'] != 2)) {
    throw BundleError('The data has no valid currency settings.');
  }
  final recs = b['records'];
  if (recs is! Map) throw BundleError('The data has no records.');
  final out = <String, List<Map<String, Object?>>>{};
  for (final t in syncTables) {
    final list = recs[t] ?? const [];
    if (list is! List) throw BundleError('Damaged data ($t).');
    final seen = <Object?>{};
    out[t] = [
      for (final r in list)
        if (r is! Map)
          throw BundleError('Damaged data ($t).')
        else
          _checkRow(t, r.cast<String, Object?>(), seen),
    ];
  }
  final catIds = {for (final c in out['categories']!) c['id']};
  for (final t in ['entries', 'budgets']) {
    for (final r in out[t]!) {
      if (!catIds.contains(r['category_id'])) {
        throw BundleError('Damaged data: a record in $t points to a missing category.');
      }
    }
  }
  return out;
}

Map<String, Object?> _checkRow(String t, Map<String, Object?> r, Set<Object?> seen) {
  final row = <String, Object?>{};
  _schema[t]!.forEach((col, ok) {
    final v = r[col];
    if (!ok(v)) throw BundleError('Damaged data: bad "$col" in $t.');
    row[col] = v;
  });
  if (!seen.add(row[_keyOf(t)])) throw BundleError('Damaged data: repeated record in $t.');
  return row;
}

/// What a merge changed in one table.
class TableCounts {
  int added = 0, updated = 0, deleted = 0, unchanged = 0, matched = 0;
  @override
  String toString() =>
      'added $added, updated $updated, deleted $deleted, unchanged $unchanged, matched $matched';
}

class MergeResult {
  final Map<String, TableCounts> tables = {for (final t in syncTables) t: TableCounts()};
  TableCounts operator [](String t) => tables[t]!;

  /// Entries in the bundle that aren't deleted.
  int entriesReceived = 0;
}

String _norm(String s) => s.trim().toLowerCase();

/// Merges validated [records] (from [validateBundle]) into [db] in one transaction.
Future<MergeResult> mergeRecords(
  Database db,
  Map<String, List<Map<String, Object?>>> records,
) => db.transaction((txn) async {
  final res = MergeResult();
  res.entriesReceived = records['entries']!.where((e) => e['deleted_at'] == null).length;

  // Categories: by ID, else merge a new live one into our live one of the
  // same kind and name.
  final remap = <String, String>{};
  final localCats = {for (final c in await txn.query('categories')) c['id'] as String: c};
  final byName = <String, String>{
    for (final c in localCats.values)
      if (c['deleted_at'] == null) '${c['kind']}|${_norm(c['name'] as String)}': c['id'] as String,
  };
  final incomingIds = {for (final c in records['categories']!) c['id']};
  for (final c in records['categories']!) {
    final id = c['id'] as String;
    final local = localCats[id];
    if (local == null) {
      final match = byName['${c['kind']}|${_norm(c['name'] as String)}'];
      if (c['deleted_at'] == null && match != null && !incomingIds.contains(match)) {
        remap[id] = match;
        res['categories'].matched++;
        continue;
      }
      await txn.insert('categories', c);
      res['categories'].added++;
    } else {
      await _applyIfNewer(txn, 'categories', 'id', local, c, res['categories']);
    }
  }

  Map<String, Object?> fix(Map<String, Object?> r) =>
      remap.containsKey(r['category_id']) ? {...r, 'category_id': remap[r['category_id']]} : r;

  await _mergeByKey(txn, 'entries', 'id', records['entries']!.map(fix), res['entries']);
  await _mergeByKey(txn, 'savings_goals', 'month', records['savings_goals']!, res['savings_goals']);

  // Budgets: by ID, else by (category, month), which must stay unique.
  final counts = res['budgets'];
  for (final b in records['budgets']!.map(fix)) {
    var local = (await txn.query('budgets', where: 'id = ?', whereArgs: [b['id']])).firstOrNull;
    local ??= (await txn.query(
      'budgets',
      where: 'category_id = ? AND month = ?',
      whereArgs: [b['category_id'], b['month']],
    )).firstOrNull;
    if (local == null) {
      await txn.insert('budgets', b);
      counts.added++;
    } else {
      // Keep our row's ID so the (category, month) pair stays single.
      await _applyIfNewer(txn, 'budgets', 'id', local, {...b, 'id': local['id']}, counts);
    }
  }

  // A live entry must never point to a deleted category: bring it back.
  await txn.rawUpdate(
    'UPDATE categories SET deleted_at = NULL WHERE deleted_at IS NOT NULL AND id IN '
    '(SELECT category_id FROM entries WHERE deleted_at IS NULL)',
  );
  return res;
});

Future<void> _mergeByKey(
  Transaction txn,
  String table,
  String key,
  Iterable<Map<String, Object?>> rows,
  TableCounts counts,
) async {
  for (final r in rows) {
    final local = (await txn.query(table, where: '$key = ?', whereArgs: [r[key]])).firstOrNull;
    if (local == null) {
      await txn.insert(table, r);
      counts.added++;
    } else {
      await _applyIfNewer(txn, table, key, local, r, counts);
    }
  }
}

/// Newer last-modified time wins; a tie keeps this device's copy.
Future<void> _applyIfNewer(
  Transaction txn,
  String table,
  String key,
  Map<String, Object?> local,
  Map<String, Object?> incoming,
  TableCounts counts,
) async {
  if ((incoming['updated_at'] as int) <= (local['updated_at'] as int)) {
    counts.unchanged++;
    return;
  }
  await txn.update(table, incoming, where: '$key = ?', whereArgs: [local[key]]);
  if (local['deleted_at'] == null && incoming['deleted_at'] != null) {
    counts.deleted++;
  } else {
    counts.updated++;
  }
}
