import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Current database schema version.
///  1: 0.1.0 / 0.2.0 (settings, categories, entries, budgets)
///  2: 0.3.0 adds savings_goals
///  3: sync metadata (updated_at, device_id, deleted_at) on every data table
const dbVersion = 3;

/// Tables that travel between devices. Each row has a random (or natural,
/// for savings_goals: the month) ID, the device that last changed it, its
/// last-modified time and a soft-delete time.
const syncTables = ['categories', 'entries', 'budgets', 'savings_goals'];

/// Opens (and on first run creates) the local SQLite database file.
/// Older files are upgraded step by step, keeping all existing data.
Future<Database> openLucentDb({String? path, int version = dbVersion}) async {
  path ??= p.join(await getDatabasesPath(), 'lucent.db');
  return openDatabase(
    path,
    version: version,
    onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    onCreate: (db, v) async {
      await _createV1(db);
      if (v >= 2) await _createV2(db);
      if (v >= 3) await _upgradeV3(db);
    },
    onUpgrade: (db, from, to) async {
      if (from < 2 && to >= 2) await _createV2(db);
      if (from < 3 && to >= 3) await _upgradeV3(db);
    },
  );
}

/// v3: adds sync metadata to every data table. Existing rows keep their data;
/// their last-modified time becomes their creation time (or now, for tables
/// without one) and they are marked as live (not deleted).
Future<void> _upgradeV3(DatabaseExecutor db) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  for (final t in syncTables) {
    await db.execute('ALTER TABLE $t ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE $t ADD COLUMN device_id TEXT');
    await db.execute('ALTER TABLE $t ADD COLUMN deleted_at INTEGER');
  }
  await db.execute('UPDATE categories SET updated_at = created_at');
  await db.execute('UPDATE entries SET updated_at = created_at');
  await db.execute('UPDATE budgets SET updated_at = $now');
  await db.execute('UPDATE savings_goals SET updated_at = $now');
}

/// v2: one savings goal for the book. Like budgets, a row applies from
/// `month` onwards until a later row replaces it; kind 'none' = no goal.
Future<void> _createV2(DatabaseExecutor db) => db.execute('''
  CREATE TABLE IF NOT EXISTS savings_goals (
    month TEXT PRIMARY KEY,
    kind TEXT NOT NULL CHECK (kind IN ('amount','percent','none')),
    value INTEGER NOT NULL DEFAULT 0
  )''');

Future<void> _createV1(DatabaseExecutor db) async {
  await db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )''');
  await db.execute('''
        CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          kind TEXT NOT NULL CHECK (kind IN ('expense','income')),
          color INTEGER NOT NULL DEFAULT 0,
          archived INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        )''');
  await db.execute('''
        CREATE TABLE entries (
          id TEXT PRIMARY KEY,
          kind TEXT NOT NULL CHECK (kind IN ('expense','income')),
          amount INTEGER NOT NULL CHECK (amount > 0),
          category_id TEXT NOT NULL REFERENCES categories(id),
          date TEXT NOT NULL,
          note TEXT,
          created_at INTEGER NOT NULL
        )''');
  await db.execute('CREATE INDEX idx_entries_date ON entries(date)');
  // A budget row sets a category's monthly limit from `month` onwards,
  // until a later row replaces it. amount NULL = no limit from that month.
  await db.execute('''
        CREATE TABLE budgets (
          id TEXT PRIMARY KEY,
          category_id TEXT NOT NULL REFERENCES categories(id),
          month TEXT NOT NULL,
          amount INTEGER,
          UNIQUE (category_id, month)
        )''');
}
