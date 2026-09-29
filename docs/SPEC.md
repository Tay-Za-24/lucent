# Lucent — v1 Product & Technical Specification

| | |
|---|---|
| **Status** | Draft v2: decisions applied (see §14) |
| **Owner** | Tay Za |
| **Date** | 29 Sep 2026 (first draft 27 Sep 2026) |
| **App name** | Lucent |
| **Package / bundle ID** | `app.lucent.budget` (all platforms) |
| **Stack** | Flutter (single codebase), local encrypted SQLite |
| **Release targets** | Android, iOS, macOS, Windows. Direct install only, no app stores in v1. No Linux release. |

---

## 1. Summary

Lucent is a private, offline budget tracker for Android, iOS, macOS and Windows. All data lives only on the device in an encrypted database. There is no account, no cloud and no server. Users create their own categories, log income and expenses, set monthly limits per category (calendar months, reset on the 1st), track savings goals (shown as a separate "Saved" line), let recurring bills and income post themselves, get a reminder the day before a bill is due, and browse past months.

Data leaves the device in only two ways, and the user starts both: (1) an encrypted `.lucent` backup file (manual, or optional automatic backups to a folder the user picks), and (2) a one-time **send over local Wi-Fi** to another of the user's devices, with an encrypted-file fallback.

The data model is built for **v2 sync from day one** (UUIDs, timestamps, tombstones, change log, hybrid logical clocks), so v2 "shared family books" won't need a schema rewrite.

v1 is distributed by direct install (APK, sideloaded IPA, unsigned Mac app, unsigned Windows installer). The limits of that are real, especially on iOS; see §12.

---

## 2. Goals and non-goals

### Goals (v1)
1. **Privacy by architecture.** Nothing leaves the device unless the user explicitly exports, auto-backs-up to a folder they chose, or sends it. The app needs no internet access to work and never contacts a server.
2. **Fast daily logging.** Adding an expense takes 3 taps plus typing the amount.
3. **Correct money math.** Amounts are integers in minor units, and totals are always derived, never stored.
4. **Useful budgeting.** Monthly category limits with the remaining amount, savings goals, and recurring items that post themselves.
5. **Move data between own devices** over LAN without internet, safely.
6. **Sync-ready schema** so v2 can add incremental LAN sync.
7. **Calm, typographic design.** Numbers are the hero; the interface stays out of the way (§5).

### Non-goals (v1)
- Cloud sync, user accounts, servers, update checks, or telemetry and analytics.
- App store distribution (Play, App Store, Mac App Store, Microsoft Store).
- Linux release builds.
- Multi-currency, exchange rates, or currency conversion.
- Bank or card connections, statement import, receipt scanning or photos.
- Payee, tags, split transactions, attachments.
- Budget carry-over (rollover) and custom month start days.
- Multiple books in the UI, shared or family books, multi-user permissions (v2).
- Continuous or automatic sync between devices (v2).
- Biometric or PIN app lock.
- Localization (English only; strings are kept in one file so it can be added later).
- Investments, loans and debt tracking, net-worth accounts. Web app.

---

## 3. User stories

| # | As a user I want to… | So that… |
|---|---|---|
| U1 | set my currency symbol and decimal places on first launch | amounts look right (e.g. `K` with 0 decimals, `$` with 2) |
| U2 | create my own expense and income categories during setup | the app matches how I actually think about money, with nothing to delete first |
| U3 | log an expense or income with amount, category, date and an optional note | I have an accurate record |
| U4 | edit or delete an entry, with undo | mistakes are easy to fix |
| U5 | set a monthly limit per category and see what's left this month | I know how much I can still spend |
| U6 | browse any past month's spending and budgets | I can look back at how a month went |
| U7 | create a savings goal and add contributions, shown separately from spending | saving doesn't look like overspending |
| U8 | set up rent, subscriptions and salary once and have them posted automatically | I don't re-enter the same items every month |
| U9 | get a reminder the day before a recurring bill is due | I'm never surprised by a bill |
| U10 | see money in, out and saved per month, and spending by category | I understand where my money goes |
| U11 | export an encrypted backup file and restore it later, with a monthly reminder | I don't lose data if I lose my phone |
| U12 | optionally have Lucent save encrypted backups to a folder I pick | backups happen without me thinking about it |
| U13 | send my data (all of it, or a date range) to my laptop over home Wi-Fi | I can use Lucent on another device without the internet |
| U14 | set up a new device by receiving data from my existing one | both devices share the same categories without duplicates |
| U15 | preview incoming data before it's imported, without creating duplicates | importing twice is harmless |
| U16 | send via a file when Wi-Fi blocks device-to-device traffic | transfer still works on guest or office networks |
| U17 | use a light or dark theme (following the system by default) | the app is comfortable day and night |

---

## 4. Screens

| Screen | Description |
|---|---|
| **Onboarding: Welcome** | Name, one-line privacy promise ("Your money stays on this device"), Get started. Secondary link: "Already use Lucent on another device? Receive your data" → Receive (skips the currency and category steps if the import provides them). |
| **Onboarding: Currency** | Symbol (free text ≤ 4 chars), decimal places 0–3, symbol before or after, digit grouping. A live example amount updates as you type. |
| **Onboarding: Create categories** | See §4.1. Nothing is pre-created. The user must add at least one expense category and at least one income category before continuing. |
| **Onboarding: Backups** | Short explanation that data can't be recovered without a backup; option to turn on auto-backup now (pick folder + passphrase) or later. Finish → Home. |
| **Home** | Month switcher (current month by default; back to the first month with data). Hero figure: **Net** for the month. Beneath it a quiet row: **In · Out · Saved**. Top budget bars (spent / limit / left). "Due tomorrow" and "Upcoming (next 7 days)" recurring items. Goals snapshot. Backup reminder card when due (§10.4). "+" to add an entry. |
| **Transactions** | List grouped by day with daily totals. Filters: type, category, date range, text search in notes. Swipe to delete (with undo snackbar). |
| **Add / Edit Transaction** | Expense/Income toggle, large amount entry (formats in minor units as you type), category list, date (defaults to today), note, "Repeat…" shortcut that creates a recurring rule. |
| **Categories** | Separate expense and income lists; add, rename, change color, optional icon, reorder, archive (archived categories keep their history). The last active category of each kind can't be archived or deleted. |
| **Budgets** | For the selected calendar month, each budgeted category shows limit, spent, left and a thin progress bar (color rules in §5.4). Past months are read-only views showing the limits that applied then. No carry-over: every month starts clean on the 1st. |
| **Edit Budget** | Set or clear a category's monthly limit. The change applies from the current month onward; limits continue month to month until changed. |
| **Savings Goals** | Rows with name, saved/target, % complete, and target date plus "needed per month" if a date is set. |
| **Goal Detail** | Progress bar, list of contributions (withdrawals as negative amounts), add contribution, edit goal, mark completed or archive. |
| **Recurring** | Active and paused rules with next due date and amount. Tap to edit; toggle to pause. |
| **Edit Recurring Rule** | Type, amount, category, note, frequency (daily/weekly/monthly/yearly with interval), day options, start date, end (never / on date / after N times), posting mode (**Post automatically**, the default, or Ask me first), "Remind me the day before" (default on for expenses, off for income). Shows the next 5 dates. |
| **Reports** | (a) In, Out and Saved per month for the last 6 or 12 months; (b) category breakdown for a month (bars with amounts and %); tap to drill into the matching transactions. |
| **Send** | Step 1 choose scope (everything / date range) → Step 2 choose a device (discovered list, "Scan QR", "Enter address") → pairing if needed → progress → done. "Use a file instead" is always visible. |
| **Receive** | "Ready to receive" with a QR code and this device's name; accept/decline an incoming offer; then Import Preview. Also reachable from Onboarding. |
| **Import Preview** | Shared by LAN receive, file import and merge-restore. Counts of new / unchanged (skipped) / updated / deletions, category matches and merges, currency check, then Import or Cancel. |
| **Backup & Restore** | Export encrypted backup (asks for a passphrase), last backup date, auto-backup (on/off, folder, passphrase, last run, keep last N), restore from file (Replace all or Merge). |
| **Settings** | Currency, Appearance (System / Light / Dark), Bill reminders (on/off, reminder time, show amounts in notifications), Backups, device name, paired devices, about and licenses (includes the Inter font license), "Erase all data". |
| **Paired Devices** | Trusted devices with name, platform and last-seen time; rename or remove (revoke trust). |

