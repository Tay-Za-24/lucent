import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'db.dart';
import 'models.dart';

const _uuid = Uuid();

/// Budget status of one expense category for the selected month.
class BudgetLine {
  BudgetLine(this.category, this.limit, this.spent);
  final Category category;
  final int? limit;
  final int spent;
  int get left => (limit ?? 0) - spent;
}

/// Holds app state in memory and writes every change to SQLite.
/// Screens listen to it and rebuild when it changes.
class AppStore extends ChangeNotifier {
  AppStore._(this._db);
  final Database _db;

  // Settings
  bool onboarded = false;
  String currency = 'K';
  int decimals = 0;
  ThemeMode themeMode = ThemeMode.system;

  List<Category> categories = [];
  Set<String> usedCategoryIds = {};

  /// First day of the month being viewed.
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  List<Entry> monthEntries = [];

  /// categoryId -> limit (minor units) in effect for [month].
  Map<String, int> limits = {};

  static Future<AppStore> open() async {
    final s = AppStore._(await openLucentDb());
    await s._loadSettings();
    await s._loadCategories();
    await s._loadMonth();
    return s;
  }

  // ---------- Settings ----------
  Future<void> _loadSettings() async {
    final rows = await _db.query('settings');
    final m = {for (final r in rows) r['key'] as String: r['value'] as String};
    onboarded = m['onboarded'] == '1';
    currency = m['currency'] ?? 'K';
    decimals = int.tryParse(m['decimals'] ?? '') ?? 0;
    themeMode = ThemeMode.values.firstWhere((t) => t.name == m['theme'],
        orElse: () => ThemeMode.system);
  }

