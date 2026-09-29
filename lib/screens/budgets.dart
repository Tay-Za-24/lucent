import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/store.dart';
import '../money.dart';
import '../theme.dart';
import '../widgets/budget_ring.dart';
import '../widgets/common.dart';

/// Monthly limits per expense category: spent vs limit and what's left.
class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final t = context.text;
    final lines = s.budgetLines();
    final withLimit = lines.where((l) => l.limit != null);
    final totalLimit = withLimit.fold<int>(0, (a, l) => a + l.limit!);
    final totalSpent = withLimit.fold<int>(0, (a, l) => a + l.spent);
    final ring = s.budgetDisplay == BudgetDisplay.ring;
    return ListView(
      padding: const EdgeInsets.only(bottom: 48),
      children: [
        const MonthTitle(),
        if (ring) BudgetRing(lines: lines, totalLimit: totalLimit),
        if (!ring && withLimit.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              totalLimit - totalSpent >= 0 ? 'Left this month' : 'Over budget',
              style: t.caption,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: MoneyText((totalLimit - totalSpent).abs(), style: t.headlineAmount),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              '${formatMoney(totalSpent, s.currency, s.decimals)} of '
              '${formatMoney(totalLimit, s.currency, s.decimals)} spent',
              style: t.caption,
            ),
          ),
        ],
        const SectionTitle('Expense categories'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('Tap a category to set its monthly limit.', style: t.caption),
        ),
        if (lines.isEmpty) const EmptyState('No expense categories yet. Add one in Settings.'),
        for (var i = 0; i < lines.length; i++) ...[
          const Hairline(indent: 0),
          BudgetRow(
            line: lines[i],
            showBar: !ring,
            onTap: () => _editLimit(context, lines[i]),
          ),
        ],
        if (lines.isNotEmpty) const Hairline(indent: 0),
      ],
    );
  }

  Future<void> _editLimit(BuildContext context, BudgetLine line) async {
    final s = StoreScope.read(context);
    final ctl = TextEditingController(
      text: line.limit == null ? '' : amountToInput(line.limit!, s.decimals),
    );
    String? error;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> save() async {
            final v = parseAmount(ctl.text, s.decimals);
            if (v == null) {
              setState(() => error = 'Enter an amount greater than zero');
              return;
            }
            await s.setLimit(line.category.id, v);
            if (ctx.mounted) Navigator.pop(ctx);
          }

          return AlertDialog(
            title: Text('${line.category.name} limit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctl,
                  autofocus: true,
                  keyboardType: TextInputType.numberWithOptions(decimal: s.decimals > 0),
                  inputFormatters: [AmountInputFormatter(s.decimals)],
                  style: ctx.text.bodyAmount,
                  decoration: InputDecoration(
                    labelText: 'Monthly limit',
                    prefixText: s.currency.isEmpty ? null : '${s.currency} ',
                    errorText: error,
                  ),
                  onSubmitted: (_) => save(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Applies to ${DateFormat('MMMM yyyy').format(s.month)} and later months. '
                  'Each month starts fresh on the 1st.',
                  style: ctx.text.caption,
                ),
              ],
            ),
            actions: [
              if (line.limit != null)
                TextButton(
                  onPressed: () async {
                    await s.setLimit(line.category.id, null);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Remove'),
                ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              TextButton(onPressed: save, child: const Text('Save')),
            ],
          );
        },
      ),
    );
  }
}
