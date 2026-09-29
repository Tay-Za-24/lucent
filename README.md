# Lucent

A minimal, private budget tracker for Android and Mac. Everything you enter stays on your device. The app never talks to the internet. The only network use is **Send to another device**, which copies your book directly to your own other phone or Mac over your home Wi-Fi, and only while you have that screen open.

> **This is the `macos` branch** (work in progress after 0.3.0): it adds the Mac app and "Send to another device". The main branch is still the Android-only 0.3.0.

## What the app does (version 0.3.0)

- **First-run setup:** a welcome screen, then you pick your currency symbol (anything you like, e.g. `K` or `$`) and whether amounts use 0 or 2 decimal places. Then you create your own categories. Nothing is pre-filled; you need at least one expense and one income category to start.
- **Entries:** add, edit or delete an expense or income: amount, category, date (today unless you change it; it can't be later than this month) and an optional note. If something is missing (no amount or no category), a message says what to fix instead of nothing happening.
- **Always this month:** Home, Entries and Budgets only ever show the current month, with its name at the top. There's no switching between months; when a new month begins, these screens start fresh on the 1st. Earlier months live in the History tab.
- **Entries tab:** every entry for this month, grouped by day, newest first. Tap one to edit it.
- **Budgets tab:** give any expense category a monthly limit (optional). You see what's been spent, what's left, or how much you're over. Each month starts fresh on the 1st; unspent money doesn't roll over. A limit you set applies to this month and later months until you change it, and past months keep their own limits, so you can look back in History. The page can show its numbers in two ways (see *Budget display* under Settings):
  - **Progress bars** (the default): each category shows how much is left, with a thin bar right underneath that fills up as you spend (it turns amber near the limit and red when you go over).
  - **Ring chart:** a doughnut-shaped ring at the top, with one colored slice per expense category sized by how much you spent on it this month. The total spent (and what's left of your budgets) is written in the middle, and a list below the ring shows each category's name, share and amount. The category rows below then have no bars.
- **History tab:** a list of past months (newest first) that have entries or budgets, each with its In, Out and Net. Tap a month to see its details: the totals, how each budget went (spent against its limit), and all its entries grouped by day. History is read-only, so past months can't be changed by accident.
- **Home tab:** the month's Net (money in minus money out) in large type, the In and Out totals, your savings goal, and a progress bar for each budget.
- **Savings goal (new in 0.3.0):** one monthly goal for the whole book, either a fixed amount (e.g. K 200,000 a month) or a share of the month's income (e.g. 20%). "Saved" means money in minus money out for the month. Home shows how much you've saved against the goal, how much is still to go (or "Goal reached"), and a thin bar. A percentage goal is worked out from this month's total income, rounded to your decimal places; with no income yet it says so instead of pretending the goal is met. If you've spent more than you earned, saved shows as a minus amount and the bar is empty. Set, change or remove it in Settings (or tap "Set goal" / the goal row on Home). Like budgets, a change applies from this month on and past months keep the goal they had; History's month detail shows how each past month did against its goal.
- **Settings:** change the currency symbol or decimal places, manage categories (add, rename, change color, archive; a category can only be deleted if no entry uses it), pick the theme (follow phone, light or dark), choose the **Budget display** (Progress bars or Ring chart; your choice is remembered), set the **Savings goal**, and view the licences.
- **Send to another device (this branch):** Settings → *Send to another device*. See *How sending works* below.
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
| `assets/brand/` | The Lucent logo: `logo.svg` (the original drawing, a faceted crystal), `logo-1024.png` (large picture) and `logo-256.png` (used inside the app on the welcome and Licenses screens). |
| `assets/fonts/` | The Inter typeface files (official v4.1 release) and their licence. They're packed inside the app, so nothing is downloaded. |
| `lib/` | **The app itself** (all the Dart code). |
| `lib/main.dart` | Starting point: opens the database, registers the font licence, picks light/dark theme, and shows setup or the main screens. |
| `lib/theme.dart` | The look: colors for light and dark mode, and the text sizes/weights (large amount, title, body, caption). All amounts use equal-width digits so they line up. |
| `lib/version.dart` | The version number shown in the app (a test checks it matches `pubspec.yaml`). |
| `lib/money.dart` | Turns typed amounts into whole numbers (e.g. 12.50 is stored as 1250) and formats them for display ("K 1,250"). |
| `lib/data/models.dart` | Describes a category and an entry. |
| `lib/data/goal.dart` | The savings goal and the maths behind it (target, saved, still to go). |
| `lib/data/db.dart` | Creates the on-device database (SQLite) and its tables: settings, categories, entries, budgets, savings goals. Upgrades keep all existing data: 1 → 2 added the savings-goal table; 2 → 3 (this branch) gives every record the ID of the device that last changed it, a last-changed time and a "deleted" mark, so two devices can be merged safely. Deleting now only marks a record as deleted. |
| `lib/data/sync.dart` | Packs the whole book into one bundle (JSON) and merges a bundle from another device: records are matched by their random ID, the newer change wins, deletions carry over, and nothing is doubled. |
| `lib/share/transfer.dart` | The Wi-Fi send itself: a tiny server on the receiving device, the PIN check and the encryption. |
| `lib/screens/share.dart` | The *Send to another device*, *Send* and *Receive* screens. |
| `lib/data/store.dart` | The app's memory and bookkeeper: loads and saves everything, and works out totals (In, Out, Net, spent per category). Totals are always calculated, never stored. |
| `lib/widgets/common.dart` | Small reusable building blocks: amount text, month title, budget bar and budget row, category color dot, dividers. |
| `lib/widgets/budget_ring.dart` | The ring (doughnut) chart for the Budgets page, drawn directly by the app (no extra library). |
| `lib/screens/` | One file per screen: `onboarding.dart` (first-run setup), `home_shell.dart` (bottom tabs), `home.dart`, `transactions.dart` (Entries tab), `entry_form.dart` (add/edit entry), `budgets.dart`, `history.dart` (History tab and the past-month detail), `settings.dart` (also the categories list), `category_editor.dart` (the add/edit category box), `goal_editor.dart` (the savings goal box), `licenses.dart` (the short Licenses page). |
| `test/` | Automatic checks: amount parsing and formatting, savings goal maths (percentages, zero income, negative months), upgrading a 0.2.0 database, the Licenses page, plus on-screen walkthroughs (adding income and expenses and seeing them on Home, History, both budget displays, setting a goal). Run with `flutter test`. |
| `tool/make_icon.py` | Redraws the logo and all Android launcher icons from one set of crystal shapes. Run `python3 tool/make_icon.py` (needs `rsvg-convert`). |
| `android/` | The Android "wrapper" that turns the code into a phone app: app ID `app.lucent.budget`, name "Lucent", launcher icon (the crystal; an adaptive icon with a separate background, foreground and a one-colour layer for themed icons), and release signing setup. |
| `android/app/src/main/AndroidManifest.xml` | Android settings, including the network permission that Send to another device needs (see below). |
| `macos/` | The Mac "wrapper": app name "Lucent", ID `app.lucent.budget`, the crystal icon, window size, and the permissions for the local network (`Runner/*.entitlements`, `Runner/Info.plist`). |
| `.github/workflows/macos.yml` | Builds the Mac app on GitHub's Mac computers every time this branch is pushed (or when started by hand) and offers it as a download. |
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

## Mac app (this branch)

The Mac app is built automatically by GitHub, because building it needs a Mac.

1. **Download:** open the repository on GitHub → **Actions** → **macOS build** → the newest run with a green tick. At the bottom, under *Artifacts*, download **Lucent-macos** (you must be signed in to GitHub). You get `Lucent-macos.zip`; double-click it (if your browser didn't unzip it already) to get `Lucent.app`, and drag that into *Applications*.
2. **First launch:** the app isn't signed with an Apple developer certificate, so macOS will refuse a normal double-click. Instead **right-click (or Control-click) Lucent → Open → Open**. You only do this once. On newer macOS versions, if there's no *Open* button, try to open it once, then go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**.
3. **Local network permission:** the first time you use *Send* or *Receive*, macOS asks whether Lucent may find and connect to devices on your local network. Click **Allow**. If you clicked *Don't Allow*, turn it on in **System Settings → Privacy & Security → Local Network**. macOS may also ask whether Lucent may accept incoming connections (when receiving): click **Allow**.

The Mac app works like the phone app, in a phone-width column in the middle of the window. Its data is stored separately on the Mac; use *Send to another device* to copy your book across.

## How sending works

Use it to copy your book from your phone to your Mac (or the other way round, or phone to phone). Both devices need this version and must be on the **same Wi-Fi**.

1. On the device that should **get** the data: Settings → **Send to another device** → **Receive**. It shows an address (like `192.168.1.20:40123`) and a 6-digit **PIN**. Keep that screen open.
2. On the device that **has** the data: Settings → **Send to another device** → **Send**, type the address and the PIN, and tap **Send**.
3. Both screens show the result, e.g. "Received 132 entries (120 new, 12 updated, 0 removed, 0 already here)".

What happens to the data:

- Everything is sent: categories, entries, budgets, the savings goal, and the currency symbol and decimal places.
- Nothing is doubled. Every record has its own random ID; if the other device already has it, the newer change is kept. Something you deleted on the sending device is deleted on the receiving one too (unless it was changed there more recently). Sending the same data twice changes nothing.
- If both devices were set up separately and each has a category with the same name and type (e.g. "Food"), they are treated as the same category.
- If the two devices use different **decimal places**, nothing is imported and both screens say so; change one of them in Settings first. A different **currency symbol** is only a warning (amounts are copied as they are). A device that has no amounts yet simply takes over the sender's currency settings.

Privacy and safety:

- The devices talk to each other directly over your Wi-Fi. There's no server and nothing goes over the internet. The receiving device only listens while its Receive screen is open, and stops after one transfer, after 3 wrong PINs, or after 5 minutes.
- The PIN is never sent. Both devices turn it into a key, and the data is encrypted with it (AES-256-GCM), so others on the Wi-Fi can't read it and any change on the way is detected. Someone on the same Wi-Fi who records the transfer could in theory try all million PINs offline, so only send on a network you trust (your home Wi-Fi).
- **Android permission:** to open any network connection Android needs the *internet* permission, so this version asks for it. Lucent still never contacts the internet; it only connects to the address you type in, on your local network.
- There is no automatic finding of devices yet and no QR code: you type the address and PIN.

## Checks

- `flutter analyze` checks the code for mistakes.
- `flutter test` runs the automatic checks, including the merge rules (newer wins, deletions, no duplicates, currency checks) and a full send between two copies of the app on the same computer.
