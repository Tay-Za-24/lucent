import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/store.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding.dart';
import 'theme.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The Inter font licence (SIL OFL) must travel with the font.
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/LICENSE.txt');
    yield LicenseEntryWithLineBreaks(['Inter font'], text);
  });
  final store = await AppStore.open();
  runApp(LucentApp(store: store));
}

/// Widest the app content gets on a large window.
const maxContentWidth = 560.0;

class LucentApp extends StatelessWidget {
  const LucentApp({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => MaterialApp(
          title: 'Lucent',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: store.themeMode,
          // On a wide window (desktop, tablet) keep content phone-width and centred.
          builder: (context, child) => ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                child: child,
              ),
            ),
          ),
          home: store.onboarded ? const HomeShell() : const OnboardingScreen(),
        ),
      ),
    );
  }
}
