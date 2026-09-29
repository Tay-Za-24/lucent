import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'transactions.dart';

/// Past months (most recent first) with In, Out and Net.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<MonthSummary>? _months;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs on first build and whenever the store changes.
    StoreScope.of(context).pastMonths().then((m) {
      if (mounted) setState(() => _months = m);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final months = _months;
    return ListView(
      padding: const EdgeInsets.only(bottom: 48),
      children: [
        const SectionTitle('History'),
        if (months != null && months.isEmpty)
          const EmptyState('Past months will appear here once a month ends.'),
        for (final m in months ?? const <MonthSummary>[]) ...[
          const Hairline(indent: 0),
          InkWell(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => MonthDetailScreen(month: m.month))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('MMMM yyyy').format(m.month), style: t.body),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 16,
                          children: [
                            _Mini('In', m.totalIn, accent: true),
                            _Mini('Out', m.totalOut),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MoneyText(m.net, style: t.bodyAmount, plus: m.net > 0),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ],
        if (months != null && months.isNotEmpty) const Hairline(indent: 0),
      ],
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.label, this.amount, {this.accent = false});
  final String label;
  final int amount;
  final bool accent;
  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: t.caption),
        MoneyText(
          amount,
          style: t.caption.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          plus: accent && amount > 0,
          color: accent ? context.colors.accent : null,
        ),
      ],
    );
  }
}

/// Read-only view of one past month: totals, budget results, entries by day.
class MonthDetailScreen extends StatefulWidget {
  const MonthDetailScreen({super.key, required this.month});
  final DateTime month;
  @override
  State<MonthDetailScreen> createState() => _MonthDetailScreenState();
}

class _MonthDetailScreenState extends State<MonthDetailScreen> {
  MonthData? _data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    StoreScope.of(context).monthData(widget.month).then((d) {
      if (mounted) setState(() => _data = d);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final t = context.text;
    final c = context.colors;
    final d = _data;
    final lines = d == null
        ? const <BudgetLine>[]
        : d.budgetLines(s.categories).where((l) => l.limit != null || l.spent > 0).toList();
    return Scaffold(
      appBar: AppBar(title: Text(DateFormat('MMMM yyyy').format(widget.month))),
      body: d == null
          ? const SizedBox.shrink()
          : MaxWidth(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 48),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text('Net', style: t.caption),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: MoneyText(d.net, style: t.headlineAmount),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Figure(
                            'In',
                            MoneyText(
                              d.totalIn,
                              style: t.bodyAmount,
                              plus: d.totalIn > 0,
                              color: c.accent,
                            ),
                          ),
                        ),
                        Expanded(child: _Figure('Out', MoneyText(d.totalOut, style: t.bodyAmount))),
                      ],
                    ),
                  ),
                  if (d.goalProgress case final p?) ...[
                    const SectionTitle('Savings goal'),
                    GoalRow(progress: p),
                  ],
                  const SectionTitle('Budgets'),
                  if (lines.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('No budgets or spending this month.', style: t.caption),
                    ),
                  for (var i = 0; i < lines.length; i++) ...[
                    const Hairline(indent: 0),
                    BudgetRow(line: lines[i]),
                  ],
                  if (lines.isNotEmpty) const Hairline(indent: 0),
                  const SectionTitle('Entries'),
                  if (d.entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('No entries this month.', style: t.caption),
                    ),
                  ...entryDayGroups(context, d.entries, readOnly: true),
                ],
              ),
            ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.child);
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: context.text.caption),
      const SizedBox(height: 4),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: child),
    ],
  );
}