### 4.1 Category onboarding screen
- **Title:** "Create your categories". **Subtitle:** "Add the ones you use. You can change them any time."
- Two sections, **Expenses** and **Income**, each with an inline field ("Add an expense category", placeholder *e.g. Groceries*) and an Add button (Enter also adds). Placeholder text is only a hint; nothing is created unless the user types it.
- Added categories appear as rows (color dot + name) with rename and remove. Colors are assigned automatically from the palette in §5.4 in rotation; the user can change them later.
- Validation: name 1–40 characters after trimming, unique per kind (case-insensitive).
- **Continue** is disabled until there is at least one expense and one income category; helper text says what's missing ("Add at least one income category").
- New categories get ordinary random UUIDv7 IDs. There are no seeded or fixed-ID categories. Cross-device duplicates are handled by UUID and by merge (§9.6).
- Tip line under the Welcome link: to use Lucent on two devices, set up one, then set up the second with "Receive your data" so both share the same categories.

---

## 5. Design guide

**Direction:** clean, minimal, typographic. Neutral surfaces, one accent color, no gradients, almost no shadows. Amounts are the visual hero; everything else is quieter.

### 5.1 Principles
1. **Numbers first.** The key figure on each screen (Net, amount being entered, left in a budget, goal progress) uses the Display role. Labels are small and secondary.
2. **One accent.** A single blue is used for primary actions, selection, focus, progress fill and income. Everything else is neutral.
3. **Flat.** No gradients anywhere (backgrounds, buttons, charts, progress bars). Sections are separated by whitespace and hairline dividers, not cards and shadows.
4. **Quiet color for money.** Income and expense are told apart by sign and a subtle accent, never by loud red/green.
5. **Generous whitespace.** When in doubt, add space instead of a divider.

### 5.2 Typeface: Inter (bundled)
- **Family:** **Inter** by Rasmus Andersson, **v4.1** (latest release as of 29 Sep 2026), licensed under the **SIL Open Font License 1.1**, which allows bundling in an app. Its OpenType features include **`tnum` (tabular numbers)**, which give every digit the same width, so amounts line up in columns and don't jitter while typing.
- **Optical sizes:** Inter 4 ships **Inter Display** for large sizes (tighter, more refined at 28pt and up). Use Inter Display for amount roles ≥ 28pt and Inter for everything else. It's the same family, so the "one typeface" rule still holds.
- **Bundle the files and never download at runtime** (the app is offline). From the official `Inter-4.1.zip` release, copy only these static files from `extras/ttf/`: `Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-SemiBold.ttf`, `InterDisplay-Medium.ttf`, `InterDisplay-SemiBold.ttf`, plus `LICENSE.txt`. Declare them under `fonts:` in `pubspec.yaml` as families `Inter` (400/500/600) and `InterDisplay` (500/600). Static files are more predictable across platforms than the variable font. Do not use the `google_fonts` package's runtime fetching.
- Register `LICENSE.txt` with Flutter's `LicenseRegistry` so it appears in About → Licenses (the OFL requires the license to travel with the font).
- **Tabular numerals for all amounts:** every amount style sets `fontFeatures: [FontFeature.tabularFigures()]`. Put this in the text styles themselves, not per widget, so it can't be forgotten.
- Only three weights are used: 400, 500, 600. No italics, no bold 700+.
- Glyph fallback: currency symbols Inter lacks fall back to the platform font automatically. Test the symbols users are likely to enter (K, $, €, £, ¥, ₹, ฿, ₫, ₩).

### 5.3 Type scale
Sizes are logical pixels (pt on Apple, dp on Android). Line heights sit on a 4pt grid. Tracking is a starting point to tune by eye.

| Role | Family / weight | Size / line height | Tracking | Numerals | Used for |
|---|---|---|---|---|---|
| **Display amount** | Inter Display SemiBold 600 | 40 / 48 | −0.8 | tabular | Home Net, amount being entered, goal saved |
| **Headline amount** | Inter Display Medium 500 | 28 / 36 | −0.4 | tabular | "Left" on a budget, month totals in reports |
| **Title** | Inter SemiBold 600 | 20 / 28 | −0.2 | — | Screen and section titles |
| **Body** | Inter Regular 400 | 16 / 24 | 0 | proportional | Text, notes, list primary text |
| **Body amount** | Inter Medium 500 | 16 / 24 | 0 | tabular | Amounts in list rows, In/Out/Saved row |
| **Label** | Inter Medium 500 | 14 / 20 | +0.1 | tabular if numeric | Buttons, tabs, chips, field labels |
| **Caption** | Inter Regular 400 | 13 / 18 | +0.1 | tabular if numeric | Dates, helper text, secondary info (secondary color) |

Rules:
- Nothing smaller than 13 in the UI (12 only for chart axis labels).
- In the Display and Headline roles, render the currency symbol at ~60% size in the secondary text color, baseline-aligned, so the digits carry the weight.
- Use a true minus sign "−" (U+2212), not a hyphen. Amounts are right-aligned in lists.
- Never truncate an amount with an ellipsis. Scale the Display amount down to fit (down to Headline size), then wrap the label instead.
- Implement the roles as a `ThemeExtension` (e.g. `LucentText.displayAmount`) instead of stretching Material's built-in text styles.
- Date format: English, day-month order ("Tue, 29 Sep", "29 Sep 2026") to avoid US-style ambiguity.

### 5.4 Color
Mostly neutral backgrounds with one accent. Contrast ratios below were calculated against the background color of each theme (WCAG 2.x formula).

| Token | Light | Dark | Use | Contrast (light / dark) |
|---|---|---|---|---|
| `background` | `#FAFAF9` | `#0F0F10` | App background | — |
| `surface` | `#FFFFFF` | `#18181A` | Sheets, dialogs, input fields | — |
| `textPrimary` | `#16161A` | `#F3F3F1` | Main text, expense amounts, Net | 17.3 / 17.2 |
| `textSecondary` | `#5E5E66` | `#A3A3AB` | Labels, captions, currency symbol | 6.2 / 7.7 |
| `textTertiary` | `#8A8A93` | `#76767F` | Disabled text only, never essential text | 3.3 / 4.3 |
| `hairline` | `#E7E7E4` | `#2A2A2E` | Dividers, field outlines | decorative |
| `track` | `#EDEDEA` | `#252528` | Progress bar track | decorative |
| `accent` | `#2F5BD3` | `#8EA8FF` | Primary buttons, selection, focus ring, progress fill, income | 5.7 / 8.4 |
| `onAccent` | `#FFFFFF` | `#0F0F10` | Text on accent buttons | 5.9 / 8.4 (on accent) |
| `caution` | `#9A6200` | `#D8A64A` | Budget ≥ 80% used | 4.9 / 8.6 |
| `over` | `#A8472C` | `#E58E73` | Budget exceeded (muted clay, not alarm red) | 5.6 / 7.7 |

**Money colors:**
- Expense: `textPrimary`, no sign in lists (context makes it clear); "−" where In and Out are mixed.
- Income: "+" prefix in `accent`.
- Saved: `textSecondary` with a "Saved" caption. Never styled as spending.
- Net: `textPrimary`; a negative Net shows "−" and stays neutral (no red).

**Budget bars:** 4pt tall, rounded ends, `accent` fill on `track`. At ≥ 80% the fill turns `caution`; above 100% it turns `over` and the text reads "Over by K 5,000". State is always also shown in text, never by color alone.

**Category colors:** a fixed palette of 8 muted swatches with light/dark variants, each ≥ 4.3:1 against its background: slate `#4F72A8`/`#8FA9D6`, teal `#2F7F79`/`#6FB8B1`, olive `#6C7A2E`/`#A9B866`, ochre `#95701F`/`#D2AE5E`, clay `#A65A3F`/`#DE9679`, rose `#A34F6D`/`#D98FA9`, violet `#6E58A6`/`#AC9BDB`, graphite `#62666D`/`#A2A6AD`. They're used only for small dots and report bars. Store the palette index, not a hex value, so each theme picks its own variant.

**Themes:** Light and Dark, following the system by default; Settings → Appearance overrides it. Disable Material 3's elevation tint (`surfaceTintColor: Colors.transparent`) so surfaces stay neutral.

