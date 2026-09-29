import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Dialog to add a category, or rename / recolor / archive / delete one.
Future<void> showCategoryEditor(BuildContext context,
    {Category? existing, Kind kind = Kind.expense}) {
  final s = StoreScope.read(context);
  final name = TextEditingController(text: existing?.name ?? '');
  var k = existing?.kind ?? kind;
  var color = existing?.color ?? (s.categories.length % 8);
  var archived = existing?.archived ?? false;
  final inUse = existing != null && s.usedCategoryIds.contains(existing.id);
  String? error;

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
        if (existing == null) {
          await s.addCategory(n, k, color);
        } else {
          existing
            ..name = n
            ..color = color
            ..archived = archived;
          await s.updateCategory(existing);
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
