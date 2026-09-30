import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/store.dart';
import '../money.dart';
import '../theme.dart';
import '../version.dart';
import '../widgets/common.dart';
import 'category_editor.dart';
import 'goal_editor.dart';
import 'licenses.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final t = context.text;
    return ListView(
      padding: const EdgeInsets.only(bottom: 48),
      children: [
        const SectionTitle('Settings'),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('Currency symbol'),
          trailing: Text(s.currency.isEmpty ? 'None' : s.currency, style: t.bodyAmount),
          onTap: () => editCurrency(context),
        ),
        const Hairline(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(child: Text('Decimal places', style: t.body)),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('0')),
                  ButtonSegment(value: 2, label: Text('2')),
                ],
                selected: {s.decimals},
                onSelectionChanged: (v) => _changeDecimals(context, v.first),
              ),
            ],
          ),
        ),
        const Hairline(),
        ListTile(
          title: const Text('Categories'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const CategoriesScreen())),
        ),
        const Hairline(),
        ListTile(
          title: const Text('Savings goal'),
          trailing: Text(
            s.goal == null ? 'Off' : goalLabel(s.goal!, s.currency, s.decimals),
            style: t.bodyAmount,
          ),
          onTap: () => showGoalEditor(context),
        ),
        const SectionTitle('Appearance'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {s.themeMode},
            onSelectionChanged: (v) => s.setThemeMode(v.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Budget display', style: t.label),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SegmentedButton<BudgetDisplay>(
            segments: const [
              ButtonSegment(value: BudgetDisplay.bars, label: Text('Progress bars')),
              ButtonSegment(value: BudgetDisplay.ring, label: Text('Ring chart')),
            ],
            selected: {s.budgetDisplay},
            onSelectionChanged: (v) => s.setBudgetDisplay(v.first),
          ),
        ),
        const SectionTitle('About'),
        ListTile(
          title: const Text('Licenses'),
          subtitle: const Text('Lucent $appVersion \u00b7 works fully offline'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const LicensesScreen())),
        ),
      ],
    );
  }

  Future<void> _changeDecimals(BuildContext context, int d) async {
    final s = StoreScope.read(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Use $d decimal places?'),
        content: Text(d == 0
            ? 'Existing amounts will be rounded to whole numbers.'
            : 'Existing amounts keep their value (1,000 becomes 1,000.00).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Change')),
        ],
      ),
    );
    if (ok == true) await s.setDecimals(d);
  }
}

Future<void> editCurrency(BuildContext context) async {
  final s = StoreScope.read(context);
  final ctl = TextEditingController(text: s.currency);
  final v = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Currency symbol'),
      content: TextField(
        controller: ctl,
        autofocus: true,
        maxLength: 5,
        decoration: const InputDecoration(hintText: 'e.g. K, \$, \u20ac'),
        onSubmitted: (x) => Navigator.pop(ctx, x),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, ctl.text), child: const Text('Save')),
      ],
    ),
  );
  if (v != null) await s.setCurrency(v);
}

/// Add, rename, recolor, archive (and delete unused) categories.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add category',
        onPressed: () => showCategoryEditor(context),
        child: const Icon(Icons.add),
      ),
      body: const MaxWidth(child: CategoryList()),
    );
  }
}

/// Categories grouped into Expense and Income sections.
class CategoryList extends StatelessWidget {
  const CategoryList({super.key, this.shrinkWrap = false});
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final t = context.text;
    List<Widget> section(Kind k, String title) {
      final list = s.categories.where((c) => c.kind == k).toList();
      return [
        SectionTitle(title,
            trailing: TextButton.icon(
              onPressed: () => showCategoryEditor(context, kind: k),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            )),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('None yet', style: t.caption),
          ),
        for (final c in list) ...[
          ListTile(
            leading: CategoryDot(c, size: 12),
            minLeadingWidth: 16,
            title: Text(c.name,
                style: c.archived ? t.body.copyWith(color: context.colors.textSecondary) : null),
            subtitle: c.archived
                ? const Text('Archived')
                : s.limits[c.id] == null
                    ? null
                    : Text('Limit ${formatMoney(s.limits[c.id]!, s.currency, s.decimals)} a month'),
            trailing: const Icon(Icons.edit_outlined, size: 20),
            onTap: () => showCategoryEditor(context, existing: c),
          ),
          const Hairline(),
        ],
      ];
    }

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        ...section(Kind.expense, 'Expense'),
        ...section(Kind.income, 'Income'),
      ],
    );
  }
}