### 5.5 Space, shape and depth
- **8pt spacing scale:** 4 (tight, inside components only), 8, 16, 24, 32, 48, 64. No other values.
- Screen side margins 16 on phones, 24 on tablets and desktop. On wide windows, center content at max 720 wide.
- List rows at least 56 tall. 24 between sections, 48 above a screen's first title on large screens.
- **Hairline dividers:** Flutter's `BorderSide(width: 0)` draws a 1-physical-pixel line. Use it for list separators, inset 16 from the leading edge.
- **Corners:** 8 for buttons and inputs, 12 for sheets and dialogs. Lists are flat (no cards).
- **Shadows:** none on in-page content. Only floating layers (bottom sheets, menus, the "+" button) get one soft, low shadow in light mode. In dark mode, use the lighter `surface` color instead of a shadow.
- **Icons:** one outlined icon style at 20–24, `textSecondary` by default. Icons support labels; they never replace them.

### 5.6 Motion
- Durations 150–250 ms with standard ease-out curves. No bounce, spring overshoot, parallax or confetti.
- Platform-default page transitions (Cupertino on iOS/macOS, Material on Android/Windows).
- Progress bars animate their fill once when they appear (≈200 ms). Numbers never "count up"; changed amounts cross-fade.
- A light selection haptic on saving an entry (phones only).
- When the OS asks for reduced motion (`MediaQuery.disableAnimations`), all motion becomes instant.

