import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../version.dart';
import '../widgets/common.dart';

/// Open-source packages the app ships (from `flutter pub deps --no-dev`),
/// shown one line each. Everything else Flutter registers (the framework,
/// engine and the libraries bundled with it) is grouped into one SDK line.
const _pubPackages = {
  'sqflite',
  'sqflite_android',
  'sqflite_common',
  'sqflite_darwin',
  'sqflite_platform_interface',
  'path',
  'uuid',
  'intl',
  'characters',
  'clock',
  'collection',
  'crypto',
  'fixnum',
  'material_color_utilities',
  'meta',
  'platform',
  'plugin_platform_interface',
  'synchronized',
  'typed_data',
  'vector_math',
  'Inter font',
};

/// Short licence name worked out from the licence text.
String licenseType(String text) {
  final t = text.toLowerCase();
  if (t.contains('apache license')) return 'Apache-2.0';
  if (t.contains('sil open font license')) return 'OFL-1.1';
  if (t.contains('permission is hereby granted, free of charge')) return 'MIT';
  if (t.contains('redistribution and use in source and binary forms')) {
    return t.contains('neither the name') ||
            t.contains('names of its contributors')
        ? 'BSD-3'
        : 'BSD-2';
  }
  if (t.contains('mozilla public license')) return 'MPL-2.0';
  return 'Other';
}

/// One line on the screen: a package (or a family, e.g. sqflite and its
/// platform parts) with its licence texts.
class LicenseGroup {
  LicenseGroup(this.name);
  final String name;
  final List<String> texts = [];
  Set<String> get types => {for (final t in texts) licenseType(t)};
}

/// Groups registered licences: sqflite_* under sqflite, non-pub entries under the SDK.
Future<(List<LicenseGroup>, int)> loadLicenseGroups() async {
  final groups = <String, LicenseGroup>{};
  var sdkCount = 0;
  await for (final entry in LicenseRegistry.licenses) {
    final text = entry.paragraphs
        .map((p) => '${'  ' * p.indent.clamp(0, 8)}${p.text}')
        .join('\n\n');
    var counted = false;
    for (final pkg in entry.packages) {
      if (_pubPackages.contains(pkg)) {
        final name = pkg.startsWith('sqflite') ? 'sqflite' : pkg;
        final g = groups.putIfAbsent(name, () => LicenseGroup(name));
        if (!g.texts.contains(text)) g.texts.add(text);
      } else if (!counted) {
        sdkCount++;
        counted = true;
      }
    }
  }
  final list = groups.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return (list, sdkCount);
}

/// Short licence screen: the app's own licence, then one line per package.
/// Full texts stay reachable (tap a line, or "Full license texts").
class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});
  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  late final Future<(List<LicenseGroup>, int)> _groups = loadLicenseGroups();

  void _fullTexts() => showLicensePage(
    context: context,
    applicationName: 'Lucent',
    applicationVersion: appVersion,
    applicationIcon: Padding(
      padding: const EdgeInsets.all(8),
      child: Image.asset('assets/brand/logo.png', width: 48, height: 48),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Licenses')),
      body: MaxWidth(
        child: FutureBuilder(
          future: _groups,
          builder: (context, snap) {
            final (groups, sdkCount) = snap.data ?? (const <LicenseGroup>[], 0);
            return ListView(
              padding: const EdgeInsets.only(bottom: 48),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/brand/logo.png',
                        width: 48,
                        height: 48,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lucent $appVersion', style: t.title),
                            const SizedBox(height: 2),
                            Text(
                              '\u00a9 2026 Tay Za. All rights reserved.',
                              style: t.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionTitle('Open-source software'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Lucent is built with these packages. Tap one to read its licence.',
                    style: t.caption,
                  ),
                ),
                if (!snap.hasData)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (snap.hasData) ...[
                  const Hairline(indent: 0),
                  _Line(
                    name: 'Flutter & Dart SDK',
                    type: 'BSD-3 and others',
                    subtitle: sdkCount > 0
                        ? 'Framework, engine and bundled parts'
                        : null,
                    onTap: _fullTexts,
                  ),
                  for (final g in groups) ...[
                    const Hairline(indent: 0),
                    _ExpandableLine(group: g),
                  ],
                  const Hairline(indent: 0),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _fullTexts,
                      child: const Text('Full license texts'),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Every licence in full, as supplied by each package.',
                    style: t.caption.copyWith(color: c.textTertiary),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.name,
    required this.type,
    this.subtitle,
    this.onTap,
    this.trailing,
  });
  final String name;
  final String type;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: t.body),
                  if (subtitle != null) Text(subtitle!, style: t.caption),
                ],
              ),
            ),
            Text(type, style: t.caption),
            const SizedBox(width: 4),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: context.colors.textTertiary,
                ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableLine extends StatefulWidget {
  const _ExpandableLine({required this.group});
  final LicenseGroup group;
  @override
  State<_ExpandableLine> createState() => _ExpandableLineState();
}

class _ExpandableLineState extends State<_ExpandableLine> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Line(
          name: g.name,
          type: g.types.join(', '),
          onTap: () => setState(() => _open = !_open),
          trailing: Icon(
            _open ? Icons.expand_less : Icons.expand_more,
            size: 20,
            color: c.textTertiary,
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SelectableText(
              g.texts.join('\n\n\u2014\n\n'),
              style: context.text.caption.copyWith(color: c.textSecondary),
            ),
          ),
      ],
    );
  }
}
