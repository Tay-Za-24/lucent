import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucent/screens/licenses.dart';
import 'package:lucent/version.dart';

import 'helpers.dart';

void main() {
  test('licence types are recognised', () {
    expect(
      licenseType(
        'Permission is hereby granted, free of charge, to any person',
      ),
      'MIT',
    );
    expect(licenseType('Apache License\nVersion 2.0'), 'Apache-2.0');
    expect(
      licenseType(
        'Redistribution and use in source and binary forms ... Neither the name',
      ),
      'BSD-3',
    );
    expect(
      licenseType('Redistribution and use in source and binary forms, with'),
      'BSD-2',
    );
  });

  test('appVersion matches pubspec.yaml', () {
    final v = RegExp(
      r'^version: (\S+)\+',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1);
    expect(appVersion, v);
  });

  testWidgets('short licence screen: one line per package, SDK grouped', (
    tester,
  ) async {
    LicenseRegistry.reset();
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks([
        'sqflite',
      ], 'Redistribution and use in source and binary forms');
      yield const LicenseEntryWithLineBreaks([
        'sqflite_android',
      ], 'Redistribution and use in source and binary forms');
      yield const LicenseEntryWithLineBreaks([
        'uuid',
      ], 'Permission is hereby granted, free of charge');
      yield const LicenseEntryWithLineBreaks(['skia'], 'Neither the name');
      yield const LicenseEntryWithLineBreaks(['boringssl'], 'Apache License');
    });
    addTearDown(LicenseRegistry.reset);
    await openApp(tester);
    await onboard(tester);
    await tapAndSettle(tester, nav('Settings'));
    await tester.scrollUntilVisible(find.text('Licenses'), 200);
    await tapAndSettle(tester, find.text('Licenses'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Flutter & Dart SDK'), findsOneWidget);
    expect(find.text('Framework, engine and bundled parts'), findsOneWidget);
    expect(find.text('sqflite'), findsOneWidget); // sqflite_android folded in
    expect(find.text('BSD-2'), findsOneWidget);
    expect(find.text('uuid'), findsOneWidget);
    expect(find.text('skia'), findsNothing);
    await tapAndSettle(tester, find.text('uuid'));
    expect(find.textContaining('Permission is hereby granted'), findsOneWidget);
    expect(find.text('Full license texts'), findsOneWidget);
  });
}
