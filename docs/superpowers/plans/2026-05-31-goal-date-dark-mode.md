# Goal Date Limit & Dark Mode Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cap goal target dates at 6 years from today, add 5 new dark theme presets, and fix all hardcoded color usage across the app so every screen renders correctly in dark themes.

**Architecture:** Three independent workstreams: (1) a single-line date constraint fix, (2) new preset data added to the theme catalog, and (3) a screen-by-screen color audit replacing hardcoded literals with `Theme.of(context).colorScheme.*` equivalents. No new abstractions — follow the existing `FinanceColors` extension and `colorScheme` usage patterns already present in the codebase.

**Tech Stack:** Flutter, Dart, Material 3, `ThemeData` / `ColorScheme`, `FinanceColors` theme extension

---

## Color Replacement Reference

Use this table throughout ALL audit tasks. When you find a hardcoded color, apply the correct theme-aware replacement.

| Hardcoded | Context | Theme-aware replacement |
|-----------|---------|------------------------|
| `Colors.white` | Background/card fill | `Theme.of(context).colorScheme.surface` |
| `Colors.white` | Text/icon on colored bg | Keep `Colors.white` only when on a dark/colored container; otherwise use `colorScheme.onSurface` |
| `Colors.white.withValues(alpha: x)` | Overlay/glass | `Theme.of(context).colorScheme.onSurface.withValues(alpha: x * 0.5)` or use `FinanceColors.glassBackground` |
| `Colors.black` | Text | `Theme.of(context).colorScheme.onBackground` |
| `Colors.black87` | Secondary text | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87)` |
| `Colors.black.withValues(alpha: x)` | Overlay | `Theme.of(context).colorScheme.shadow.withValues(alpha: x)` |
| `Colors.grey` / `Colors.grey[N]` | Hint/divider | `Theme.of(context).colorScheme.outline` (dividers) or `colorScheme.onSurface.withValues(alpha: 0.4)` (hints) |
| `Colors.grey.shade50` | Input fill (light) | Already in `InputDecorationTheme` — remove local override if duplicating |
| `Colors.red` / `Colors.redAccent` | Error | `Theme.of(context).colorScheme.error` |
| Hardcoded dark bg `Color(0xFF07090F)` etc. | Container bg | `Theme.of(context).colorScheme.surface` or `scaffoldBackgroundColor` |
| Hardcoded light bg `Color(0xFFF6F7FB)` etc. | Container bg | `Theme.of(context).colorScheme.background` |
| Category/transaction colors (`Color(0xFFFF9500)` etc.) | Semantic domain colors | Leave as-is — these are intentional semantic colors, not theme-dependent |
| `FinanceColors.income` / `.expense` / `.savings` | Domain semantic | Already theme-aware — do NOT change |

**Rule for icons on AppBar / colored backgrounds:** `Colors.white` is correct when the icon sits on `colorScheme.primary`. Only replace `Colors.white` with `colorScheme.onSurface` when the icon sits on a neutral/surface background.

---

## Task 1: Goal Date Limit

**Files:**
- Modify: `lib/features/goals/presentation/pages/goals_crud_page.dart:180`

- [ ] **Step 1: Apply the constraint change**

Open `lib/features/goals/presentation/pages/goals_crud_page.dart`. Find line 180 inside `_DateTile.build` → `showDatePicker`:

```dart
// Current (line 180):
lastDate: DateTime(2100),

// Replace with:
lastDate: DateTime(DateTime.now().year + 6, 12, 31),
```

The complete `showDatePicker` call after the change:

```dart
final DateTime? picked = await showDatePicker(
  context: context,
  initialDate: value,
  firstDate: DateTime(2000),
  lastDate: DateTime(DateTime.now().year + 6, 12, 31),
);
```

- [ ] **Step 2: Run the analyzer**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && flutter analyze lib/features/goals/presentation/pages/goals_crud_page.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && git add lib/features/goals/presentation/pages/goals_crud_page.dart && git commit -m "feat: cap goal target date to 6 years from today"
```

---

## Task 2: New Dark Theme Presets

**Files:**
- Modify: `lib/utils/app_theme_preset.dart`

- [ ] **Step 1: Read the file to understand existing preset structure**

