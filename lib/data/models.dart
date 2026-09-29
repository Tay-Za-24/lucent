/// Plain data classes used across the app.
library;

enum Kind { expense, income }

Kind kindFromName(String s) => s == 'income' ? Kind.income : Kind.expense;

class Category {
  Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.color,
    this.archived = false,
  });

  final String id;
  String name;
  final Kind kind;

  /// Index into the fixed category palette (see theme.dart).
  int color;
  bool archived;

  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'color': color,
        'archived': archived ? 1 : 0,
      };

  static Category fromRow(Map<String, Object?> r) => Category(
        id: r['id'] as String,
        name: r['name'] as String,
        kind: kindFromName(r['kind'] as String),
        color: r['color'] as int,
        archived: (r['archived'] as int) == 1,
      );
}

class Entry {
  Entry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
  });

  final String id;
  final Kind kind;

  /// Amount in minor units (e.g. cents when 2 decimals are used). Always positive.
  final int amount;
  final String categoryId;

  /// Calendar date only (no time).
  final DateTime date;
  final String? note;

  Map<String, Object?> toRow() => {
        'id': id,
        'kind': kind.name,
        'amount': amount,
        'category_id': categoryId,
        'date': dateKey(date),
        'note': note,
      };

  static Entry fromRow(Map<String, Object?> r) => Entry(
        id: r['id'] as String,
        kind: kindFromName(r['kind'] as String),
        amount: r['amount'] as int,
        categoryId: r['category_id'] as String,
        date: DateTime.parse(r['date'] as String),
        note: r['note'] as String?,
      );
}

String _two(int n) => n.toString().padLeft(2, '0');

/// "2026-09-29"
String dateKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// "2026-09"
String monthKey(DateTime d) => '${d.year}-${_two(d.month)}';
