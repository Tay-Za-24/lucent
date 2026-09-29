import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'goal_editor.dart';

/// Month overview: Net (large), In and Out, then budget progress.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final t = context.text;
    final c = context.colors;
    final lines = s.budgetLines().where((l) => l.limit != null).toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        const MonthTitle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text('Net', style: t.caption),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.6,
              child: MoneyText(s.net, style: t.displayAmount),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _Figure(label: 'In', child: MoneyText(s.totalIn, style: t.bodyAmount, plus: s.totalIn > 0, color: c.accent)),
              ),
              Expanded(
                child: _Figure(label: 'Out', child: MoneyText(s.totalOut, style: t.bodyAmount)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Hairline(indent: 0),
        const SectionTitle('Savings goal'),
        if (s.goalProgress case final p?)
          GoalRow(progress: p, onTap: () => showGoalEditor(context))
        else
          ListTile(
            title: Text('No savings goal yet', style: t.body.copyWith(color: c.textSecondary)),
            subtitle: const Text('A fixed amount or a share of income each month.'),
            trailing: TextButton(onPressed: () => showGoalEditor(context), child: const Text('Set goal')),
          ),
        const SizedBox(height: 8),
        const Hairline(indent: 0),
        const SectionTitle('Budgets'),
        if (lines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('No budgets set for this month. Add limits in the Budgets tab.',
                style: t.body.copyWith(color: c.textSecondary)),
          )
        else
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const Hairline(),
            BudgetRow(line: lines[i]),
          ],
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.child});
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
