import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../money.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'category_editor.dart';

Future<void> openEntryForm(BuildContext context, {Entry? entry}) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => EntryFormScreen(entry: entry)));

/// Add or edit one income/expense entry.
class EntryFormScreen extends StatefulWidget {
  const EntryFormScreen({super.key, this.entry});
  final Entry? entry;
  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  late Kind _kind;
  late DateTime _date;
  String? _categoryId;
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _amountError;
  String? _categoryError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    final now = DateTime.now();
    _kind = e?.kind ?? Kind.expense;
    _date = e?.date ?? DateTime(now.year, now.month, now.day);
    _categoryId = e?.categoryId ?? _onlyCategory(_kind);
    _note.text = e?.note ?? '';
    if (e != null) {
      _amount.text = amountToInput(e.amount, StoreScope.read(context).decimals);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Pre-selects the category when there is exactly one to choose from.
  String? _onlyCategory(Kind kind) {
    final list = StoreScope.read(context).activeCategories(kind);
    return list.length == 1 ? list.first.id : null;
  }

  void _setKind(Kind k) {
    if (k == _kind) return;
    final s = StoreScope.read(context);
    final current = _categoryId == null ? null : s.categoryById(_categoryId!);
    setState(() {
      _kind = k;
      // Keep the typed amount; only drop the category if it's the other type.
      if (current == null || current.kind != k) _categoryId = _onlyCategory(k);
      _categoryError = null;
    });
  }

  Future<void> _newCategory() async {
    final s = StoreScope.read(context);
    final before = s.categories.map((c) => c.id).toSet();
    await showCategoryEditor(context, kind: _kind);
    if (!mounted) return;
    final added = s.categories.where((c) => !before.contains(c.id) && c.kind == _kind);
    if (added.isNotEmpty) {
      setState(() {
        _categoryId = added.first.id;
        _categoryError = null;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_saving) return;
    final s = StoreScope.read(context);
    final amount = parseAmount(_amount.text, s.decimals);
    final cat = _categoryId == null ? null : s.categoryById(_categoryId!);
    final amountError = amount == null ? 'Enter an amount greater than zero' : null;
    final categoryError = (cat == null || cat.kind != _kind)
        ? 'Choose ${_kind == Kind.income ? 'an income' : 'an expense'} category'
        : null;
    setState(() {
      _amountError = amountError;
      _categoryError = categoryError;
    });
    // Shown above the keyboard so it is never hidden (it used to appear only
    // at the bottom of the form, out of sight while typing).
    if (amountError != null || categoryError != null) {
      _showError(amountError ?? categoryError!);
      return;
    }
    setState(() => _saving = true);
    try {
      await s.saveEntry(
        id: widget.entry?.id,
        kind: _kind,
        amount: amount!,
        categoryId: cat!.id,
        date: _date,
        note: _note.text,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showError('Couldn\u2019t save: $e');
      }
      return;
    }
    HapticFeedback.selectionClick();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text('This can\u2019t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await StoreScope.read(context).deleteEntry(widget.entry!.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final t = context.text;
    final c = context.colors;
    final cats = s.categories
        .where((x) => x.kind == _kind && (!x.archived || x.id == _categoryId))
        .toList();
    final editing = widget.entry != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit entry' : 'New entry'),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: const Text('Save')),
          if (editing)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<Kind>(
              segments: const [
                ButtonSegment(value: Kind.expense, label: Text('Expense')),
                ButtonSegment(value: Kind.income, label: Text('Income')),
              ],
              selected: {_kind},
              onSelectionChanged: (v) => _setKind(v.first),
            ),
            const SizedBox(height: 24),
            Text('Amount', style: t.caption),
            const SizedBox(height: 8),
            TextField(
              controller: _amount,
              autofocus: !editing,
              keyboardType: TextInputType.numberWithOptions(decimal: s.decimals > 0),
              inputFormatters: [AmountInputFormatter(s.decimals)],
              style: t.displayAmount.copyWith(
                color: _kind == Kind.income ? c.accent : c.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: s.decimals > 0 ? '0.00' : '0',
                hintStyle: t.displayAmount.copyWith(color: c.textTertiary),
                prefixText: s.currency.isEmpty ? null : '${s.currency} ',
                prefixStyle: t.headlineAmount.copyWith(color: c.textSecondary),
                errorText: _amountError,
              ),
              onChanged: (_) {
                if (_amountError != null) setState(() => _amountError = null);
              },
            ),
            const SizedBox(height: 24),
            Text('Category', style: t.caption),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in cats)
                  ChoiceChip(
                    avatar: CategoryDot(cat),
                    label: Text(cat.name),
                    selected: _categoryId == cat.id,
                    onSelected: (_) => setState(() {
                      _categoryId = cat.id;
                      _categoryError = null;
                    }),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('New'),
                  onPressed: _newCategory,
                ),
              ],
            ),
            if (_categoryError != null) ...[
              const SizedBox(height: 8),
              Text(_categoryError!, style: t.caption.copyWith(color: c.over)),
            ],
            const SizedBox(height: 24),
            Text('Date', style: t.caption),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 20),
              label: Text(DateFormat('EEE, d MMM yyyy').format(_date)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 32),
            FilledButton(onPressed: _saving ? null : _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