Read `lib/utils/app_theme_preset.dart`. Presets are entries in the `static const List<AppThemePreset> all` list. Each entry uses the `AppThemePreset(id, name, primary, isDark, isPremium, background?, surface?)` constructor.

- [ ] **Step 2: Add 2 new FREE dark presets**

In `lib/utils/app_theme_preset.dart`, after the existing `noche` preset entry (the last free theme) and before the `// ── Premium themes` comment, add:

```dart
// Electric green on near-black — clean, productivity
AppThemePreset(
  id: 'carbon',
  name: 'Carbón',
  primary: Color(0xFF00C853),
  isDark: true,
  isPremium: false,
  background: Color(0xFF1A1A1A),
  surface: Color(0xFF242424),
),

// Indigo-blue on deep dark — cool, focused
AppThemePreset(
  id: 'indigo_dark',
  name: 'Índigo',
  primary: Color(0xFF536DFE),
  isDark: true,
  isPremium: false,
  background: Color(0xFF1C1B2E),
  surface: Color(0xFF252438),
),
```

- [ ] **Step 3: Add 3 new PRO dark presets**

After the existing `cosmos` preset (last existing PRO dark theme) and before `arena`, add:

```dart
// Ruby red on very dark — bold, premium
AppThemePreset(
  id: 'ruby',
  name: 'Rubí',
  primary: Color(0xFFEF5350),
  isDark: true,
  isPremium: true,
  background: Color(0xFF1A0A0A),
  surface: Color(0xFF2A1010),
),

// Amber/gold on dark warm — luxurious
AppThemePreset(
  id: 'amber_dark',
  name: 'Ámbar',
  primary: Color(0xFFFFB300),
  isDark: true,
  isPremium: true,
  background: Color(0xFF1C1400),
  surface: Color(0xFF2A1E00),
),

// Forest green on deep dark — earthy, calm
AppThemePreset(
  id: 'bosque',
  name: 'Bosque',
  primary: Color(0xFF43A047),
  isDark: true,
  isPremium: true,
  background: Color(0xFF0A1A0A),
  surface: Color(0xFF122012),
),
```

- [ ] **Step 4: Run the analyzer**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && flutter analyze lib/utils/app_theme_preset.dart
```

Expected: No issues found.

- [ ] **Step 5: Verify the new presets appear in the themes page**

The themes page (`lib/features/settings/presentation/pages/themes_page.dart`) renders all presets from `AppThemePreset.all` dynamically. No code change is needed — the new presets will auto-appear. Confirm by reading the file and checking it iterates `AppThemePreset.all`.

- [ ] **Step 6: Commit**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && git add lib/utils/app_theme_preset.dart && git commit -m "feat: add 5 new dark theme presets (2 free, 3 PRO)"
```

---

## Task 3: Dark Mode Audit — Auth Screen

**Files:**
- Modify: `lib/features/auth/presentation/pages/auth_layout.dart`

This file has the most hardcoded colors (~22+ instances). It controls the login/register/splash UI.

- [ ] **Step 1: Read the full file**

Read `lib/features/auth/presentation/pages/auth_layout.dart` in full.

- [ ] **Step 2: Identify and fix all hardcoded colors**

Apply the Color Replacement Reference table at the top of this plan. Key patterns to find:

```bash
grep -n "Colors\.white\|Colors\.black\|Colors\.grey\|Color(0xFF" lib/features/auth/presentation/pages/auth_layout.dart
```

For each match:
- If `Colors.white` is used as a background fill → replace with `Theme.of(context).colorScheme.surface`
- If `Colors.white` is used as text/icon color on a colored container → keep `Colors.white`
- If `Colors.black` or `Colors.black87` is used as text → replace with `Theme.of(context).colorScheme.onSurface`
- If `Color(0xFF1F1F1F)` (dark fixed color) is used on a widget that must adapt → replace with `Theme.of(context).colorScheme.onSurface`
- The constant `_kGreen = Color(0xFF0E8F5B)` at the top — if used for a UI element that must respond to theme, replace with `Theme.of(context).colorScheme.primary` at the call site; if it's a semantic indicator (success/active) leave as-is

- [ ] **Step 3: Run the analyzer**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && flutter analyze lib/features/auth/presentation/pages/auth_layout.dart
```

Fix any errors.

- [ ] **Step 4: Commit**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && git add lib/features/auth/presentation/pages/auth_layout.dart && git commit -m "fix: replace hardcoded colors in auth screen for dark theme support"
```