  Future<void> _setSetting(String key, String value) => _db.insert(
      'settings', {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> setCurrency(String symbol) async {
    currency = symbol.trim();
    await _setSetting('currency', currency);
    notifyListeners();
  }

  /// Changes decimal places and converts every stored amount so values keep
  /// their meaning (2 -> 0 rounds to the nearest whole unit).
  Future<void> setDecimals(int d, {bool convert = true}) async {
    if (d == decimals) return;
    if (convert) {
      final sqlAmount = d > decimals ? 'amount * 100' : '(amount + 50) / 100';
      await _db.transaction((txn) async {
        await txn.rawUpdate('UPDATE entries SET amount = MAX(1, $sqlAmount)');
        await txn.rawUpdate(
            'UPDATE budgets SET amount = $sqlAmount WHERE amount IS NOT NULL');
      });
    }
    decimals = d;
    await _setSetting('decimals', '$d');
    await _loadMonth();
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    await _setSetting('theme', m.name);
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    onboarded = true;
    await _setSetting('onboarded', '1');
    notifyListeners();
  }

  // ---------- Categories ----------
  Future<void> _loadCategories() async {
    final rows = await _db.query('categories', orderBy: 'created_at');
    categories = rows.map(Category.fromRow).toList();
    final used =
        await _db.rawQuery('SELECT DISTINCT category_id FROM entries');
    usedCategoryIds = used.map((r) => r['category_id'] as String).toSet();
  }

  Category? categoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<Category> activeCategories(Kind kind) =>
      categories.where((c) => c.kind == kind && !c.archived).toList();

  Future<void> addCategory(String name, Kind kind, int color) async {
    final c = Category(id: _uuid.v4(), name: name.trim(), kind: kind, color: color);
    await _db.insert('categories',
        {...c.toRow(), 'created_at': DateTime.now().millisecondsSinceEpoch});
    categories.add(c);
    notifyListeners();
  }

  Future<void> updateCategory(Category c) async {
    await _db.update('categories',
        {'name': c.name.trim(), 'color': c.color, 'archived': c.archived ? 1 : 0},
        where: 'id = ?', whereArgs: [c.id]);
    notifyListeners();
  }

  /// Only allowed when no entry uses the category.
  Future<bool> deleteCategory(Category c) async {
    if (usedCategoryIds.contains(c.id)) return false;
    await _db.transaction((txn) async {
      await txn.delete('budgets', where: 'category_id = ?', whereArgs: [c.id]);
      await txn.delete('categories', where: 'id = ?', whereArgs: [c.id]);
    });
    categories.removeWhere((x) => x.id == c.id);
    limits.remove(c.id);
    notifyListeners();
    return true;
  }

  // ---------- Month & entries ----------
  Future<void> setMonth(DateTime m) async {
    month = DateTime(m.year, m.month);
    await _loadMonth();
  }

  Future<void> shiftMonth(int delta) =>
      setMonth(DateTime(month.year, month.month + delta));

  Future<void> _loadMonth() async {
    final key = monthKey(month);
    final rows = await _db.query('entries',
        where: 'date LIKE ?',
        whereArgs: ['$key-%'],
        orderBy: 'date DESC, created_at DESC');
    monthEntries = rows.map(Entry.fromRow).toList();
    // Latest budget row at or before this month wins, per category.
    final b = await _db.query('budgets',
        where: 'month <= ?', whereArgs: [key], orderBy: 'month');
    final l = <String, int?>{};
    for (final r in b) {
      l[r['category_id'] as String] = r['amount'] as int?;
    }
    limits = {
      for (final e in l.entries)
        if (e.value != null) e.key: e.value!
    };
    notifyListeners();
  }

  Future<void> saveEntry({
    String? id,
    required Kind kind,
    required int amount,
    required String categoryId,
    required DateTime date,
    String? note,
  }) async {
    final e = Entry(
      id: id ?? _uuid.v4(),
      kind: kind,
      amount: amount,
      categoryId: categoryId,
      date: DateTime(date.year, date.month, date.day),
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
    );
    if (id == null) {
      await _db.insert('entries',
          {...e.toRow(), 'created_at': DateTime.now().millisecondsSinceEpoch});
    } else {
      await _db.update('entries', e.toRow(), where: 'id = ?', whereArgs: [id]);
    }
    usedCategoryIds.add(categoryId);
    await _loadCategories();
    await _loadMonth();
  }

  Future<void> deleteEntry(String id) async {
    await _db.delete('entries', where: 'id = ?', whereArgs: [id]);
    await _loadCategories();
    await _loadMonth();
  }

  // ---------- Budgets ----------
  /// Sets (or clears with null) the limit for a category from the selected
  /// month onwards. Earlier months keep their own limits.
  Future<void> setLimit(String categoryId, int? amount) async {
    final key = monthKey(month);
    await _db.transaction((txn) async {
      await txn.delete('budgets',
          where: 'category_id = ? AND month >= ?', whereArgs: [categoryId, key]);
      await txn.insert('budgets', {
        'id': _uuid.v4(),
        'category_id': categoryId,
        'month': key,
        'amount': amount,
      });
    });
    await _loadMonth();
  }

  // ---------- Computed totals (never stored) ----------
  int get totalIn => monthEntries
      .where((e) => e.kind == Kind.income)
      .fold(0, (s, e) => s + e.amount);
  int get totalOut => monthEntries
      .where((e) => e.kind == Kind.expense)
      .fold(0, (s, e) => s + e.amount);
  int get net => totalIn - totalOut;

  int spentIn(String categoryId) => monthEntries
      .where((e) => e.kind == Kind.expense && e.categoryId == categoryId)
      .fold(0, (s, e) => s + e.amount);

  /// Expense categories to show on the budgets screen: active ones, plus
  /// archived ones that still have spending or a limit this month.
  List<BudgetLine> budgetLines() => categories
      .where((c) =>
          c.kind == Kind.expense &&
          (!c.archived || limits.containsKey(c.id) || spentIn(c.id) > 0))
      .map((c) => BudgetLine(c, limits[c.id], spentIn(c.id)))
      .toList();
}
