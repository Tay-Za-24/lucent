import 'package:flutter/material.dart';

import '../data/models.dart';
import '../money.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Dialog to add a category, or rename / recolor / archive / delete one.
/// Expense categories also get an optional monthly limit, saved the same way
/// as on the Budgets screen (from the current month onwards).
Future<void> showCategoryEditor(BuildContext context,
    {Category? existing, Kind kind = Kind.expense}) {
  final s = StoreScope.read(context);
  final name = TextEditingController(text: existing?.name ?? '');
  var k = existing?.kind ?? kind;
  var color = existing?.color ?? (s.categories.length % 8);
  var archived = existing?.archived ?? false;
  final inUse = existing != null && s.usedCategoryIds.contains(existing.id);
  final oldLimit = existing == null ? null : s.limits[existing.id];
  final limit = TextEditingController(
    text: oldLimit == null ? '' : amountToInput(oldLimit, s.decimals),
  );
  String? error;
  String? limitError;

  return showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      final c = ctx.colors;
      final t = ctx.text;
      Future<void> save() async {
        final n = name.text.trim();
        if (n.isEmpty) {
          setState(() => error = 'Enter a name');
          return;
        }
        final dup = s.categories.any((x) =>
            x.kind == k && x.id != existing?.id && x.name.toLowerCase() == n.toLowerCase());
        if (dup) {
          setState(() => error = 'That name is already used');
          return;
        }
        // Empty = no limit. Anything else must be a valid amount.
        int? newLimit;
        if (k == Kind.expense && limit.text.trim().isNotEmpty) {
          newLimit = parseAmount(limit.text, s.decimals);
          if (newLimit == null) {
            setState(() => limitError = 'Enter an amount greater than zero, or leave it empty');
            return;
          }
        }
        final String id;
        if (existing == null) {
          id = (await s.addCategory(n, k, color)).id;
        } else {
          id = existing.id;
          existing
            ..name = n
            ..color = color
            ..archived = archived;
          await s.updateCategory(existing);
        }
        if (k == Kind.expense && newLimit != oldLimit) {
          await s.setLimit(id, newLimit);
        }
        if (ctx.mounted) Navigator.pop(ctx);
      }

      return AlertDialog(
        title: Text(existing == null ? 'New category' : 'Edit category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (existing == null) ...[
                SegmentedButton<Kind>(
                  segments: const [
                    ButtonSegment(value: Kind.expense, label: Text('Expense')),
                    ButtonSegment(value: Kind.income, label: Text('Income')),
                  ],
                  selected: {k},
                  onSelectionChanged: (v) => setState(() => k = v.first),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: 'Name', errorText: error),
                onSubmitted: (_) => save(),
              ),
              if (k == Kind.expense) ...[
                const SizedBox(height: 16),
                TextField(
                  key: const Key('category-limit'),
                  controller: limit,
                  keyboardType: TextInputType.numberWithOptions(decimal: s.decimals > 0),
                  inputFormatters: [AmountInputFormatter(s.decimals)],
                  style: t.bodyAmount,
                  decoration: InputDecoration(
                    labelText: 'Monthly limit (optional)',
                    hintText: 'No limit',
                    prefixText: s.currency.isEmpty ? null : '${s.currency} ',
                    helperText: 'From this month on. Leave empty for no limit.',
                    errorText: limitError,
                  ),
                  onChanged: (_) {
                    if (limitError != null) setState(() => limitError = null);
                  },
                  onSubmitted: (_) => save(),
                ),
              ],
              const SizedBox(height: 16),
              Text('Color', style: t.caption),
              const SizedBox(height: 8),
              Wrap(
                children: [
                  for (var i = 0; i < 8; i++)
                    InkResponse(
                      onTap: () => setState(() => color = i),
                      radius: 24,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: c.category(i),
                              shape: BoxShape.circle,
                              border: color == i
                                  ? Border.all(color: c.textPrimary, width: 2)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (existing != null) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Archived'),
                  subtitle: const Text('Hidden when adding entries'),
                  value: archived,
                  onChanged: (v) => setState(() => archived = v),
                ),
                if (inUse)
                  Text('Used by entries, so it can\u2019t be deleted. Archive it instead.',
                      style: t.caption),
              ],
            ],
          ),
        ),
        actions: [
          if (existing != null && !inUse)
            TextButton(
              onPressed: () async {
                await s.deleteCategory(existing);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text('Delete', style: TextStyle(color: c.over)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: save, child: const Text('Save')),
        ],
      );
    }),
  );
}
