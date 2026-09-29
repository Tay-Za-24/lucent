import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'entry_form.dart';

/// All entries of the selected month, grouped by day (newest first).
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final t = context.text;
    final groups = <DateTime, List<Entry>>{};
    for (final e in s.monthEntries) {
      groups.putIfAbsent(e.date, () => []).add(e);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: MonthSwitcher(),
        ),
        if (days.isEmpty) const EmptyState('No entries this month.\nTap + to add one.'),
        for (final day in days) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              children: [
                Expanded(child: Text(DateFormat('EEE, d MMM').format(day), style: t.caption)),
                MoneyText(
                  groups[day]!.fold<int>(0, (a, e) => a + (e.kind == Kind.income ? e.amount : -e.amount)),
                  style: t.caption,
                  plus: true,
                ),
              ],
            ),
          ),
          const Hairline(indent: 0),
          for (final e in groups[day]!) ...[
            _EntryRow(e),
            const Hairline(),
          ],
        ],
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow(this.e);
  final Entry e;

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final t = context.text;
    final c = context.colors;
    final cat = s.categoryById(e.categoryId);
    final income = e.kind == Kind.income;
    return InkWell(
      onTap: () => openEntryForm(context, entry: e),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CategoryDot(cat),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat?.name ?? 'Unknown', style: t.body),
                    if (e.note != null)
                      Text(e.note!, style: t.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              MoneyText(e.amount,
                  style: t.bodyAmount, plus: income, color: income ? c.accent : null),
            ],
          ),
        ),
      ),
    );
  }
}
