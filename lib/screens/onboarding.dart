import 'package:flutter/material.dart';

import '../data/models.dart';
import '../money.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'settings.dart';

/// First run: welcome -> currency & decimals -> create categories.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  late final TextEditingController _currency =
      TextEditingController(text: StoreScope.read(context).currency);

  @override
  void dispose() {
    _currency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final t = context.text;
    final c = context.colors;
    Widget body;
    Widget button;
    switch (_step) {
      case 0:
        body = ListView(
          padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Image.asset('assets/brand/logo.png', width: 64, height: 64),
            ),
            const SizedBox(height: 24),
            Text('Lucent', style: t.displayAmount),
            const SizedBox(height: 16),
            Text('A calm, simple way to track what comes in and what goes out each month.',
                style: t.body.copyWith(color: c.textSecondary)),
            const SizedBox(height: 16),
            Text('Everything stays on this phone. No account, no internet.',
                style: t.body.copyWith(color: c.textSecondary)),
          ],
        );
        button = FilledButton(
            onPressed: () => setState(() => _step = 1), child: const Text('Get started'));
      case 1:
        body = ListView(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          children: [
            Text('Your currency', style: t.title),
            const SizedBox(height: 8),
            Text('Type the symbol you want to see next to amounts.', style: t.caption),
            const SizedBox(height: 24),
            TextField(
              controller: _currency,
              maxLength: 5,
              decoration: const InputDecoration(labelText: 'Currency symbol', hintText: 'e.g. K, \$'),
              onChanged: (v) => s.setCurrency(v),
            ),
            const SizedBox(height: 24),
            Text('Decimal places', style: t.label),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('0  (1,000)')),
                ButtonSegment(value: 2, label: Text('2  (1,000.00)')),
              ],
              selected: {s.decimals},
              onSelectionChanged: (v) => s.setDecimals(v.first, convert: false),
            ),
            const SizedBox(height: 32),
            Text('Preview', style: t.caption),
            const SizedBox(height: 4),
            Text(formatMoney(s.decimals == 0 ? 12500 : 1250000, s.currency, s.decimals),
                style: t.headlineAmount),
          ],
        );
        button = FilledButton(
            onPressed: () => setState(() => _step = 2), child: const Text('Continue'));
      default:
        final hasExpense = s.categories.any((x) => x.kind == Kind.expense);
        final hasIncome = s.categories.any((x) => x.kind == Kind.income);
        body = ListView(
          padding: const EdgeInsets.only(top: 32),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Your categories', style: t.title),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                  'Create the categories you use. You need at least one expense and one income category. '
                  'You can change them later in Settings.',
                  style: t.caption),
            ),
            const CategoryList(shrinkWrap: true),
          ],
        );
        button = FilledButton(
          onPressed: hasExpense && hasIncome ? s.finishOnboarding : null,
          child: Text(hasExpense && hasIncome
              ? 'Start using Lucent'
              : 'Add ${!hasExpense ? 'an expense' : 'an income'} category'),
        );
    }
    return Scaffold(
      appBar: _step > 0
          ? AppBar(
              leading: IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step--),
              ),
            )
          : null,
      body: SafeArea(child: MaxWidth(child: body)),
      bottomNavigationBar: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16), child: button),
      ),
    );
  }
}
