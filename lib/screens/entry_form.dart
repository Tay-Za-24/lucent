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
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    final now = DateTime.now();
    _kind = e?.kind ?? Kind.expense;
    _date = e?.date ?? DateTime(now.year, now.month, now.day);
    _categoryId = e?.categoryId;
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

  Future<void> _save() async {
    final s = StoreScope.read(context);
    final amount = parseAmount(_amount.text, s.decimals);
    if (amount == null) {
      setState(() => _error = 'Enter an amount greater than zero');
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = 'Choose a category');
      return;
    }
    await s.saveEntry(
      id: widget.entry?.id,
      kind: _kind,
      amount: amount,
      categoryId: _categoryId!,
      date: _date,
      note: _note.text,
    );
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
          TextButton(onPressed: _save, child: const Text('Save')),
          if (editing)
            IconButton(
                tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: _delete),
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
              onSelectionChanged: (v) => setState(() {
                _kind = v.first;
                _categoryId = null;
                _error = null;
              }),
            ),
            const SizedBox(height: 24),
            Text('Amount', style: t.caption),
            const SizedBox(height: 8),
            TextField(
              controller: _amount,
              autofocus: !editing,
              keyboardType: TextInputType.numberWithOptions(decimal: s.decimals > 0),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(s.decimals > 0 ? r'[0-9.,]' : r'[0-9,]')),
              ],
              style: t.displayAmount.copyWith(
                  color: _kind == Kind.income ? c.accent : c.textPrimary),
              decoration: InputDecoration(
                hintText: s.decimals > 0 ? '0.00' : '0',
                hintStyle: t.displayAmount.copyWith(color: c.textTertiary),
                prefixText: s.currency.isEmpty ? null : '${s.currency} ',
                prefixStyle: t.headlineAmount.copyWith(color: c.textSecondary),
              ),
              onChanged: (_) => setState(() => _error = null),
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
                      _error = null;
                    }),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('New'),
                  onPressed: () => showCategoryEditor(context, kind: _kind),
                ),
              ],
            ),
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
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: t.label.copyWith(color: c.over)),
            ],
            const SizedBox(height: 32),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