### 5.7 Accessibility
- **Contrast:** body text ≥ 4.5:1, large text and meaningful UI parts (progress fill, focus ring, field outlines when they're the only affordance) ≥ 3:1. The token table above meets this. Add a unit test that recomputes contrast for every token pair so a later palette tweak can't regress it.
- **Text scaling:** respect the system text size (iOS Dynamic Type, Android font size, Windows text scaling) via `MediaQuery.textScaler`. Never disable it. Layouts must work at 200%: rows grow taller, amounts move below labels instead of truncating, and the Display amount may cap its own scale at 1.6×. Golden tests at 1.0×, 1.3× and 2.0× in both themes.
- **Bold text:** when the OS requests bold text (`MediaQuery.boldText`), step each role up one weight.
- **Targets:** at least 48×48 dp (Android/Windows) and 44×44 pt (Apple).
- **Screen readers:** give every amount a semantic label that includes its meaning ("Expense, 12,000", "Food budget: 45,000 of 60,000 spent, 15,000 left"). Charts get a text summary. Status is never conveyed by color alone.
- **Keyboard (desktop):** full tab navigation, visible 2pt `accent` focus ring, Enter to save, Esc to cancel, Ctrl/Cmd+N for a new entry.

### 5.8 Copy
- Plain, short, English. Sentence case. "Left", not "Remaining balance available".
- All user-facing strings live in **one file**, `lib/l10n/app_en.arb`, and are generated with Flutter's `gen-l10n` (`flutter_localizations` from the SDK). No hard-coded strings in widgets. Adding a language later means adding one `.arb` file.

---

## 6. Architecture overview

```
UI (Flutter widgets, LucentTheme)  ──  state (Riverpod providers)
        │
Domain (pure Dart, fully unit-tested)
  Money · RecurrenceEngine · ReminderPlanner · HLC · BundleCodec · ImportPlanner · BackupRotation
        │
Data (drift over encrypted SQLite)
  Repositories stamp ids/timestamps/HLC; SQL triggers write change_log
        │
Platform services
  SecureStorage (DB key, device keys, auto-backup passphrase) · FilePicker/Share · FolderAccess (SAF / bookmarks)
  Discovery (mDNS) · TLS server/client · LocalNotifications
```

Rules:
- Only repositories write to the database. Every write goes through one "mutation" path that stamps metadata, so sync metadata can't be skipped by accident.
- Balances, budget left, goal progress and report numbers are **SQL aggregate queries**, recomputed reactively (drift streams), and never persisted.
- "On open" jobs run in this order on app start, on resume, and when the date changes while the app is open: recurring generation (§8) → reminder rescheduling (§8.3) → auto-backup check (§10.5) → backup-reminder check (§10.4).

---

## 7. Data model

### 7.1 Conventions
- **Money:** `INTEGER` minor units (64-bit). Stored amounts are **always positive**, and the sign comes from `type` (`expense` / `income`). Goal contributions are the one exception: they are signed (negative = withdrawal).
- **Calendar dates** (when a transaction happened, rule dates): `TEXT 'YYYY-MM-DD'` in the user's local calendar. They are not timestamps, so time-zone changes never move an entry to a different day.
- **Months:** `TEXT 'YYYY-MM'`. Budget months are **calendar months** in the local calendar.
- **Instants** (`created_at`, `updated_at`, `deleted_at`): `INTEGER` Unix epoch milliseconds, UTC.
- **IDs:** `TEXT` UUID. **UUIDv7** for new records (time-ordered, which keeps indexes efficient). A few IDs are deterministic **UUIDv5** (see 7.4).
- **App namespace:** `APP_NAMESPACE = 5edbd5a8-f3ca-4604-9ff8-8cd525136969` (fixed random UUID; never change it).

### 7.2 Sync metadata (on every syncable table)

| Column | Type | Purpose |
|---|---|---|
| `id` | TEXT PK | UUID, globally unique across devices |
| `book_id` | TEXT FK → books | partition for v2 private vs shared books |
| `created_at` | INTEGER | creation instant (UTC ms) |
| `updated_at` | INTEGER | last modification instant (for display) |
| `origin_device_id` | TEXT | device that created the record |
| `author_id` | TEXT | "member" identity that created it (one per install in v1; v2 links a person's devices to one member). Basis for v2 edit ownership. |
| `hlc` | TEXT | hybrid logical clock of the last change (ordering and conflict resolution) |
| `version` | INTEGER | starts at 1, +1 on every change |
| `deleted_at` | INTEGER NULL | tombstone. Rows are never hard-deleted (except by "Erase all data"). |

**HLC format:** `<wall_ms:12 hex>-<counter:4 hex>-<device_id>`, which sorts correctly as plain text. Standard HLC rules: `wall = max(local_clock, last_hlc.wall, remote.wall)`, and the counter increments on ties. Imports advance the local HLC past any incoming HLC.

### 7.3 Tables

**`books`**: `name TEXT`, `kind TEXT` (`private` in v1; `shared` reserved for v2), `sort_order INTEGER`, + metadata (`book_id` = self). v1 has **one hidden default book**, created on first launch with the deterministic ID from 7.4, so every install's default book has the same ID and sent data lands in it without remapping. The UI never shows books in v1. Multiple books arrive in v2.

**`categories`**: `name TEXT`, `kind TEXT` (`expense`|`income`), `icon TEXT NULL`, `color_index INTEGER` (0–7, palette in §5.4), `sort_order INTEGER`, `archived INTEGER(0/1)`, `merged_into TEXT NULL` (FK → categories; set when this category was merged into another, see 9.6), + metadata. **No seeded categories**: all are user-created with UUIDv7 IDs. Invariant: at least one active (non-archived, non-deleted) category of each kind.

**`transactions`**

| Field | Type | Notes |
|---|---|---|
| `type` | TEXT | `expense` \| `income` |
| `amount_minor` | INTEGER | > 0 |
| `category_id` | TEXT FK | category `kind` must match `type` |
| `occurred_on` | TEXT date | |
| `note` | TEXT NULL | ≤ 500 chars |
| `recurring_rule_id` | TEXT NULL | set if generated by a rule |
| `occurrence_date` | TEXT NULL | the scheduled date this entry fulfils (may differ from `occurred_on` if the user edits it) |
| `status` | TEXT | `posted` (default) \| `pending` (awaiting confirmation from an "Ask me first" rule; excluded from totals) |
| + metadata | | Indexes: `(book_id, occurred_on)`, `(category_id, occurred_on)`, unique `(recurring_rule_id, occurrence_date)` |

**`budgets`** (monthly limit per category, versioned by month so past months keep their historical limits)

| Field | Type | Notes |
|---|---|---|
| `category_id` | TEXT FK | expense categories only |
| `amount_minor` | INTEGER | ≥ 0 |
| `effective_from` | TEXT month | limit applies from this month… |
| `effective_to` | TEXT month NULL | …through this month (NULL = open-ended) |
| + metadata | | Limit for month M = the row whose range contains M. Editing a limit closes the current row at last month and opens a new one from this month. |

**`savings_goals`**: `name TEXT`, `target_minor INTEGER`, `target_date TEXT NULL`, `icon TEXT NULL`, `completed_at INTEGER NULL`, `archived INTEGER`, + metadata.

**`goal_contributions`**: `goal_id TEXT FK`, `amount_minor INTEGER` (signed), `contributed_on TEXT date`, `note TEXT NULL`, + metadata.

**`recurring_rules`**

| Field | Type | Notes |
|---|---|---|
| `type`, `amount_minor`, `category_id`, `note` | | template for generated transactions |
| `freq` | TEXT | `daily` \| `weekly` \| `monthly` \| `yearly` |
| `interval` | INTEGER | every N periods (≥ 1) |
| `by_weekdays` | TEXT NULL | weekly: e.g. `"1,5"` (ISO Mon=1) |
| `month_day` | INTEGER NULL | monthly/yearly: 1–31, or `-1` = last day of month |
| `month` | INTEGER NULL | yearly: 1–12 |
| `start_on` | TEXT date | first possible occurrence |
| `end_on` | TEXT date NULL | |
| `max_count` | INTEGER NULL | end after N occurrences |
| `mode` | TEXT | **`auto` (default)**: post immediately \| `confirm`: create as pending |
| `remind` | INTEGER(0/1) | reminder the day before; default 1 for expense rules, 0 for income |
| `paused` | INTEGER | |
| `generated_through` | TEXT date NULL | high-water mark for this device's generator (local only, see 8) |
| + metadata | | |

**Local-only tables (never exported or synced):**
- `app_settings(key TEXT PK, value TEXT)`: currency symbol, decimals, symbol position, grouping; `onboarding_done`; `theme_mode` (system/light/dark); `reminders_enabled`, `reminder_time` (default `09:00`), `reminder_show_amounts` (default off); `last_backup_at`, `backup_reminder_snoozed_until`; `auto_backup_enabled`, `auto_backup_folder` (platform handle, see 10.5), `auto_backup_keep` (default 8), `last_auto_backup_at`, `last_auto_backup_seq`; device name.
- `devices(id TEXT PK, name, platform, tls_cert_sha256 BLOB, sign_pubkey BLOB, is_self INTEGER, paired_at, last_seen_at, revoked_at)`
- `change_log(seq INTEGER PK AUTOINCREMENT, entity TEXT, entity_id TEXT, op TEXT(insert|update|delete), hlc TEXT, device_id TEXT, at INTEGER)`: filled by `AFTER INSERT/UPDATE` triggers on every syncable table. The triggers copy `NEW.hlc`, which the repository sets. This lets v2 answer "changes since seq N", and lets auto-backup skip runs when nothing changed.
- `import_log(id, source_device_id, source_kind(lan|file|restore), bundle_sha256, imported_at, counts_json)`: audit trail; warns if the same bundle is imported twice.
- `sync_peers(peer_device_id, book_id, last_sent_seq, last_received_hlc)`: **created empty in v1**, used in v2.

### 7.4 Deterministic IDs
- **Default book:** `UUIDv5(APP_NAMESPACE, "book:default")`.
- **Generated recurring transactions:** `UUIDv5(APP_NAMESPACE, "<rule_id>:<occurrence_date>")`. Generation is idempotent on one device, across restores, and across devices in v2.
- Categories are **not** deterministic (no defaults exist). Duplicates are prevented by UUID identity plus the merge flow in 9.6.

### 7.5 Currency
- One currency per install: `symbol` (free text, ≤ 4 chars), `decimals` (0–3), `symbol_position`, grouping style. Display formatting uses `intl`.
- **Changing decimals after data exists** rescales every stored amount in one DB transaction. Increasing is lossless (×10^k). Decreasing rounds half-away-from-zero, and the user sees a warning with an example first.
- Bundles carry the sender's `decimals`. On import: equal → import as is. Incoming has fewer → scale up losslessly. Incoming has more → block, with an explanation ("Sender uses 2 decimals, this device uses 0"). The **symbol is not converted** (single currency is assumed), but a mismatch shows a warning. On a fresh install receiving during onboarding, the sender's currency settings are adopted.

### 7.6 Month totals (definitions)
For calendar month M, counting only `status = posted`, non-deleted rows:
- **In** = sum of income transactions dated in M.
- **Out** = sum of expense transactions dated in M.
- **Saved** = sum of goal contributions dated in M (withdrawals reduce it; it can be negative).
- **Net** = In − Out − Saved.
- **Budget spent** for a category = its expense transactions in M. Goal contributions never count toward budgets or Out.
- **Left** = limit for M − spent. **No carry-over**: unused or overspent amounts don't affect M+1.
- History: every past month is browsable from the month switcher (back to the earliest month with any record). Past-month limits are shown as they were (read-only).

---

## 8. Recurring items and bill reminders

### 8.1 When generation runs
On app start, on resume from background, when the date changes while the app is open, and immediately after a rule is created or edited. v1 has no background jobs, which is fine because totals are derived: missed items appear the next time the app opens. **Rules post automatically by default**; "Ask me first" rules create pending items to confirm.

### 8.2 Algorithm (per non-paused, non-deleted rule)
1. `from = max(start_on, generated_through + 1 day)`, `to = today` (local date).
2. Expand occurrence dates in `[from, to]` using the rules below. Stop at `end_on` or `max_count` (counting all existing occurrences of the rule, tombstoned ones included).
3. For each date, compute the deterministic ID (7.4). **Skip if a row with that ID exists, even as a tombstone.** Deleting one generated occurrence therefore means "skip this one" and it never comes back.
4. Insert the transaction (`status = posted` for `auto`, `pending` for `confirm`), `occurred_on = occurrence_date`.
5. Set `generated_through = to`. All of the above happens in one DB transaction.

**Date rules:**
- **Monthly on day 29–31:** clamp to the last day of shorter months (Jan 31 → Feb 28/29 → Mar 31). The anchor day is kept, so the date doesn't drift to the 28th forever.
- **`month_day = -1`:** always the last day of the month.
- **Yearly on Feb 29:** Feb 28 in non-leap years.
- **Weekly with interval N:** weeks are counted from the ISO week of `start_on`.
- **Catch-up cap:** if more than 60 occurrences would be created at once (e.g. a daily rule after months away), ask the user to confirm first.
- **Future items are never created.** "Upcoming" and "Due tomorrow" lists are computed on the fly from rules.

**Editing rules:**
- Edits change **future, not-yet-generated** occurrences only. Already-generated transactions stay as they are and can be edited individually.
- "Change from a date" (e.g. rent goes up in March) = set `end_on` on the old rule and create a new rule starting on that date. The UI does this as one action.
- Deleting a rule stops future generation. The user chooses whether to also delete its pending items. Posted items stay.
- Pausing, then resuming: the user is asked whether to back-fill the missed period or skip it. Skipping advances `generated_through` to today.

### 8.3 Bill reminders (local notifications)
- **What:** one local notification **the day before** each upcoming occurrence of a rule with `remind = 1` (default on for expense rules), at `reminder_time` (default 09:00 local). Text: "Rent is due tomorrow". The amount is included only if "Show amounts in notifications" is on (off by default, because notifications appear on the lock screen).
- **Scheduling (Android, iOS, macOS):** the OS delivers them even when the app is closed. `ReminderPlanner` (pure Dart) computes occurrences for the next 30 days. On each "on open" run and after any rule change, cancel all Lucent reminders and reschedule, capped at **50** (iOS keeps only 64 pending notifications per app). Use `zonedSchedule` with `timezone` + `flutter_timezone`, and each notification carries a payload of `rule_id` + date. Tapping one opens that rule's upcoming item.
- **Android:** request `POST_NOTIFICATIONS` (Android 13+) at the moment the user first creates a reminded rule, not during onboarding. Use **inexact** scheduling (`AndroidScheduleMode.inexactAllowWhileIdle`) so no exact-alarm permission is needed; a day-ahead reminder doesn't need minute precision. Add `RECEIVE_BOOT_COMPLETED` and the plugin's receivers so reminders survive reboots. Lock-screen visibility: private. Some OEM builds (e.g. Xiaomi, Huawei) may kill scheduled alarms; the in-app "Due tomorrow" list is the backstop.
- **iOS / macOS:** request permission in context (same moment). On macOS, notifications only work for a properly signed bundle; the ad-hoc signature in §12 is required. Verify on a real Mac.
- **Windows limitation:** for apps not packaged as MSIX, the notifications plugin can't cancel notifications, so rescheduling would leave stale reminders. On Windows v1 therefore **doesn't pre-schedule**. When the app starts or resumes (and once a day while it's running), it shows an immediate toast for bills due tomorrow, plus the in-app "Due tomorrow" list. Reminders on Windows only appear if Lucent is opened that day. This is stated in Settings.
- If reminders are off or permission is denied, Home still shows "Due tomorrow".

---

## 9. LAN send (one-time transfer)

### 9.1 Overview
One device **sends** a snapshot of selected records. The other **receives**, previews and imports. No internet, no relay server. Transport is HTTPS on the local network with pinned keys. The receiver's server runs **only while the Receive screen is open** and stops automatically after the transfer or after 10 minutes idle.

### 9.2 Device identity
Created on first launch and stored in platform secure storage:
- **TLS identity:** ECDSA P-256 key pair + self-signed X.509 certificate (generated with `basic_utils`). Fingerprint = SHA-256 of the certificate (DER).
- **Signing identity:** Ed25519 key pair (`cryptography`), used to authenticate the client side of a connection.
- `device_id` (UUID) and a user-editable device name.

### 9.3 Discovery
- **Primary: DNS-SD/mDNS (Bonjour/NSD)** via `bonsoir` (Android, iOS, macOS, Windows). Service type **`_lucent._tcp`** (6-character name, within the 15-character limit). The receiver advertises a random ephemeral port. TXT record: `v=1`, `id=<device_id>`, `fp=<first 8 bytes of cert fingerprint, hex>`, `n=<device name>`.
- **Secondary: QR code**, which contains the IP address(es) and port, so the sender can connect directly even when mDNS is filtered but unicast works.
- **Tertiary: manual "Enter address"** (IP:port shown on the Receive screen).
- UDP multicast announce is not planned for v1 (iOS raw multicast needs the restricted `com.apple.developer.networking.multicast` entitlement).

**Platform requirements:**
- **iOS:** `NSLocalNetworkUsageDescription` ("Lucent uses your local network to send data to your other devices.") and `NSBonjourServices` = `["_lucent._tcp"]` in Info.plist. The OS prompts on first use. If the user denies it, discovery fails silently, so after about 5 seconds with no results, show guidance (Settings → Privacy & Security → Local Network) and offer QR or file. Camera: `NSCameraUsageDescription` for QR scanning. None of this needs a paid developer account.
- **macOS:** App Sandbox entitlements `com.apple.security.network.server` and `.client`, `com.apple.security.device.camera` for QR, and `com.apple.security.files.user-selected.read-write` + `com.apple.security.files.bookmarks.app-scope` for backup files and folders. macOS 15+ also enforces Local Network privacy, so include the same Info.plist keys.
- **Android:** `INTERNET` (required for any socket, even LAN-only), `ACCESS_NETWORK_STATE`, `CHANGE_WIFI_MULTICAST_STATE`. NSD (`NsdManager`, used by `bonsoir`) handles mDNS. Camera permission for QR.
- **Windows:** the first time the server listens, Windows Firewall prompts. If the network profile is "Public", inbound connections are blocked, so detect connection timeouts and explain how to fix it or use a file.

### 9.4 Pairing (first time only)
Trust is established once per device pair and stored in `devices`. Later sends skip straight to 9.5 while fingerprints still match.

**A. QR pairing (preferred when one side has a camera).** The Receive screen shows:
`lucent://pair?v=1&id=<device_id>&h=<ip1,ip2>&p=<port>&fp=<cert_sha256_b64url>&k=<sign_pubkey_b64url>&t=<one-time token>&n=<name>`
The sender scans it, connects over TLS, and **accepts only a server certificate whose SHA-256 equals `fp`**. It then sends `POST /v1/pair` with the token (single use, expires in 5 minutes) and its own `device_id`, name, cert fingerprint and Ed25519 public key. Both sides store each other as trusted.
*Note:* `mobile_scanner` supports Android, iOS and macOS but **not Windows**. Windows therefore always *displays* the QR code, and phones or Macs scan it. Windows ↔ Windows uses method B.

**B. Code comparison pairing (no camera).** The sender picks the device from the discovered list and connects over TLS without verification yet. Both sides run a commit-reveal exchange: the sender sends `H(nonce_S)`, the receiver replies with `nonce_R`, the sender reveals `nonce_S`. Both screens then show a **6-digit code** = `SHA-256(fp_S ‖ fp_R ‖ nonce_S ‖ nonce_R) mod 10^6`. The user checks that the codes match and taps "Match" on both devices. This is the same numeric-comparison idea as Bluetooth LE Secure Connections. The commitment stops a man-in-the-middle from searching for keys that produce matching codes. After 3 failed or aborted attempts, pairing is locked for 1 minute.

### 9.5 Transfer protocol (HTTPS, JSON, version 1)
All requests go over TLS 1.3 (`dart:io` `HttpServer.bindSecure` / `HttpClient`). The **client pins the server certificate** via `badCertificateCallback` (fingerprint must equal the stored one). The **server authenticates the client** at the app layer: `GET /v1/challenge` returns a nonce, and each later request carries a header with the client's `device_id` and an Ed25519 signature over `(nonce ‖ server_fp ‖ method ‖ path ‖ body_sha256)`. The server rejects unknown or revoked devices.

| Step | Endpoint | Description |
|---|---|---|
| 1 | `GET /v1/info` | Protocol version, device id, name, schema version. Incompatible major version → friendly error. |
| 2 | `GET /v1/challenge` | Returns a nonce for request signing (60-second lifetime). |
| 3 | `POST /v1/offer` | Manifest: scope, record counts per table, date span, bundle size, `bundle_sha256`, sender decimals. The receiver shows "Tay's iPhone wants to send 412 transactions, 3 goals… (Jan–Sep 2026)" → **Accept / Decline**. The request waits for the answer (≤ 2 minutes) and returns a `session_id` on accept. |
| 4 | `PUT /v1/sessions/{id}/bundle` | Streams the bundle (gzip JSON, ≤ 50 MB). The receiver checks the size and SHA-256, and stages the data without writing to the DB. |
| 5 | (receiver UI) | **Import Preview** (9.6). The user confirms or cancels. |
| 6 | `GET /v1/sessions/{id}/result` | The sender polls for the result (imported / cancelled + counts) and shows "Done". |

Only one session at a time. Everything times out after 10 minutes and the server shuts down.

### 9.6 Bundle format and import rules
The same **bundle** format is used for LAN send, file send and backups:
```json
{ "format": "lucent-bundle", "schema": 1, "created_at": 1790000000000,
  "source": {"device_id": "…", "name": "Tay's iPhone"},
  "currency": {"symbol": "K", "decimals": 0},
  "scope": {"kind": "range", "from": "2026-01-01", "to": "2026-09-30"},
  "records": { "books": [...], "categories": [...], "transactions": [...],
               "budgets": [...], "savings_goals": [...], "goal_contributions": [...],
               "recurring_rules": [...] } }
```
- **Scope:** *Everything* or *Date range* (transactions and contributions by date, plus every category, goal and rule they reference). Referenced parents are always included so the data stays consistent. Tombstones inside the scope are included. (`book` scope returns in v2.)
- **Staging:** parse → validate the schema, types and limits (amount > 0, dates valid, foreign keys resolvable) → build an import plan. Any validation error rejects the whole bundle.
- **De-duplication by UUID:**
  - ID not present locally → **new**.
  - Present and identical content → **skip** (unchanged).
  - Present and different → **update if the incoming `hlc` is newer**. Default is "keep newer", with an alternative "keep mine".
  - Incoming tombstone for an existing live row with a newer `hlc` → **delete**. Listed separately in the preview with an off switch.
- **Category name match (different UUID, same kind and same name, case-insensitive and trimmed).** Because there are no seeded categories, this is the normal case when two devices were set up separately. The preview lists each match with **"Merge into your 'Groceries'"** switched **on** by default. On merge, the incoming category is stored as a tombstone with `merged_into = <local id>`, and all incoming references are rewritten to the local ID. Later imports that reference the merged ID are remapped automatically with no prompt, so repeated sends never duplicate. Unmatched incoming categories are imported as new.
- **Recurring rules** are imported as **paused** so both devices don't post the same items twice. The user can turn them on in one tap, and deterministic IDs prevent duplicates either way.
- **Commit:** a single DB transaction; the local HLC is advanced; `change_log` and `import_log` rows are written; imported rows keep their original `origin_device_id` / `author_id`. Re-importing the same bundle creates nothing. Reminders are rescheduled afterwards.

### 9.7 File fallback (AP isolation, no shared network)
"Use a file instead" exports the same bundle as an **encrypted `.lucent` file** (format in 10.3, passphrase chosen by the sender), named `Lucent-transfer-YYYY-MM-DD.lucent`. The user moves it any way they like (AirDrop, USB, Nearby Share, messaging). The receiver opens it via the file picker or the "Open with" / share target, enters the passphrase, and continues in the same Import Preview. The Send screen suggests this automatically when discovery or connecting fails (e.g. guest Wi-Fi with client isolation).

File-type registration: iOS/macOS export a UTI `app.lucent.budget.bundle` for extension `lucent`. Android accepts `ACTION_VIEW`/`ACTION_SEND` for `application/octet-stream` and checks the magic bytes, because extension matching on Android is unreliable. The in-app file picker always works. The Windows installer registers `.lucent` per-user.

### 9.8 Security summary

| Threat | Mitigation |
|---|---|
| Eavesdropping on Wi-Fi | TLS 1.3 for all traffic |
| Man-in-the-middle / impersonation | Certificate fingerprint pinned from QR or verified by code comparison; client requests signed with a paired Ed25519 key |
| Unwanted pushes from strangers | Server only runs while Receive is open; unpaired devices must pair; every offer needs explicit Accept |
| Malicious or corrupt bundle | Size cap, SHA-256 check, strict schema validation, preview, all-or-nothing DB transaction |
| Lost or compromised device | "Paired Devices" → revoke (the fingerprint is rejected afterwards) |
| Discovery leaking info | TXT record has only name, a short fingerprint and protocol version, and only while Receive is open. The device name is user-editable. |
| Someone else using the unlocked device | **Accepted in v1**: there is no app lock. Anyone who can unlock the device can open Lucent. The DB is encrypted at rest and bound to the device keystore. |

---

## 10. Storage, encryption and backup

### 10.1 Encrypted database
- **drift** on **`sqlite3` 3.x with SQLite3MultipleCiphers** (`hooks: user_defines: sqlite3: source: sqlite3mc` in pubspec). This is drift's currently documented encryption path. *Note:* `sqlcipher_flutter_libs` is **end-of-life** (v0.7.0+eol) and must not be used. Default cipher: sqlite3mc's default (ChaCha20-Poly1305).
- The key is set via `PRAGMA key` in `NativeDatabase` `setup`. At startup, assert that `PRAGMA cipher` returns a value, so the app can never silently run unencrypted.
- The DB file lives in the app support directory (`path_provider`). It is excluded from OS cloud backups: Android `allowBackup="false"`, iOS "do not back up" attribute. This matches the local-only promise, and the keystore key wouldn't survive such a restore anyway.

### 10.2 Key management (no app lock)
- On first launch, generate a random 256-bit DB key and store it in **`flutter_secure_storage`**: iOS Keychain (`first_unlock_this_device`), Android Keystore-backed ciphers (v10+ default RSA-OAEP + AES-GCM), Windows Credential Manager/DPAPI, and on macOS the **legacy (file-based) Keychain via `MacOsOptions(usesDataProtectionKeychain: false)`**. The data-protection keychain needs the `keychain-access-groups` entitlement, which requires a provisioning profile that an unsigned/ad-hoc build doesn't have. TLS and Ed25519 private keys, and the auto-backup passphrase (10.5), are stored the same way.
- **No biometric or PIN lock, and no user passphrase on the DB.** The keystore-held key is the only protection at rest. `local_auth` is not a dependency.
- **Consequence:** if the OS keystore is wiped or the app's signing identity changes (factory reset, some reinstall paths, re-signing an iOS build with a different Apple ID, see §12), the database can't be decrypted. **Encrypted backups are the recovery path.** If the key is missing or unreadable at startup, the app never overwrites the old DB file. It moves it aside and offers "Restore from backup" or "Start fresh".
- macOS (ad-hoc signed): after each app update the signature changes, so macOS may ask once whether Lucent may use its Keychain item. The app explains this before the prompt ("Choose Always Allow") and retries if the user declines.

### 10.3 Backup and file format (`.lucent`)
```
magic "LCNT" | format_version u8 | kdf_id u8 | argon2id params (mem KiB u32, iters u32, par u8)
| salt 16B | nonce 24B | ciphertext (XChaCha20-Poly1305 over gzip(bundle JSON)) | tag 16B
```
- Key = **Argon2id**(passphrase, salt) (default 64 MiB / 3 iterations / parallelism 1, tuned to take under 1.5 s on a mid-range phone). The whole header is authenticated as AAD. Crypto comes from `cryptography` + `cryptography_flutter`.
- Manual backups: the passphrase is entered at export time (minimum 10 characters, with a strength hint) and is **never stored**. The app warns that a forgotten passphrase means the backup can't be opened.
- **Backup** = bundle with scope "everything", including tombstones and currency settings, but **excluding** device identity keys, paired devices and local settings.
- File names: `Lucent-backup-YYYY-MM-DD.lucent` (manual), `Lucent-auto-YYYY-MM-DD-HHmm.lucent` (auto).
- **Restore modes:** *Replace all* (wipe, then load, with double confirmation) or *Merge* (the same import rules as 9.6).
- Save via the platform save dialog (`file_picker` `saveFile`) or the share sheet (`share_plus`).

### 10.4 Monthly backup reminder
- If no backup (manual or auto) has succeeded in **30 days**, Home shows a dismissible card: "Last backup: 12 Aug. Back up now". Snooze = 7 days. In-app only, no notification.
- The reminder also appears once after the first 20 entries if the user has never backed up.

### 10.5 Optional auto-backup to a user-picked folder
- **Enable:** Backup & Restore → Auto-backup → pick a folder → set an auto-backup passphrase (min. 10 chars, entered twice). The screen warns: "If this folder syncs to a cloud service, your encrypted backups will leave this device."
- **Passphrase storage:** so backups can run unattended, this passphrase **is stored in secure storage**. It's the one exception to "passphrases are never stored", and the UI says so. The user must still remember or record it, because restoring on a new device needs it.
- **When it runs:** during the "on open" jobs (§6), if ≥ 24 h since the last auto-backup **and** `change_log` has new entries since `last_auto_backup_seq`. It runs in the background of the running app. Write to a temp name, then rename, so a partial file never looks valid.
- **Rotation:** keep the newest `auto_backup_keep` (default 8) files. Delete only files in that folder matching `Lucent-auto-*.lucent`. Never touch anything else.
- **Failure** (folder gone, permission revoked, disk full): a quiet Home banner with "Choose folder again". It never blocks the app.
- **Folder access per platform** (small platform channels; evaluate a maintained package first):
  - Android: Storage Access Framework `ACTION_OPEN_DOCUMENT_TREE` + `takePersistableUriPermission`, writing through `DocumentFile`. Store the tree URI.
  - iOS: `UIDocumentPickerViewController` in folder mode, plus a security-scoped bookmark (`startAccessingSecurityScopedResource` around each write). The folder can be "On My iPhone" or any Files provider.
  - macOS (sandboxed): an app-scoped security-scoped bookmark (entitlements in 9.3).
  - Windows: a plain folder path.
- Auto-backup is off by default.

---

## 11. Recommended Flutter packages

Versions confirmed on pub.dev on 27 Sep 2026; entries marked † checked on 29 Sep 2026. Pin versions in `pubspec.lock`.

| Package | Version seen | Use |
|---|---|---|
| `drift` | 2.35.0 | Type-safe SQLite ORM, migrations, reactive queries |
| `drift_flutter` | 0.3.1 | Opens drift DBs on each platform (or use `NativeDatabase` directly for the encryption `setup` hook) |
| `sqlite3` | 3.6.0 | SQLite bindings, bundles **SQLite3MultipleCiphers** via hook option `source: sqlite3mc` |
| ~~`sqlcipher_flutter_libs`~~ | 0.7.0+eol | **Do not use.** Obsolete, replaced by the `sqlite3` 3.x hook |
| `flutter_secure_storage` | 11.2.0 † | DB key, device private keys, auto-backup passphrase (macOS: `usesDataProtectionKeychain: false`) |
| `bonsoir` | 7.1.5 | mDNS/DNS-SD advertise and discover |
| `nsd` | 5.0.1 | Alternative to bonsoir; fallback option |
| `mobile_scanner` | 7.4.2 | QR scanning (Android, iOS, macOS; **not Windows**) |
| `qr_flutter` | 4.1.0 | Render the pairing QR code (stable but last published about 3 years ago) |
| `basic_utils` | 5.8.2 | Generate EC key pair and self-signed X.509 cert for TLS |
| `cryptography` | 2.9.0 | Ed25519, X25519, XChaCha20-Poly1305/AES-GCM, Argon2id, SHA-256 |
| `cryptography_flutter` | 2.3.4 | Native-accelerated crypto on Android and Apple platforms |
| `uuid` | 4.6.0 | UUIDv7 / v5 generation |
| `path_provider` | 2.1.6 | App data directories |
| `file_picker` | 13.1.0 | Open and save backup and transfer files |
| `share_plus` | 13.3.0 | Share-sheet export of files |
| `flutter_local_notifications` | 22.3.1 † | Bill reminders. Needs Flutter ≥ 3.38.1, Android core-library desugaring, compileSdk ≥ 35. Windows: no cancel without MSIX (see 8.3). |
| `timezone` | 0.11.1 † | `TZDateTime` for `zonedSchedule` |
| `flutter_timezone` | 5.1.0 † | Reads the device's IANA time zone |
| `intl` | 0.20.3 | Number and date formatting |
| `flutter_localizations` | (Flutter SDK) | `gen-l10n` from the single `app_en.arb` string file |
| `fl_chart` | 1.2.0 | Bar charts for reports (flat styling, no gradients) |
| `flutter_riverpod` | 3.4.3 | State management (a suggestion; any mainstream option works) |

Removed since the first draft: `local_auth` (no app lock). HTTPS server/client, TLS and gzip use `dart:io`. Fonts are bundled assets (§5.2), not a package.

---

## 12. Build, distribution and release

### 12.1 Identifiers (fixed; changing any of these later breaks upgrades and Keychain access)

| Item | Value |
|---|---|
| Display name | Lucent |
| Android `applicationId` / iOS & macOS bundle ID | `app.lucent.budget` |
| Dart package name (`pubspec.yaml`) | `lucent` |
| mDNS service type | `_lucent._tcp` |
| Pairing URI scheme | `lucent://` |
| File extension / magic / bundle format | `.lucent` / `LCNT` / `lucent-bundle` |
| Apple UTI | `app.lucent.budget.bundle` |
| Windows AppUserModelID (notifications) | `app.lucent.budget` |
| Windows toast activator GUID | `5A90E9AE-5511-48BF-BA37-0DAA181AC39C` |
| Windows installer AppId (Inno Setup) | `D6237A53-1283-4095-86A3-7C25EBAAF721` |
| UUIDv5 namespace | `5edbd5a8-f3ca-4604-9ff8-8cd525136969` |

`app.lucent.budget` is reverse-DNS for `lucent.app`, a domain we don't own. That's fine for sideloaded builds (IDs only need to be unique on the device), and app stores only require uniqueness too. Pick it once and never change it.

**Minimum OS targets** (from package requirements): Android 7.0 / API 24, iOS 14, macOS 10.15, Windows 10. **Linux:** not a release target. The `linux/` platform folder isn't created. The Linux dev machine builds and tests Android (device or emulator) and runs the pure-Dart unit tests.

### 12.2 Per-platform distribution (no app stores in v1)

**Android: signed APK, sideloaded**
- Built **locally on the Linux dev machine**: `flutter build apk --release` (one universal APK; `--split-per-abi` optional to shrink it).
- Signed with our own release keystore made with `keytool` (free; no Google account needed). The keystore and its passwords **never enter the repo or CI**. Keep two offline copies. Losing the key means future versions can't install over the old one: users would have to uninstall (losing data unless they have a backup).
- Install: the user allows "Install unknown apps" for their browser or file manager. Play Protect may show a warning or offer to scan an unknown app.
- Updates: install a newer APK (higher `versionCode`, same key) over the old one; data is kept. There is no auto-update, and the app never checks the internet for updates.
- **Android developer verification (be aware):** Google now requires apps on certified Android devices to be registered by a verified developer. As of 29 Sep 2026, enforcement starts 30 Sep 2026 only in Brazil, Indonesia, Singapore and Thailand, and only for installs from participating stores. Direct APK sideloads aren't affected yet. Google plans a global rollout covering all install sources in 2027. When that happens, the options are: register through the Android Developer Console (there is a "limited distribution" account type for hobbyists, up to 20 devices, no identity verification), have users complete Android's one-time "advanced flow" for unverified apps (includes a 24-hour wait), or install via `adb` (exempt). Re-check before each release.

**iOS: sideloading without a paid Apple Developer account (the weakest platform in v1)**
- CI (macOS runner) builds an **unsigned** app: `flutter build ipa --no-codesign`, then zip `Payload/Runner.app` into `Lucent.ipa`. It must be a **release** build: Flutter debug builds won't launch from the home screen on iOS 14+.
- The user signs and installs it with **their own free Apple ID** using one of:
  - **AltStore (classic):** AltServer on a Mac or Windows PC installs and re-signs apps. Refresh needs AltServer running on the same Wi-Fi.
  - **SideStore:** needs a computer once for setup, then refreshes on the phone using a pairing file and a VPN helper app. It occasionally breaks after iOS updates or when the helper app changes.
  - **Xcode on a Mac** with a free "personal team": build and run directly to a connected iPhone.
- **Hard limits of a free Apple ID** (set by Apple, not by these tools):
  - Apps stop launching **7 days** after signing unless refreshed. Data isn't lost when an app expires; it opens again after a refresh.
  - At most **3 sideloaded apps** active per device (AltStore/SideStore counts as one).
  - At most **10 new App IDs per 7 days**.
  - iOS 16+ requires **Developer Mode** to be turned on (Settings → Privacy & Security) and the developer profile to be trusted.
- **Data risk specific to Lucent:** the DB key sits in the iOS Keychain, which is tied to the signing team. Always refresh with the **same Apple ID**. Re-signing with a different Apple ID (or later moving to a paid account) makes iOS treat Lucent as a different app, since AltStore/SideStore may also rewrite the bundle ID. The old data and key then become unreachable. Always make a `.lucent` backup before changing how the app is signed. Deleting the app deletes its data.
- Not available with a free account, and not needed: push notifications, App Groups, TestFlight. Local notifications, Local Network/Bonjour, camera and Keychain all work.
- **Realistic upgrade path (not in v1):** the Apple Developer Program ($99/year) gives 1-year signing, ad-hoc installs on up to 100 registered devices per device type, and TestFlight, all without a public App Store listing.

**macOS: ad-hoc signed app, direct download**
- CI (macOS runner): `flutter build macos --release`. Xcode signs it **ad-hoc** ("Sign to Run Locally", identity `-`) **with the sandbox entitlements**. Ship `Lucent.app` in a `.dmg` (`hdiutil`) or a zip made with `ditto -c -k --keepParent`.
- CI checks: `codesign --verify --deep --strict Lucent.app` and `codesign -d --entitlements - Lucent.app`. Apple Silicon needs at least an ad-hoc signature, and since macOS 15.1 a missing or damaged signature fails with no "Open Anyway" option. Never re-sign without passing the entitlements file, or the sandbox and network entitlements are dropped.
- **First launch (Gatekeeper):** macOS blocks it as not notarized. The user tries to open it once, then goes to **System Settings → Privacy & Security → Open Anyway**, confirms and authenticates. Since macOS 15 the old Control-click → Open shortcut no longer bypasses this. Terminal alternative: `xattr -dr com.apple.quarantine /Applications/Lucent.app`. Document both on the release page.
- Expect a Keychain access prompt after updates (10.2). Local notifications need this proper ad-hoc signed bundle (8.3).
- Notarization and Developer ID signing need the paid Apple Developer Program, so they're out of scope for v1.

**Windows: unsigned installer**
- CI (Windows runner): `flutter build windows --release`, then package with **Inno Setup** as a per-user installer (installs to `%LOCALAPPDATA%\Programs\Lucent`, no admin needed, registers `.lucent` for the current user, creates the Start-menu shortcut that toast notifications rely on). Also publish a portable zip. Include the MSVC runtime DLLs (`msvcp140.dll`, `vcruntime140.dll`, `vcruntime140_1.dll`) next to the exe, as Flutter's Windows distribution docs describe. The build machine needs the C++ ATL component for `flutter_secure_storage`.
- **SmartScreen:** unsigned downloads show "Windows protected your PC". The user clicks **More info → Run anyway**. Expect this for every new release, since unsigned files build no reputation.
- **Smart App Control** (Windows 11, when enabled) may block unsigned apps outright with no per-app override. The user would have to turn it off. Document this honestly.
- MSIX is not used: it can't be installed without a trusted signature. As a result, notification cancel isn't available and reminders work as described in 8.3.
- The first Receive triggers a Windows Firewall prompt (9.3).
- Code signing (a paid certificate or a signing service) is a later option.

**Integrity for unsigned builds:** each GitHub Release lists **SHA-256 checksums** (`SHA256SUMS.txt`) for every artifact, and the release notes explain how to check them.

### 12.3 CI pipeline (GitHub Actions, public repo)
1. **Every push/PR** (`ubuntu-latest`): `flutter analyze`, unit tests (money, recurrence engine, reminder planner, HLC, bundle codec, import planner including category merge, backup rotation, palette contrast), drift migration tests, golden tests (both themes, text scale 1.0/1.3/2.0), and `flutter build apk --debug` as a compile check.
2. **Tag `v*`**: macOS runner → unsigned `Lucent.ipa` + ad-hoc signed `Lucent.dmg`; Windows runner → `Lucent-Setup.exe` + portable zip. Attach them to a **draft** GitHub Release along with `SHA256SUMS.txt`. The signed Android APK is built locally and attached by hand, so the keystore never touches GitHub. Publishing the draft release is a manual step.
3. Pin the Flutter version (e.g. via a Flutter setup action) so every runner and the local machine build the same thing. Pin third-party actions to commit SHAs.
4. **Cost:** standard GitHub-hosted runners (Linux, Windows and macOS) are free for public repositories, so building Apple and Windows on every tag costs nothing. Larger runners are still billed; don't use them.

### 12.4 Public repository rules (nothing secret may be committed)
- Never commit: the Android keystore, `key.properties`, any passwords or tokens, real `.lucent` files, screenshots or fixtures containing real financial data, or personal device names and IPs.
- `.gitignore` from day one: `*.jks`, `*.keystore`, `key.properties`, `*.lucent` (except synthetic test fixtures under `test/fixtures/`, which use generated data and a documented test passphrase), `.env*`.
- Turn on GitHub **secret scanning** and **push protection**. Require approval before workflows run for first-time outside contributors. v1 CI needs **no secrets at all**; keep it that way.
- Everything in the repo, including this spec and the release artifacts, is public.

### 12.5 Testing focus
Property-based tests for recurrence (month ends, leap years, intervals) and for reminder planning (DST, the 50-reminder cap, time-zone changes). Round-trip tests for bundle export → import (idempotency: importing twice creates no changes; merged categories remap on repeat imports). A golden-file test so old `.lucent` backups stay readable. Auto-backup rotation deletes only its own files. Onboarding can't finish without one expense and one income category. Manual matrix: LAN send (iPhone ↔ Android ↔ Mac ↔ Windows; home Wi-Fi, phone hotspot, guest Wi-Fi → file fallback); install and update flows per platform (APK over APK; AltStore refresh; Gatekeeper Open Anyway; SmartScreen); Keychain behavior after a macOS update; notifications on each platform.

---

## 13. Roadmap after v1 (out of scope; informs v1 design)

**v2: Multiple books and shared books with LAN sync**
- Users can create books. A book is either **private** (never leaves the device, excluded from every sync query by `book_id`) or **shared** (synced with invited family members' devices). The v1 default book becomes the first private book.
- Paired devices (9.4) become sync peers. Membership of a shared book is a signed list of member identities (`author_id` → device keys).
- **Incremental sync:** each peer tracks `last_sent_seq` / `last_received_hlc` per book in `sync_peers`. A sync session sends only `change_log` entries after that point (the latest row state plus tombstones, including category `merged_into`), over the same pinned TLS channel. Runs when both devices are on the same LAN and the app is open.
- **Ownership rule:** only the entry's `author_id` may edit or delete it. Other members' devices reject changes to rows they don't own. This removes most conflicts.
- **Remaining conflicts** (the same author editing on two of their own devices, or shared objects like categories and budgets): **highest HLC wins** by default. For budgets and goals, the user is prompted if both sides changed since the last sync.
- **Why v1 already fits:** UUID keys, `book_id` on every row, `author_id`, `origin_device_id`, HLC, `version`, tombstones, `change_log`, deterministic recurring and default-book IDs, `merged_into`, derived totals and an empty `sync_peers` table are all in v1. v2 adds logic, not a schema rewrite.

**Later candidates:** budget carry-over (rollover), custom month start day (e.g. payday), receipt photos, payee / tags / split transactions, CSV export, localization (e.g. Burmese with Myanmar digits; strings are already in one `.arb` file), paid Apple Developer Program for longer-lived iOS installs, code signing for Windows and notarization for macOS, optional store distribution.

---

## 14. Decisions (answered 29 Sep 2026; replaces "Open questions")

| # | Topic | Decision | Applied in |
|---|---|---|---|
| D1 | Name and identifiers | **Lucent.** Package/bundle ID `app.lucent.budget`; mDNS `_lucent._tcp`; URI `lucent://`; files `.lucent` (magic `LCNT`, format `lucent-bundle`). | Header, §9.3, §9.4, §9.6–9.7, §10.3, §12.1 |
| D2 | Budget month | Calendar months, reset on the 1st. Past months persist and are browsable. | §4, §7.1, §7.6 |
| D3 | Recurring default | Auto-post by default; "Ask me first" available per rule. | §4, §7.3, §8.1 |
| D4 | Language | English only in v1; all strings in one `app_en.arb` file. | §5.8, §11 |
| D5 | Distribution | Direct install only, no app stores: APK (Android), sideloaded unsigned IPA via AltStore/SideStore/Xcode with a free Apple ID (7-day expiry, 3-app limit), ad-hoc signed Mac app (Gatekeeper "Open Anyway"), unsigned Windows installer (SmartScreen "Run anyway"). | §12.2 |
| D6 | Savings | Contributions show as a separate **Saved** line, not spending. Net = In − Out − Saved. | §4, §5.4, §7.6 |
| D7 | Carry-over | None in v1; each month starts clean. Carry-over listed as future. | §7.6, §13 |
| D8 | Books | One hidden default book (deterministic ID) in v1; multiple books in v2. | §7.3, §7.4, §13 |
| D9 | Security | **No biometric/PIN lock.** DB key held in the OS keystore/Keychain only; no DB passphrase. | §9.8, §10.2, §11 |
| D10 | Backups | Monthly in-app backup reminder, plus optional auto-backup to a user-picked folder (stored auto-backup passphrase, rotation). | §10.4, §10.5 |
| D11 | Notifications | Local notification the day before a recurring bill is due (Windows: shown when the app is open, see 8.3). | §8.3 |
| D12 | Linux | No Linux release. The Linux dev machine builds Android. | Header, §12.1 |
| D13 | Entry details | Amount, category, date, note only. No payee, tags, splits or attachments (receipt photos maybe later). | §2, §13 |
| D14 | Categories | **No default categories.** Onboarding requires the user to create at least one expense and one income category. Fixed-ID starter categories removed; dedupe via UUIDs plus name-match merge with `merged_into`. | §4.1, §7.3, §7.4, §9.6 |
| D15 | Repository | Public GitHub repo (free standard Actions runners). Nothing secret is ever committed; v1 CI uses no secrets. | §12.3, §12.4 |
| D16 | Design | Clean, minimal, flat; Inter (bundled) with tabular numerals; light and dark themes; one accent. | §5 |
