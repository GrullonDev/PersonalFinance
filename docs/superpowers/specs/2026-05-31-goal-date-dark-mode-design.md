# Design Spec: Goal Date Limit & Dark Mode Improvements

**Date:** 2026-05-31
**Status:** Approved
**Scope:** Two independent improvements — goal creation date cap and dark theme expansion + rendering audit

---

## 1. Problem Statements

### 1.1 Goal Date Has No Meaningful Upper Limit

The goal creation form allows users to set a target date up to year 2100, which is impractical for a personal finance app focused on achievable milestones. Users should be constrained to realistic planning horizons.

**Desired behavior:** The date picker caps selection at December 31 of the year that is 6 years from the current year (e.g., in 2026 → max is Dec 31, 2032). The cap is always relative to today, not a hardcoded year.

### 1.2 Dark Themes Have Rendering Issues

The app controls its own theme via preset `ThemeData` objects while keeping `ThemeMode.light` always set. Several widgets use hardcoded colors (`Colors.white`, `Colors.black`, `Color(0xFF...)`) that do not adapt when a dark preset is active, producing unreadable text, invisible icons, and low-contrast UI elements.

Additionally, the FREE plan has only one dark theme (Noche) and the PRO plan has three, which limits user personalization.

**Desired behavior:** All UI elements render clearly in any dark preset. The FREE plan gains two additional dark themes; the PRO plan gains three more.

---

## 2. Feature 1: Goal Date Limit

### 2.1 Change

**File:** `lib/features/goals/presentation/pages/goals_crud_page.dart`

In the `_DateTile` widget's `showDatePicker` call, change `lastDate`:

```dart
// Before
lastDate: DateTime(2100),

// After
lastDate: DateTime(DateTime.now().year + 6, 12, 31),
```

- `firstDate` remains `DateTime(2000)` — unchanged
- Default initial date for new goals (90 days from today) remains unchanged
- No validation message or UI change needed — the calendar simply will not render months beyond the cap
- The cap is evaluated at the moment the picker opens, so it stays accurate as years pass

### 2.2 Edge Cases

| Scenario | Behavior |
|----------|----------|
| Existing goal with date beyond cap | Date is preserved on edit; cap only applies to the picker when editing (user cannot extend further) |
| Picker opened on Dec 31 of cap year | Last selectable date is Dec 31 of that year |

---

## 3. Feature 2: New Dark Theme Presets

### 3.1 New Themes

**Free dark themes (+2):**

| ID | Name | Primary | Background | Feel |
|----|------|---------|------------|------|
| `carbon` | Carbón | `#00C853` | `#1A1A1A` | Electric green on near-black — clean, productivity |
| `indigo` | Índigo | `#536DFE` | `#1C1B2E` | Indigo-blue on deep dark — cool, focused |

**PRO dark themes (+3):**

| ID | Name | Primary | Background | Feel |
|----|------|---------|------------|------|
| `ruby` | Rubí | `#EF5350` | `#1A0A0A` | Ruby red on very dark — bold, premium |
| `amber` | Ámbar | `#FFB300` | `#1C1400` | Amber/gold on dark warm — luxurious |
| `bosque` | Bosque | `#43A047` | `#0A1A0A` | Forest green on deep dark — earthy, calm |

### 3.2 Implementation

**File:** `lib/utils/app_theme_preset.dart`

Each new theme is added to the existing `AppThemePreset.all` list with:
- `id`: unique string
- `name`: display name (Spanish)
- `primary`: primary color hex
- `isDark: true`
- `isPremium: false` for free themes, `true` for PRO themes
- `background` and `surface` colors set from the background column above

The `AppTheme.dark()` factory in `lib/utils/theme.dart` already handles dark `ThemeData` construction — no changes needed there.

**File:** `lib/features/settings/presentation/pages/themes_page.dart`

The themes grid renders all presets from `AppThemePreset.all` dynamically — new presets auto-appear without structural changes to the page. No changes needed unless the grid layout needs adjusting for the increased count.

