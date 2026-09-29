import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'db.dart';
import 'goal.dart';
import 'models.dart';

const _uuid = Uuid();

/// How the Budgets tab visualises spending.
enum BudgetDisplay { bars, ring }

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
  BudgetDisplay budgetDisplay = BudgetDisplay.bars;

  List<Category> categories = [];
  Set<String> usedCategoryIds = {};

  /// First day of the month being viewed.
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  List<Entry> monthEntries = [];

  /// categoryId -> limit (minor units) in effect for [month].
  Map<String, int> limits = {};

  /// Savings goal in effect for [month] (null = none).
  SavingsGoal? goal;

  /// [path] is only used by tests (e.g. an in-memory database).
  static Future<AppStore> open({String? path}) async {
    final s = AppStore._(await openLucentDb(path: path));
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
    themeMode = ThemeMode.values.firstWhere(
      (t) => t.name == m['theme'],
      orElse: () => ThemeMode.system,
    );
    budgetDisplay = BudgetDisplay.values.firstWhere(
      (b) => b.name == m['budget_display'],
      orElse: () => BudgetDisplay.bars,
    );
  }

  Future<void> _setSetting(String key, String value) => _db.insert('settings', {
    'key': key,
    'value': value,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

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
        await txn.rawUpdate('UPDATE budgets SET amount = $sqlAmount WHERE amount IS NOT NULL');
        await txn.rawUpdate(
          "UPDATE savings_goals SET value = MAX(1, ${sqlAmount.replaceAll('amount', 'value')}) "
          "WHERE kind = 'amount'",
        );
      });
    }
    decimals = d;
    await _setSetting('decimals', '$d');
    await _loadMonth();
  }

  Future<void> setBudgetDisplay(BudgetDisplay d) async {
    budgetDisplay = d;
    await _setSetting('budget_display', d.name);
    notifyListeners();
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
    final used = await _db.rawQuery('SELECT DISTINCT category_id FROM entries');
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

  Future<Category> addCategory(String name, Kind kind, int color) async {
    final c = Category(id: _uuid.v4(), name: name.trim(), kind: kind, color: color);
    await _db.insert('categories', {
      ...c.toRow(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    categories.add(c);
    notifyListeners();
    return c;
  }

  Future<void> updateCategory(Category c) async {
    await _db.update(
      'categories',
      {'name': c.name.trim(), 'color': c.color, 'archived': c.archived ? 1 : 0},
      where: 'id = ?',
      whereArgs: [c.id],
    );
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
  /// Home, Entries and Budgets always show the current calendar month.
  /// Called after changes and when the app comes back to the foreground, so a
  /// new month starts fresh on the 1st even if the app stayed open.
  Future<void> refreshMonth() async {
    final now = DateTime.now();
    month = DateTime(now.year, now.month);
    await _loadMonth();
  }

  Future<void> _loadMonth() async {
    final d = await monthData(month);
    monthEntries = d.entries;
    limits = d.limits;
    goal = d.goal;
    notifyListeners();
  }

  /// Entries and budget limits of any month (used by History, read-only).
  Future<MonthData> monthData(DateTime m) async {
    final key = monthKey(m);
    final rows = await _db.query(
      'entries',
      where: 'date LIKE ?',
      whereArgs: ['$key-%'],
      orderBy: 'date DESC, created_at DESC',
    );
    // Latest budget row at or before this month wins, per category.
    final b = await _db.query('budgets', where: 'month <= ?', whereArgs: [key], orderBy: 'month');
    final l = <String, int?>{};
    for (final r in b) {
      l[r['category_id'] as String] = r['amount'] as int?;
    }
    // Same rule for the savings goal: latest row at or before this month.
    final g = await _db.query(
      'savings_goals',
      where: 'month <= ?',
      whereArgs: [key],
      orderBy: 'month DESC',
      limit: 1,
    );
    SavingsGoal? goal;
    if (g.isNotEmpty && g.first['kind'] != 'none') {
      goal = SavingsGoal(
        g.first['kind'] == 'percent' ? GoalKind.percent : GoalKind.amount,
        g.first['value'] as int,
      );
    }
    return MonthData(
      DateTime(m.year, m.month),
      rows.map(Entry.fromRow).toList(),
      {
        for (final e in l.entries)
          if (e.value != null) e.key: e.value!,
      },
      goal,
    );
  }

  /// Past months (before the current one) that have entries or had a budget
  /// set, most recent first, with their totals.
  Future<List<MonthSummary>> pastMonths() async {
    final now = DateTime.now();
    final current = monthKey(DateTime(now.year, now.month));
    final rows = await _db.rawQuery(
      "SELECT substr(date, 1, 7) AS m, "
      "SUM(CASE WHEN kind = 'income' THEN amount ELSE 0 END) AS inc, "
      "SUM(CASE WHEN kind = 'expense' THEN amount ELSE 0 END) AS exp "
      'FROM entries WHERE substr(date, 1, 7) < ? GROUP BY m',
      [current],
    );
    final byKey = <String, MonthSummary>{
      for (final r in rows)
        r['m'] as String: MonthSummary(
          _parseMonthKey(r['m'] as String),
          (r['inc'] as int?) ?? 0,
          (r['exp'] as int?) ?? 0,
        ),
    };
    final b = await _db.rawQuery(
      'SELECT DISTINCT month FROM budgets WHERE month < ? AND amount IS NOT NULL',
      [current],
    );
    for (final r in b) {
      final k = r['month'] as String;
      byKey.putIfAbsent(k, () => MonthSummary(_parseMonthKey(k), 0, 0));
    }
    return byKey.values.toList()..sort((a, b) => b.month.compareTo(a.month));
  }

  static DateTime _parseMonthKey(String k) =>
      DateTime(int.parse(k.substring(0, 4)), int.parse(k.substring(5, 7)));

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
      await _db.insert('entries', {
        ...e.toRow(),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      await _db.update('entries', e.toRow(), where: 'id = ?', whereArgs: [id]);
    }
    usedCategoryIds.add(categoryId);
    await _loadCategories();
    await refreshMonth();
  }

  Future<void> deleteEntry(String id) async {
    await _db.delete('entries', where: 'id = ?', whereArgs: [id]);
    await _loadCategories();
    await refreshMonth();
  }

  // ---------- Budgets ----------
  /// Sets (or clears with null) the limit for a category from the selected
  /// month onwards. Earlier months keep their own limits.
  Future<void> setLimit(String categoryId, int? amount) async {
    final key = monthKey(month);
    await _db.transaction((txn) async {
      await txn.delete(
        'budgets',
        where: 'category_id = ? AND month >= ?',
        whereArgs: [categoryId, key],
      );
      await txn.insert('budgets', {
        'id': _uuid.v4(),
        'category_id': categoryId,
        'month': key,
        'amount': amount,
      });
    });
    await _loadMonth();
  }

  // ---------- Savings goal ----------
  /// Sets (or clears with null) the savings goal from the current month
  /// onwards. Earlier months keep the goal they had.
  Future<void> setGoal(SavingsGoal? g) async {
    final key = monthKey(month);
    await _db.transaction((txn) async {
      await txn.delete('savings_goals', where: 'month >= ?', whereArgs: [key]);
      await txn.insert('savings_goals', {
        'month': key,
        'kind': g?.kind.name ?? 'none',
        'value': g?.value ?? 0,
      });
    });
    await _loadMonth();
  }

  // ---------- Computed totals (never stored) ----------
  MonthData get current => MonthData(month, monthEntries, limits, goal);
  GoalProgress? get goalProgress => current.goalProgress;
  int get totalIn => current.totalIn;
  int get totalOut => current.totalOut;
  int get net => totalIn - totalOut;
  int spentIn(String categoryId) => current.spentIn(categoryId);
  List<BudgetLine> budgetLines() => current.budgetLines(categories);
}

/// One month's entries and limits, with totals computed on the fly.
class MonthData {
  MonthData(this.month, this.entries, this.limits, [this.goal]);
  final DateTime month;
  final List<Entry> entries;
  final Map<String, int> limits;
  final SavingsGoal? goal;

  /// Saved (= net) against the goal, or null when no goal applies.
  GoalProgress? get goalProgress {
    final g = goal;
    return g == null ? null : GoalProgress(g, totalIn, net);
  }

  int get totalIn =>
      entries.where((e) => e.kind == Kind.income).fold(0, (s, e) => s + e.amount);
  int get totalOut =>
      entries.where((e) => e.kind == Kind.expense).fold(0, (s, e) => s + e.amount);
  int get net => totalIn - totalOut;

  int spentIn(String categoryId) => entries
      .where((e) => e.kind == Kind.expense && e.categoryId == categoryId)
      .fold(0, (s, e) => s + e.amount);

  /// Expense categories to show: active ones, plus archived ones that still
  /// have spending or a limit this month.
  List<BudgetLine> budgetLines(List<Category> categories) => categories
      .where(
        (c) =>
            c.kind == Kind.expense &&
            (!c.archived || limits.containsKey(c.id) || spentIn(c.id) > 0),
      )
      .map((c) => BudgetLine(c, limits[c.id], spentIn(c.id)))
      .toList();
}

/// A past month's totals for the History list.
class MonthSummary {
  MonthSummary(this.month, this.totalIn, this.totalOut);
  final DateTime month;
  final int totalIn;
  final int totalOut;
  int get net => totalIn - totalOut;
}
