import 'package:flutter/material.dart';

import '../data/goal.dart';
import '../money.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Dialog to set, change or remove the monthly savings goal.
Future<void> showGoalEditor(BuildContext context) {
  final s = StoreScope.read(context);
  final existing = s.goal;
  var kind = existing?.kind ?? GoalKind.amount;
  final ctl = TextEditingController(
    text: existing == null
        ? ''
        : existing.kind == GoalKind.amount
        ? amountToInput(existing.value, s.decimals)
        : '${existing.value}',
  );
  String? error;

  return showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final t = ctx.text;
        Future<void> save() async {
          final int? v;
          if (kind == GoalKind.amount) {
            v = parseAmount(ctl.text, s.decimals);
            if (v == null) return setState(() => error = 'Enter an amount');
          } else {
            v = int.tryParse(normalizeDigits(ctl.text).trim());
            if (v == null || v < 1 || v > 100) {
              return setState(() => error = 'Enter a percentage from 1 to 100');
            }
          }
          await s.setGoal(SavingsGoal(kind, v));
          if (ctx.mounted) Navigator.pop(ctx);
        }

        return AlertDialog(
          title: const Text('Savings goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How much you want to keep each month. Saved means money in minus money out.',
                  style: t.caption,
                ),
                const SizedBox(height: 16),
                SegmentedButton<GoalKind>(
                  segments: const [
                    ButtonSegment(
                      value: GoalKind.amount,
                      label: Text('Amount'),
                    ),
                    ButtonSegment(
                      value: GoalKind.percent,
                      label: Text('% of income'),
                    ),
                  ],
                  selected: {kind},
                  onSelectionChanged: (v) => setState(() {
                    kind = v.first;
                    ctl.clear();
                    error = null;
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('goal-value'),
                  controller: ctl,
                  autofocus: true,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: kind == GoalKind.amount && s.decimals > 0,
                  ),
                  inputFormatters: [
                    AmountInputFormatter(
                      kind == GoalKind.amount ? s.decimals : 0,
                    ),
                  ],
                  style: t.bodyAmount,
                  decoration: InputDecoration(
                    labelText: kind == GoalKind.amount
                        ? 'Amount per month'
                        : 'Share of income',
                    prefixText: kind == GoalKind.amount && s.currency.isNotEmpty
                        ? '${s.currency} '
                        : null,
                    suffixText: kind == GoalKind.percent ? '%' : null,
                    errorText: error,
                  ),
                  onSubmitted: (_) => save(),
                ),
                const SizedBox(height: 8),
                Text(
                  kind == GoalKind.amount
                      ? 'e.g. 200,000 a month.'
                      : 'Worked out from this month\u2019s total income.',
                  style: t.caption,
                ),
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () async {
                  await s.setGoal(null);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Remove'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(onPressed: save, child: const Text('Save')),
          ],
        );
      },
    ),
  );
}