---

## Task 4: Dark Mode Audit — Dashboard

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- Modify: `lib/features/dashboard/presentation/widgets/balance_card.dart`

The dashboard page has 35+ `Colors.white` instances. The balance card has a hardcoded dark gradient.

- [ ] **Step 1: Read both files**

Read `lib/features/dashboard/presentation/pages/dashboard_page.dart` and `lib/features/dashboard/presentation/widgets/balance_card.dart`.

- [ ] **Step 2: Fix dashboard_page.dart**

```bash
grep -n "Colors\.white\|Colors\.black\|Colors\.grey\|Color(0xFF\|Colors\.red" lib/features/dashboard/presentation/pages/dashboard_page.dart
```

Apply replacements:
- `Colors.white` used as text/icon color on gradient/colored sections → keep `Colors.white`
- `Colors.white` used as background/card fill → `Theme.of(context).colorScheme.surface`
- `Colors.white.withValues(alpha: x)` used as overlay → use `Theme.of(context).extension<FinanceColors>()!.glassBackground` when it's a glass effect
- `Colors.red.shade200` (line ~899) → `Theme.of(context).colorScheme.error.withValues(alpha: 0.7)`
- `Color.lerp(primaryColor, Colors.white, 0.2)` (line ~388) → `Color.lerp(primaryColor, Theme.of(context).colorScheme.surface, 0.2)`

- [ ] **Step 3: Fix balance_card.dart**

The card has `colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)]` — a hardcoded dark gradient that becomes invisible on light themes and clashes with custom dark themes.

Replace fixed gradient colors with theme-aware ones:

```dart
// Replace hardcoded gradient colors with:
colors: [
  Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
  Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
],
```

