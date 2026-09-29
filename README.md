# Lucent

A minimal, private budget tracker for Android. Everything you enter stays on your phone; the app never uses the internet (the release app doesn't even ask for internet permission).

## What the app does (version 0.1.0)

- **First-run setup:** a welcome screen, then you pick your currency symbol (anything you like, e.g. `K` or `$`) and whether amounts use 0 or 2 decimal places. Then you create your own categories. Nothing is pre-filled; you need at least one expense and one income category to start.
- **Entries:** add, edit or delete an expense or income: amount, category, date (today unless you change it) and an optional note.
- **Entries tab:** every entry for the chosen month, grouped by day, newest first. Arrows at the top switch months.
- **Budgets tab:** give any expense category a monthly limit (optional). You see what's been spent, what's left, or how much you're over. Each month starts fresh on the 1st; unspent money doesn't roll over. A limit you set applies to that month and later months until you change it, and past months keep their own limits, so you can look back.
- **Home tab:** the month's Net (money in minus money out) in large type, the In and Out totals, and a progress bar for each budget.
- **Settings:** change the currency symbol or decimal places, manage categories (add, rename, change color, archive; a category can only be deleted if no entry uses it), pick the theme (follow phone, light or dark), and view the licences.

## What's in this folder

| Path | What it is |
|---|---|
| `README.md` | This file. |
| `docs/SUMMARY.md` | A one-page plain-language description of the full Lucent idea. |
| `docs/SPEC.md` | The detailed spec for a bigger, future multi-platform version. This app follows its design guide (§5); most of the rest isn't built. |
| `pubspec.yaml` | The app's "shopping list": its name, version, the add-on libraries it uses, and the font files it bundles. |
| `pubspec.lock` | Exact versions of those libraries, so every build is the same. Generated automatically. |
| `analysis_options.yaml` | Rules for the code checker (`flutter analyze`). |
| `.gitignore` | Tells git which files never to save online (build output, signing keys, passwords). |
| `.metadata` | Bookkeeping file Flutter creates. Leave it alone. |
| `assets/fonts/` | The Inter typeface files (official v4.1 release) and their licence. They're packed inside the app, so nothing is downloaded. |
| `lib/` | **The app itself** (all the Dart code). |
| `lib/main.dart` | Starting point: opens the database, registers the font licence, picks light/dark theme, and shows setup or the main screens. |
| `lib/theme.dart` | The look: colors for light and dark mode, and the text sizes/weights (large amount, title, body, caption). All amounts use equal-width digits so they line up. |
| `lib/money.dart` | Turns typed amounts into whole numbers (e.g. 12.50 is stored as 1250) and formats them for display ("K 1,250"). |
| `lib/data/models.dart` | Describes a category and an entry. |
| `lib/data/db.dart` | Creates the on-phone database (SQLite) and its tables: settings, categories, entries, budgets. |
| `lib/data/store.dart` | The app's memory and bookkeeper: loads and saves everything, and works out totals (In, Out, Net, spent per category). Totals are always calculated, never stored. |
| `lib/widgets/common.dart` | Small reusable building blocks: amount text, month switcher, budget bar, category color dot, dividers. |
| `lib/screens/` | One file per screen: `onboarding.dart` (first-run setup), `home_shell.dart` (bottom tabs), `home.dart`, `transactions.dart` (Entries tab), `entry_form.dart` (add/edit entry), `budgets.dart`, `settings.dart` (also the categories list), `category_editor.dart` (the add/edit category box). |
| `test/` | Automatic checks for amount parsing and formatting. Run with `flutter test`. |
| `android/` | The Android "wrapper" that turns the code into a phone app: app ID `app.lucent.budget`, name "Lucent", launcher icon (a plain "L"), and release signing setup. |
| `android/app/src/release/AndroidManifest.xml` | Makes sure the release app has no internet permission. |
| `build/` | Created when you build. Not saved in git. |

## How to build the installable APK

You need Flutter (stable), Java 17 and the Android SDK. On the build machine these live in `/home/box/sdk`; run `source /home/box/sdk/env.sh` first to make them available.

1. **Signing key (one time).** Android apps must be signed. The key is kept *outside* this folder, in `/home/box/lucent-keys/` (its password is in `README.txt` there). Create a file `android/key.properties` containing:
   ```
   storePassword=<password>
   keyPassword=<password>
   keyAlias=lucent
   storeFile=/home/box/lucent-keys/lucent-release.jks
   ```
   This file is ignored by git, so the password is never uploaded. Without it, the build still works but is signed with a throwaway debug key (fine for testing, not for sharing updates).
2. **Build:** in this folder run
   ```
   flutter pub get
   flutter build apk --release
   ```
3. **Result:** `build/app/outputs/flutter-apk/app-release.apk`. It works on any modern Android phone (one "universal" file). Copy it to the phone and open it to install (you may need to allow "install unknown apps").

Keep the signing key and its password safe: updates must be signed with the same key, or the phone will refuse to install them over the old version.

## Checks

- `flutter analyze` checks the code for mistakes.
- `flutter test` runs the automatic checks.
