import 'package:flutter/material.dart';

import '../widgets/common.dart';
import 'budgets.dart';
import 'entry_form.dart';
import 'home.dart';
import 'settings.dart';
import 'transactions.dart';

/// Bottom navigation with the four main tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [HomeScreen(), TransactionsScreen(), BudgetsScreen(), SettingsScreen()];
    return Scaffold(
      body: SafeArea(child: MaxWidth(child: IndexedStack(index: _tab, children: pages))),
      floatingActionButton: _tab <= 1
          ? FloatingActionButton(
              tooltip: 'Add entry',
              onPressed: () => openEntryForm(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerTheme.color!, width: 0)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: 'Entries'),
            NavigationDestination(icon: Icon(Icons.donut_large_outlined), label: 'Budgets'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
