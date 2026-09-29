import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens (and on first run creates) the local SQLite database file.
Future<Database> openLucentDb({String? path}) async {
  path ??= p.join(await getDatabasesPath(), 'lucent.db');
  return openDatabase(
    path,
    version: 1,
    onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    onCreate: (db, version) async {
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
    },
  );
}
