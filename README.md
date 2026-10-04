# Lucent

A minimal, private budget tracker for Android. Everything you enter stays on your phone; the app never uses the internet (the release app doesn't even ask for internet permission).

## What the app does (version 0.4.0)

**New in 0.4.0:** a new logo and app icon (the original silver crystal artwork on a pale background), and you can set a category's monthly limit right when you create or edit it.


- **First-run setup:** a welcome screen, then you pick your currency symbol (anything you like, e.g. `K` or `$`) and whether amounts use 0 or 2 decimal places. Then you create your own categories (for an expense category you can type a monthly limit straight away, or leave it empty). Nothing is pre-filled; you need at least one expense and one income category to start.
- **Entries:** add, edit or delete an expense or income: amount, category, date (today unless you change it; it can't be later than this month) and an optional note. If something is missing (no amount or no category), a message says what to fix instead of nothing happening.
- **Always this month:** Home, Entries and Budgets only ever show the current month, with its name at the top. There's no switching between months; when a new month begins, these screens start fresh on the 1st. Earlier months live in the History tab.
- **Entries tab:** every entry for this month, grouped by day, newest first. Tap one to edit it.
- **Budgets tab:** give any expense category a monthly limit (optional). You see what's been spent, what's left, or how much you're over. Each month starts fresh on the 1st; unspent money doesn't roll over. You can also set or change a limit when you add or edit an expense category in Settings (the "Monthly limit" box; leave it empty for no limit). It is the same limit, so it shows up here too. Income categories have no limit. A limit you set applies to this month and later months until you change it, and past months keep their own limits, so you can look back in History. The page can show its numbers in two ways (see *Budget display* under Settings):
  - **Progress bars** (the default): each category shows how much is left, with a thin bar right underneath that fills up as you spend (it turns amber near the limit and red when you go over).
  - **Ring chart:** a doughnut-shaped ring at the top, with one colored slice per expense category sized by how much you spent on it this month. The total spent (and what's left of your budgets) is written in the middle, and a list below the ring shows each category's name, share and amount. The category rows below then have no bars.
- **History tab:** a list of past months (newest first) that have entries or budgets, each with its In, Out and Net. Tap a month to see its details: the totals, how each budget went (spent against its limit), and all its entries grouped by day. History is read-only, so past months can't be changed by accident.
- **Home tab:** the month's Net (money in minus money out) in large type, the In and Out totals, your savings goal, and a progress bar for each budget.
- **Savings goal (added in 0.3.0):** one monthly goal for the whole book, either a fixed amount (e.g. K 200,000 a month) or a share of the month's income (e.g. 20%). "Saved" means money in minus money out for the month. Home shows how much you've saved against the goal, how much is still to go (or "Goal reached"), and a thin bar. A percentage goal is worked out from this month's total income, rounded to your decimal places; with no income yet it says so instead of pretending the goal is met. If you've spent more than you earned, saved shows as a minus amount and the bar is empty. Set, change or remove it in Settings (or tap "Set goal" / the goal row on Home). Like budgets, a change applies from this month on and past months keep the goal they had; History's month detail shows how each past month did against its goal.
- **Settings:** change the currency symbol or decimal places, manage categories (add, rename, change color, set or change an expense category's monthly limit, archive; a category can only be deleted if no entry uses it), pick the theme (follow phone, light or dark), choose the **Budget display** (Progress bars or Ring chart; your choice is remembered), set the **Savings goal**, and view the licences.
- **Licenses:** a short page with Lucent's own notice, then one line per open-source package with its licence type (e.g. "sqflite — BSD-2"). Tap a line to read that licence in full. The Flutter and Dart SDK parts are grouped into one line; it and the "Full license texts" link open the complete standard list.

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
| `assets/brand/` | The Lucent logo: `logo-source.png` (original artwork), `logo.svg` (embeds that artwork), `logo-1024.png` (exact copy) and `logo-256.png` (used on the welcome and Licenses screens). `crystal.svg` / `crystal-1024.png` are silhouette references for themed icons. |
| `assets/fonts/` | The Inter typeface files (official v4.1 release) and their licence. They're packed inside the app, so nothing is downloaded. |
| `lib/` | **The app itself** (all the Dart code). |
| `lib/main.dart` | Starting point: opens the database, registers the font licence, picks light/dark theme, and shows setup or the main screens. |
| `lib/theme.dart` | The look: colors for light and dark mode, and the text sizes/weights (large amount, title, body, caption). All amounts use equal-width digits so they line up. |
| `lib/version.dart` | The version number shown in the app (a test checks it matches `pubspec.yaml`). |
| `lib/money.dart` | Turns typed amounts into whole numbers (e.g. 12.50 is stored as 1250) and formats them for display ("K 1,250"). |
| `lib/data/models.dart` | Describes a category and an entry. |
| `lib/data/goal.dart` | The savings goal and the maths behind it (target, saved, still to go). |
| `lib/data/db.dart` | Creates the on-phone database (SQLite) and its tables: settings, categories, entries, budgets, savings goals. When you update from 0.2.0 it adds the new savings-goal table and keeps all your existing data (database version 1 → 2). |
| `lib/data/store.dart` | The app's memory and bookkeeper: loads and saves everything, and works out totals (In, Out, Net, spent per category). Totals are always calculated, never stored. |
| `lib/widgets/common.dart` | Small reusable building blocks: amount text, month title, budget bar and budget row, category color dot, dividers. |
| `lib/widgets/budget_ring.dart` | The ring (doughnut) chart for the Budgets page, drawn directly by the app (no extra library). |
| `lib/screens/` | One file per screen: `onboarding.dart` (first-run setup), `home_shell.dart` (bottom tabs), `home.dart`, `transactions.dart` (Entries tab), `entry_form.dart` (add/edit entry), `budgets.dart`, `history.dart` (History tab and the past-month detail), `settings.dart` (also the categories list), `category_editor.dart` (the add/edit category box), `goal_editor.dart` (the savings goal box), `licenses.dart` (the short Licenses page). |
| `test/` | Automatic checks: amount parsing and formatting, savings goal maths (percentages, zero income, negative months), upgrading a 0.2.0 database, the Licenses page, plus on-screen walkthroughs (adding income and expenses and seeing them on Home, History, both budget displays, setting a goal, setting a category's limit from the category box). Run with `flutter test`. |
| `tool/make_icon.py` | Generates logos and Android launcher icons from `assets/brand/logo-source.png`. Run `python3 tool/make_icon.py` (requires Pillow: `python3 -m pip install Pillow`). Full-colour icons preserve the original image; themed icons use a traced silhouette. |
| `.github/workflows/android.yml` | Builds and tests the Android app on GitHub's computers on every push (a check that everything still builds). Its APK is signed with a throwaway key, so it's only for checking; the real APK is signed with the private key on the maintainer's computer (see below). |
| `android/` | The Android "wrapper" that turns the code into a phone app: app ID `app.lucent.budget`, name "Lucent", launcher icon (the crystal; an adaptive icon with a separate background, foreground and a one-colour layer for themed icons), and release signing setup. |
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
3. **Result:** `build/app/outputs/flutter-apk/app-release.apk`. Installing a newer version over an older one keeps all your data, as long as both were signed with the same key. It works on any modern Android phone (one "universal" file). Copy it to the phone and open it to install (you may need to allow "install unknown apps").

Keep the signing key and its password safe: updates must be signed with the same key, or the phone will refuse to install them over the old version.

## Checks

- `flutter analyze` checks the code for mistakes.
- `flutter test` runs the automatic checks.
