import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('Settings -> Send to another device -> Send checks the address', (tester) async {
    await openApp(tester);
    await onboard(tester);
    await tapAndSettle(tester, nav('Settings'));
    await tester.scrollUntilVisible(find.text('Send to another device'), 100);
    await tester.ensureVisible(find.text('Send to another device'));
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Send to another device'));
    expect(find.text('Receive'), findsOneWidget);
    await tapAndSettle(tester, find.text('Send'));
    await tester.enterText(find.byType(TextField).first, '192.168.1.20');
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Send'));
    expect(find.textContaining('Enter the address exactly'), findsOneWidget);
  });
}