---

## 4. Feature 3: Dark Theme Rendering Audit

### 4.1 Scope

Full audit of all presentation files under `lib/features/*/presentation/` — pages, widgets, and any custom painters. The goal is to eliminate all hardcoded colors and ensure every visual element adapts correctly when a dark preset (`isDark: true`) is active.

### 4.2 Categories of Fixes

**Category A — Hardcoded color literals**

Any direct use of `Colors.white`, `Colors.black`, `Colors.grey`, `Color(0xFF...)`, or `Color(0x...)` in widget `color:`, `backgroundColor:`, `foregroundColor:`, `style: TextStyle(color: ...)`, or `BoxDecoration` must be replaced with theme-aware equivalents:

| Hardcoded | Theme-aware replacement |
|-----------|------------------------|
| `Colors.white` (backgrounds) | `Theme.of(context).colorScheme.surface` |
| `Colors.white` (text/icons on dark bg) | `Theme.of(context).colorScheme.onSurface` |
| `Colors.black` / dark greys (text) | `Theme.of(context).colorScheme.onBackground` |
| `Colors.grey` (dividers, hints) | `Theme.of(context).colorScheme.outline` |
| Primary-colored items | `Theme.of(context).colorScheme.primary` |
| Scaffold/page backgrounds | `Theme.of(context).colorScheme.background` |

**Category B — Icon colors**

`Icon` widgets without an explicit `color:` inherit from `IconTheme`, which is set per-preset. Any `Icon` with a hardcoded `color:` should use `Theme.of(context).colorScheme.onSurface` (or `primary` if it's an action icon).

**Category C — Specialty widgets**

- **Dashboard cards** (`lib/features/dashboard/presentation/`) — glassmorphism overlays and gradient backgrounds need dark-appropriate opacity/colors
- **Goal and debt cards** — progress bar colors and card surfaces
- **Transaction list items** — amount colors use `FinanceColors` extension (`income`, `expense`) which are already theme-aware; verify contrast ratios are acceptable in dark themes
- **Dialogs and bottom sheets** — `showDialog` and `showModalBottomSheet` surfaces must use `colorScheme.surface`, not hardcoded white
- **Input fields / TextFormField** — `InputDecoration` fill color, border color, hint text color
- **Charts** (if present) — verify axis labels, grid lines, and data series colors are readable

### 4.3 Audit Process

The implementer will:
1. Enable each dark preset one at a time (starting with Noche as the canonical test)
2. Navigate every screen in the app
3. Identify elements with insufficient contrast or wrong color
4. Apply theme-aware fixes
5. Re-verify with all dark presets (Noche, Carbón, Índigo, Medianoche, Galaxia, Cosmos, Rubí, Ámbar, Bosque)

### 4.4 What Does NOT Change

- `ThemeMode` stays `ThemeMode.light` — the app continues to own its theme
- No OS dark mode auto-detection is added
- `FinanceColors` extension values that are already theme-aware are left unchanged
- Light theme rendering is not modified

---

## 5. Files to Modify

### Feature 1 — Goal Date Limit
| File | Change |
|------|--------|
| `lib/features/goals/presentation/pages/goals_crud_page.dart` | `lastDate: DateTime(DateTime.now().year + 6, 12, 31)` |

### Feature 2 — New Presets
| File | Change |
|------|--------|
| `lib/utils/app_theme_preset.dart` | Add 5 new preset entries (2 free dark, 3 PRO dark) |

### Feature 3 — Rendering Audit
| Scope | Files |
|-------|-------|
| All screens and widgets | `lib/features/*/presentation/**/*.dart` |

---

## 6. Out of Scope

- OS-level dark mode auto-detection (ThemeMode stays fixed)
- New light theme presets
- Changes to existing theme colors (only adding new presets, not modifying existing ones)
- Accessibility (WCAG contrast ratio enforcement beyond visual clarity)
- Charts library theming beyond basic color fixes