All `Colors.white` used as text/icon on this colored card → keep `Colors.white` (correct — it's on a colored background).

- [ ] **Step 4: Run the analyzer**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && flutter analyze lib/features/dashboard/
```

Fix any errors.

- [ ] **Step 5: Commit**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && git add lib/features/dashboard/ && git commit -m "fix: replace hardcoded colors in dashboard and balance card for dark theme"
```

---

## Task 5: Dark Mode Audit — Quick Finance Widgets

**Files:**
- Modify: `lib/features/quick_finance/presentation/widgets/transaction_tile.dart`
- Modify: `lib/features/quick_finance/presentation/widgets/balance_card.dart`

- [ ] **Step 1: Read both files**

Read both files in full.

- [ ] **Step 2: Fix transaction_tile.dart**

```bash
grep -n "Colors\.white\|Colors\.black\|Colors\.grey\|Color(0xFF" lib/features/quick_finance/presentation/widgets/transaction_tile.dart
```

Key patterns:
- Transaction type colors (`Color(0xFFFF9500)` orange, `Color(0xFF34C759)` green, `Color(0xFFFF3B30)` red etc.) — these are semantic category colors. **Leave them as-is** — they are intentional and readable on both light/dark.
- Any `Colors.white` or `Colors.black` used as generic background or text (not tied to a specific category) → replace with `colorScheme.surface` or `colorScheme.onSurface`
- Any `Colors.grey` for secondary text → `colorScheme.onSurface.withValues(alpha: 0.6)`

- [ ] **Step 3: Fix quick_finance balance_card.dart**

```bash
grep -n "Colors\.white\|Colors\.black\|Colors\.grey\|Color(0xFF" lib/features/quick_finance/presentation/widgets/balance_card.dart
```

Status indicator colors (lines ~96, 98, 148, 149, 255, 256, 265, 266):
- If they are semantic status colors (e.g., green = positive, red = negative) → replace with `Theme.of(context).extension<FinanceColors>()!.income` and `.expense` respectively
- Background fills → `colorScheme.surface`
- `Colors.white` text on colored container → keep

- [ ] **Step 4: Run the analyzer**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && flutter analyze lib/features/quick_finance/
```

Fix any errors.

- [ ] **Step 5: Commit**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && git add lib/features/quick_finance/ && git commit -m "fix: replace hardcoded colors in quick finance widgets for dark theme"
```

---

## Task 6: Dark Mode Audit — Navigation Drawer & App Lifecycle

**Files:**
- Modify: `lib/utils/widgets/drawer.dart`
- Modify: `lib/utils/widgets/app_lifecycle_listener.dart`

- [ ] **Step 1: Read both files**

Read `lib/utils/widgets/drawer.dart` and `lib/utils/widgets/app_lifecycle_listener.dart`.

- [ ] **Step 2: Fix drawer.dart**

```bash
grep -n "Colors\.white\|Colors\.black\|Colors\.grey\|Color(0xFF" lib/utils/widgets/drawer.dart
```

Lines ~183, 195, 205, 219, 227, 232, 289, 312:
- `Colors.white` as text/icon on the drawer header (which uses `colorScheme.primary` as background) → keep `Colors.white`
- `Colors.white` as list tile background → `colorScheme.surface`
- `Colors.black` as text → `colorScheme.onSurface`
- Any hardcoded divider color → `colorScheme.outline`

- [ ] **Step 3: Fix app_lifecycle_listener.dart**

```bash
grep -n "Colors\.white\|Colors\.black\|Colors\.grey\|Color(0xFF\|Colors\.red" lib/utils/widgets/app_lifecycle_listener.dart
```

Lines ~198, 204, 217, 240, 254, 281, 285:
- `Colors.white` as dialog/sheet background → `colorScheme.surface`
- `Colors.redAccent` → `colorScheme.error`
- `Colors.black.withValues(alpha: x)` as overlay → `colorScheme.shadow.withValues(alpha: x)`

- [ ] **Step 4: Run the analyzer**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && flutter analyze lib/utils/widgets/drawer.dart lib/utils/widgets/app_lifecycle_listener.dart
```

Fix any errors.

- [ ] **Step 5: Commit**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && git add lib/utils/widgets/drawer.dart lib/utils/widgets/app_lifecycle_listener.dart && git commit -m "fix: replace hardcoded colors in drawer and lifecycle widgets for dark theme"
```

---

## Task 7: Dark Mode Audit — Settings & Themes Page

**Files:**
- Modify: `lib/features/settings/presentation/pages/themes_page.dart`

- [ ] **Step 1: Read the file**

Read `lib/features/settings/presentation/pages/themes_page.dart`.

- [ ] **Step 2: Identify and fix hardcoded colors**

```bash
grep -n "Colors\.white\|Colors\.black\|Colors\.grey\|Color(0xFF" lib/features/settings/presentation/pages/themes_page.dart
```

Lines ~109, 110, 122, 123, 132, 133, 192, 199, 226, 227, 232, 240, 249, 256, 433:
- The themes page shows a preview of each preset using that preset's own colors (e.g., `Color(0xFF1E1B4B)` for a purple preview) — these are intentional preview swatches, **leave them as-is**
- Any `Colors.white` or `Colors.grey` used as the *page's own* text, background, or divider (not as part of a swatch preview) → replace with `colorScheme.surface` / `colorScheme.onSurface` / `colorScheme.outline`
- The currently-selected theme banner (lines ~105-139): uses colors to indicate selected state — ensure the selected indicator uses `colorScheme.primary` not a hardcoded color

- [ ] **Step 3: Run the analyzer**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && flutter analyze lib/features/settings/presentation/pages/themes_page.dart
```

Fix any errors.

- [ ] **Step 4: Commit**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && git add lib/features/settings/presentation/pages/themes_page.dart && git commit -m "fix: replace hardcoded page-level colors in themes page for dark theme"
```

---

## Task 8: Dark Mode Audit — Subscription Paywall & Onboarding

**Files:**
- Modify: `lib/features/subscription/presentation/pages/paywall_page.dart`
- Modify: `lib/features/onboarding/presentation/widgets/onboarding_content.dart`

- [ ] **Step 1: Read both files**

Read both files in full.

- [ ] **Step 2: Fix paywall_page.dart**

```bash
grep -n "Colors\.white\|Colors\.black\|Colors\.grey\|Color(0xFF" lib/features/subscription/presentation/pages/paywall_page.dart
```

Lines ~59, 135, 249, 370 — hardcoded dark gradients like `Color(0xFF0F172A)`, `Color(0xFF020617)`:
- The paywall may intentionally use a dark premium look regardless of theme. If the gradient is part of the "premium" visual identity (dark stars/glow effect), replace fixed dark values with `colorScheme.surface` / `colorScheme.background` so they adapt across dark presets.
- `Colors.white70`, `Colors.white54`, `Colors.white.withValues()` used as text on dark background → keep if the containing background is a fixed dark gradient; replace with `colorScheme.onSurface.withValues(alpha: x)` if the background adapts.
- `Colors.white` as button/card background → `colorScheme.surface`

- [ ] **Step 3: Fix onboarding_content.dart**

```bash
grep -n "Colors\.white\|Colors\.black\|Colors\.grey\|Color(0xFF" lib/features/onboarding/presentation/widgets/onboarding_content.dart
```

Lines ~36, 47, 72, 82, 96, 100, 125, 134:
- `Colors.black87` / `Colors.black` text → `colorScheme.onSurface`
- `Colors.grey[600]` → `colorScheme.onSurface.withValues(alpha: 0.6)`
- Hardcoded illustration colors `Color(0xFF5D4037)`, `Color(0xFF00695C)` — if these are decorative illustration colors not connected to text/background readability, leave them; if they are UI element colors (buttons, backgrounds), replace with `colorScheme.primary` or `colorScheme.surface`

- [ ] **Step 4: Run the analyzer**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && flutter analyze lib/features/subscription/ lib/features/onboarding/
```

Fix any errors.

- [ ] **Step 5: Commit**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && git add lib/features/subscription/ lib/features/onboarding/ && git commit -m "fix: replace hardcoded colors in paywall and onboarding for dark theme"
```

---

## Task 9: Full Analyzer Pass & Verification

- [ ] **Step 1: Run analyzer on the entire project**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && flutter analyze
```

Expected: No new errors or warnings introduced. Pre-existing `info`-level lints (5 in test files) are acceptable.

- [ ] **Step 2: Manual verification with dark themes**

The implementer should set `selectedThemeId` to each dark preset and visually scan major screens:
- `noche` — original dark theme
- `carbon` — new free dark (electric green)
- `indigo_dark` — new free dark (indigo)
- `medianoche` — PRO dark AMOLED
- `galaxia` — PRO deep purple
- `cosmos` — PRO cyan
- `ruby` — new PRO dark (red)
- `amber_dark` — new PRO dark (gold)
- `bosque` — new PRO dark (green)

For each theme, check:
- [ ] Text is readable on all screens
- [ ] Icons are visible (no dark-on-dark or white-on-white)
- [ ] Card backgrounds contrast with scaffold background
- [ ] Input fields are visible
- [ ] Bottom nav bar readable
- [ ] Dialogs/bottom sheets readable

If any issue is found during this check, fix it and add to the relevant commit or create a new fix commit.

- [ ] **Step 3: Run tests**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && flutter test
```

Expected: Same pass rate as before (206 passing, 5 pre-existing failures in quick_finance_bloc_goals_debts_test.dart unrelated to our changes).

- [ ] **Step 4: Final commit if any remaining fixes**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && git add -A && git commit -m "fix: remaining dark theme rendering fixes from full verification pass"
```

---

## Self-Review

**Spec coverage:**
- Goal date limit (6 years cap) → Task 1 ✓
- New FREE dark presets: Carbón, Índigo → Task 2 ✓
- New PRO dark presets: Rubí, Ámbar, Bosque → Task 2 ✓
- Dark audit - auth → Task 3 ✓
- Dark audit - dashboard → Task 4 ✓
- Dark audit - quick finance → Task 5 ✓
- Dark audit - navigation/drawer → Task 6 ✓
- Dark audit - settings/themes → Task 7 ✓
- Dark audit - subscription/onboarding → Task 8 ✓
- Full verification → Task 9 ✓

**Placeholder scan:** All tasks have concrete grep commands, specific line references, and replacement rules. No "TBD" or vague instructions.

**Type consistency:** `FinanceColors.glassBackground` referenced in Tasks 4 and 5 is defined in `lib/utils/theme.dart` as a `ThemeExtension<FinanceColors>` — access via `Theme.of(context).extension<FinanceColors>()!.glassBackground`.

**Edge cases:**
- Category/semantic colors intentionally left hardcoded (orange for food, red for loss, etc.) — explicitly noted in the Color Replacement Reference and in Tasks 5, 8.
- Paywall dark gradient intentional identity — handled in Task 8 with explicit note.
- Theme preview swatches in themes_page — explicitly excluded from replacement in Task 7.
