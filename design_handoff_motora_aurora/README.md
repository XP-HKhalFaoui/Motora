# Handoff: Motora — "Nocturne Aurora" mobile redesign (variant 2a)

## Overview
Motora is a Flutter + Supabase car-maintenance tracker. This handoff covers a full visual
redesign of its mobile UI, direction **"Nocturne Aurora"** — a light lavender interface built
on the Nocturne design system's blurple accent, with soft white cards, a floating dark pill
navigation bar, and a single hero metric per screen. The organising principle of the whole
product is **"never miss a due date"**: the soonest maintenance/document deadline is the first
thing on the home screen and owns the largest type on it.

Six screens are specified here: Home, Due & reminders, Quick-add sheet, New entry form,
Ledger history, Reports.

Copy language is **French**; units are **km / L / L·100km⁻¹**; currency **EUR**, formatted
French style (`3 148,60 €`, thin-space thousands separator, comma decimal).

## About the Design Files
The files in this bundle are **design references created in HTML** — a prototype showing the
intended look, layout, and behavior. They are **not production code to copy**. The task is to
**recreate these designs in the existing Flutter codebase**, using its established patterns
(widgets, theme, routing, Supabase repositories, state management) rather than porting HTML
structure literally. Where this document and the HTML disagree, this document wins.

Open `Motora - Refonte.dc.html` in a browser. It is a pannable canvas holding three design
directions; the one to implement is the **top row, labelled `2a — Nocturne Aurora`**. The two
rows below it (`1a Nocturne`, `1b Broadsheet`) are rejected alternatives — ignore them.

## Fidelity
**High-fidelity.** Colors, type sizes, weights, radii, spacing, and shadows below are final
and exact. Recreate them pixel-for-pixel in Flutter widgets. Every value in this document is
a literal — no interpretation needed.

The one intentional gap: vehicle photos and scanned-document thumbnails are **placeholders**
in the prototype (dashed/blank slots). In the app they come from Supabase Storage.

---

## Design Tokens

Put these in a single `AuroraTheme` / `AppColors` file and reference them everywhere. Do not
introduce colors outside this list.

### Colors — core

| Token | Hex | Use |
| --- | --- | --- |
| `accent` | `#9184D9` | The only accent. Active nav pill, primary buttons, icons, chart ink, progress fill, links |
| `ink` | `#161826` | Primary text on light ground; also the fill of dark cards and the floating nav |
| `onDark` | `#E9E9ED` | Text/icons on `ink` surfaces |
| `card` | `#FFFFFF` | All card surfaces |

### Colors — derived (precomputed; use these literals)

| Token | Hex | Use |
| --- | --- | --- |
| `bgTop` | `#F8F8FD` | Screen background gradient stop 0% |
| `bgMid` | `#EDEBF9` | Screen background gradient stop 58% |
| `bgBottom` | `#FAF9FD` | Screen background gradient stop 100% |
| `accentTint06` | `#F7F6FC` | Faintest accent wash |
| `accentTint08` | `#F6F5FC` | Quick-add secondary row fill |
| `accentTint12` | `#F2F0FA` | "Linked to" info banner fill |
| `accentTint13` | `#F1EFFA` | Ledger row icon-chip fill |
| `accentTint14` | `#F0EEFA` | Home tile icon-chip fill, accent pill fill |
| `accentTint16` | `#EFEDF9` | Progress-ring track |
| `accentTint22` | `#E7E4F7` | Inactive monthly bars |
| `accentTint24` | `#E5E2F6` | Vehicle photo placeholder gradient (start) |
| `accentTint32` | `#DCD8F3` | Breakdown legend swatch 3 |
| `accentTint45` | `#CEC8EE` | Dashed camera-slot border |
| `accentTint55` | `#C3BBEA` | Breakdown legend swatch 2 |
| `muted` | `#6A6B74` | Secondary/metadata text (11–12px). Meets 4.5:1 on white |
| `mutedSoft` | `#73747D` | Chart axis labels (10px) |
| `hairline` | `#E3E3E5` | Form field underline (inactive) |
| `hairlineStrong` | `#DEDEE1` | Bottom-sheet grab handle |
| `neutralChip` | `#EFEFF0` | Non-accent row icon chip (toll, parking) |
| `iconMutedOnWhite` | `#A2A3A8` | Trailing chevrons |

On `ink` surfaces use white-with-opacity of `onDark`: `onDark @ 62%` for secondary text,
`@ 55%` for inactive nav icons, `@ 26%` for outline-button borders, `@ 14%` for progress
tracks. Accent tints on dark: `accent @ 26%` for icon-chip fills.

### Typography
Single family: **Inter**. Weights used: 400 (regular), 500 (medium), 600 (semibold). No other
family anywhere — no serif, no display face.

| Role | Size | Weight | Notes |
| --- | --- | --- | --- |
| Screen title | 22 | 600 | "Échéances", "Journal", "Rapports" |
| Hero metric | 26 | 600 | Totals, mileage. `tabular figures` |
| Card title / dark-card headline | 18–19 | 600 | |
| Section label | 13–14 | 600 | "Activité récente", "Juillet 2026" |
| List row title | 14–15 | 500 | |
| Body / field value | 15 | 400 | |
| Meta / caption | 11–12 | 400 | color `muted` |
| Chip / badge | 11 | 600 | |
| Axis label | 10 | 400 | color `mutedSoft` |
| Status bar | 12 | 500 | |

**Always enable tabular figures** (`FontFeature.tabularFigures()`) on money, mileage, dates,
litres, and counters.

### Spacing, radii, elevation

- Screen horizontal padding: **18**. Vertical gap between blocks: **13–14**.
- Card padding: **16** (large cards), **12–14** (list rows), **12×8** (count chips).
- Radii: screen frame `36` · large card `26` · standard card `24` · small card `20` ·
  list row `18–20` · icon chip `11–14` · image slot `16` · pill / fully-round `999` ·
  progress bar `3`.
- Shadows (all `BoxShadow`, black-violet, no spread):
  - card soft — `rgba(40,36,80,0.06)`, blur 16, y +4
  - card raised — `rgba(40,36,80,0.07)`, blur 22, y +6
  - dark card / floating nav — `rgba(22,24,38,0.30–0.36)`, blur 34, y +14
  - accent button — `rgba(145,132,217,0.36–0.40)`, blur 26, y +10
  - bottom sheet — `rgba(40,36,80,0.16)`, blur 40, y −8

### Icons
**Phosphor Icons** (`phosphor_flutter`). Regular weight for inactive/secondary, **Fill weight
for anything on an accent or dark surface and for all list-row icon chips**. Icons used:
`house`, `bell`, `bell-ringing`, `receipt`, `chart-line`, `gauge`, `wrench`, `gas-pump`,
`currency-eur`, `file-text`, `drop`, `tire`, `shield-check`, `shield-warning`, `gear`,
`ticket`, `car-profile`, `link-simple`, `camera`, `magnifying-glass`, `funnel`, `export`,
`sliders-horizontal`, `plus`, `x`, `caret-down`, `caret-right`, `arrow-right`.

---

## Global chrome

### Screen background
Vertical-ish linear gradient, 168° (i.e. top-left → bottom-right, nearly vertical):
`#F8F8FD` 0% → `#EDEBF9` 58% → `#FAF9FD` 100%. Applied to the whole scaffold body.

### Floating pill navigation
Present on Home, Due, Ledger, Reports. **Absent** on the New-entry form and behind the
quick-add sheet.

- Positioned `left: 18, right: 18, bottom: 18`, height **64**, radius **32**, fill `ink`,
  shadow "dark card".
- Four equal slots: `house` / `bell-ringing` / `receipt` / `chart-line`.
- Inactive: regular weight, 21px, `onDark @ 55%`.
- Active: a **44×44 circle filled `accent`** with the icon in **Fill** weight at 20px,
  colored `ink`. No labels anywhere in the bar.
- Because the bar floats over content, every scrollable body needs
  `padding.bottom = 96` so the last item clears it.

### Status bar
The prototype draws a fake one (`9:41` + signal/wifi/battery, 12px/500, color `ink`). In
Flutter use the real system status bar with `SystemUiOverlayStyle.dark` and let `SafeArea`
handle the inset.

---

## Screens

### 1. Home — `Accueil`
**Purpose:** answer "is anything due, and what is this car costing me?" in one glance.

Layout: single scrolling column, 18px side padding, 14px gaps, 96px bottom padding.

1. **App bar row** (h 38): leading 38×38 rounded-14 white chip, shadow soft, `car-profile`
   Fill 19px in `accent`. Then a two-line block — "Bonjour Camille" (12, `muted`) over the
   vehicle name "308 SW" (17/600) followed by a 12px `caret-down` in `#A2A3A8`; **tapping
   this block opens the vehicle switcher**. Trailing 38×38 white chip with `bell` 18px and a
   7px `accent` dot badge (2px white ring) at its top-right.
2. **Vehicle photo** — height 132, radius 26, `cover`. Placeholder when absent: gradient
   `#E5E2F6 → #F5F4FB` at 120°. Two overlaid glass pills at the bottom corners
   (`rgba(255,255,255,0.88)`, blur 6, radius 999, padding 5×10, 11/600): plate `AB-123-CD`
   bottom-left, `128 450 km` bottom-right.
3. **Next-due card** — white, radius 24, padding 16, shadow raised. Left column: "Prochaine
   échéance" (12, `muted`) / title (19/600) / "dans 11 jours · 9 août" (12/600, `accent`).
   Right: **72×72 progress ring** — stroke 7, track `#EFEDF9`, progress `accent`, round caps,
   starts at 12 o'clock clockwise, filled proportional to elapsed interval (91% in the mock).
   Centred inside: number (17/600, `ink`) over unit "jours" (9, `muted`).
4. **Stat tiles** — 2×2 grid, gap 10. Each: white, radius 18, padding 12×13, shadow soft, a
   30×30 radius-11 `#F0EEFA` chip with a 15px Fill icon in `accent`, then label (10, `muted`)
   over value (15/600, tabular). Tiles: Coût/km `0,21 €` · Conso. `6,4 L` · Vidange `620 km`
   · Papiers OK `3 / 4`.
5. **"Activité récente"** header (14/600) with "Tout voir" (12/600, `accent`) right-aligned.
6. **Activity rows** (2 shown) — white, radius 18, padding 11×13, shadow soft, gap 9. A
   34×34 radius-12 `#F1EFFA` chip + Fill icon `accent`; title (14/500) over meta (11,
   `muted`); trailing amount (14/600, tabular).

### 2. Due & reminders — `Échéances`
**Purpose:** the unified list of upcoming maintenance **and** expiring documents.

1. Title row: "Échéances" (22/600) + trailing 38×38 white chip `sliders-horizontal`
   (opens threshold settings).
2. **Status counters** — 4-up grid, gap 8, radius 18, padding 12×8, centred. The first
   (*Urgent*) is filled `accent` with white text and an accent shadow; the other three are
   white with shadow soft, count 20/600 `ink`, label 9 `muted`. Labels: Urgent · À surveiller
   · OK · À régler.
3. **Segmented filter** — white pill container, radius 999, padding 4, shadow soft; three
   equal segments 13px. Selected segment: fill `ink`, text `onDark`, weight 600, radius 999.
4. **Urgent hero card** — fill `ink`, radius 26, padding 18, shadow dark. Row: 38×38
   radius-14 chip `accent @ 26%` with `shield-warning` Fill 19px in `accent`; then kicker
   "Urgent" (11, `accent`), title (18/600, `onDark`), meta (12, `onDark @ 62%`). Below: a 5px
   radius-3 progress bar, track `onDark @ 14%`, fill `accent`, at 91%. Below that, two
   actions 14px apart: **"Marquer comme fait"** — flexible, height 44 equivalent (padding
   11), radius 999, fill `accent`, label 13/600 in `ink`; and **"Reporter"** — outline
   `onDark @ 26%` 1px, radius 999, label 13 `onDark`.
5. **Second urgent item** — white card radius 22, padding 14, 34×34 `#F0EEFA` chip with
   `drop` Fill, title 15/500, meta 11 `muted`, trailing "Urgent" pill (11/600, fill
   `#EFEDF9`, text `accent`).
6. **"À surveiller"** label (13/600, `muted`), then rows radius 18, padding 12×13, gap 9:
   *Assurance* (`shield-check`, chevron `#A2A3A8`) and *Plaquettes de frein* (`gear` in a
   neutral `#EFEFF0` chip, trailing outlined "Régler" pill — 1px `accent`, text `accent` —
   which routes to interval setup).

Note: only two "À surveiller" rows fit above the floating nav at 820px design height. On
taller devices show all of them — the list scrolls.

### 3. Quick-add sheet — `Ajouter`
**Purpose:** log anything in one tap from any tab.

Modal bottom sheet over a **dimmed, non-blurred** page: scrim
`rgba(255,255,255,0.72)` tinted 10% `accent`; the page behind drops to 25% opacity. The
floating nav is hidden while the sheet is up.

Sheet: white, radius 30 (top corners; the mock rounds all four with 16–18px insets — in
Flutter use a standard bottom sheet with `borderRadius: vertical(top: 30)`), padding 20×18,
shadow bottom-sheet. Contents: a 38×4 radius-2 `#DEDEE1` grab handle, centred, 16px below it
the title "Ajouter" (19/600) and subtitle "Cinq gestes, depuis n'importe quel écran" (12,
`muted`); then five rows, gap 9.

- **Row 1 — "Relevé kilométrique"** is promoted: fill `accent`, radius 20, padding 12, accent
  shadow; 38×38 radius-14 chip `ink @ 18%` with `gauge` Fill 19px; title 15/600 in `ink`,
  subtitle "Saisie ou photo du compteur" (11, `ink @ 80%`); trailing `arrow-right`.
- **Rows 2–5** — fill `#F6F5FC`, radius 20, padding 12; 38×38 white chip with Fill icon in
  `accent`; single title 15/500; trailing `caret-right` in `#A2A3A8`.
  Réparation (`wrench`) · Plein de carburant (`gas-pump`) · Dépense (`currency-eur`) ·
  Document scanné (`file-text`).

### 4. New entry — `Nouvelle entrée`
**Purpose:** the single form behind all three ledger types; also the target of "Marquer comme
fait", which arrives pre-filled and linked.

Full-screen route, **no bottom nav**, sticky footer button.

1. Header: 38×38 white chip with `x` (closes), then "Nouvelle entrée" (20/600).
2. **Type selector** — white pill, radius 999, padding 4, shadow soft; three equal segments
   with icon + label at 12px. Selected: fill `accent`, text `ink`, weight 600.
   Entretien (`wrench`) / Carburant (`gas-pump`) / Dépense (`currency-eur`).
   Switching type swaps the field set (see below).
3. **Linked-maintenance banner** — only when the form was opened from "Marquer comme fait":
   fill `#F2F0FA`, radius 20, padding 12×14, `link-simple` Fill in `accent`, text 12px:
   "Lié à **Contrôle technique** — l'échéance sera remise à zéro".
4. **Field card** — white, radius 24, padding 16, shadow raised, 14px between fields. Each
   field is a label (11/600, `muted`) above a 15px value with a **1px bottom border only**:
   `#E3E3E5` at rest, **`accent` when focused**. No boxes, no filled inputs.
   - Entretien: Intitulé (full width) · Date + Kilométrage (2-up) · Coût + Garage (2-up), then
     a text action "＋ Nouveau garage" (12/600, `accent`) which opens inline garage creation.
   - Carburant: replace Intitulé/Garage with **Litres** + a **"Plein complet"** switch;
     compute and display L/100 km from the previous full tank once saved.
   - Dépense: Intitulé · Catégorie (assurance, péage, parking, amende, accessoire, autre) ·
     Date · Coût.
5. **Receipt card** — white, radius 24, padding 16. Label "Justificatif" (11/600, `muted`),
   then two 84×100 radius-16 slots side by side (gap 11): the captured scan, and an
   add-affordance — 1.5px **dashed** `#CEC8EE` border, fill `#F7F6FC`, `camera` 22px in
   `accent`.
6. **Sticky footer** — padding 14×18×20, a 52-high radius-26 button filled `accent`, label
   15/600 in `ink`, accent shadow: **"Enregistrer l'entrée"**.

### 5. Ledger — `Journal`
**Purpose:** searchable, filterable history with running totals.

1. Title row: "Journal" (22/600) + two trailing 38×38 white chips: `funnel`, `export`
   (export = the PDF logbook, then the system share sheet).
2. **Search field** — white pill, radius 999, padding 11×15, shadow soft, `magnifying-glass`
   in `#A2A3A8` + placeholder 13px `#A2A3A8`: "Rechercher une entrée…".
3. **Filter chips** — wrap, gap 7, 11px, padding 6×11, radius 999. Active chip: fill `ink`,
   text `onDark`, weight 600. Inactive: white, shadow `rgba(40,36,80,0.06)` blur 10 y+2.
   Chips: type · date range · garage.
4. **Totals card** — fill `ink`, radius 24, padding 16×18, shadow dark. Left: "Total sur la
   période" (11, `onDark @ 60%`) over `3 148,60 €` (26/600, tabular). Right, right-aligned:
   entry count (11, `onDark @ 60%`) over the monthly average (13/600, `accent`).
5. **Month groups** — a header row (month 13/600 `ink`, total 12 `muted` tabular), then rows:
   white, radius 20, padding 12×13, shadow soft, gap 9. 34×34 radius-12 chip — `#F1EFFA` +
   Fill accent icon for fuel/maintenance, `#EFEFF0` + `#6A6B74` icon for neutral expenses.
   Title 14/500; meta 11 `muted` combining date · odometer · derived figure
   (e.g. "24 juil. · 128 300 km · 6,2 L/100"); trailing amount 14/600 tabular.

### 6. Reports — `Rapports`
**Purpose:** cost and consumption over a selectable period.

1. Title row: "Rapports" (22/600) + a white period pill (12/600, padding 8×13, radius 999,
   `caret-down`): "12 mois".
2. **Mileage card** — white, radius 26, padding 16, shadow raised. Header: label 11 `muted` /
   value `128 450` (26/600 tabular) on the left; on the right a pill (11/600, fill `#F0EEFA`,
   text `accent`): "+1 240 / mois". Then a **78px-high area chart**: 2.5px `accent` polyline,
   round caps, a 4px `accent` dot on the last point, and a vertical gradient fill under it
   from `accent @ 34%` to `accent @ 0%`. Three axis labels below (10, `mutedSoft`).
3. **KPI pair** — 2-up, gap 10, white radius 20 padding 14 shadow soft: "Dépense / mois"
   `262,40 €` and "Conso. moyenne" `6,4 L/100`, values 19/600 tabular.
4. **Monthly bars card** — white, radius 26, padding 16. Title 13/600. Row of 8 bars, height
   box 92, gap 7, radius 6, `#E7E4F7`; the **current month is `accent`**. Three axis labels
   below (10, `mutedSoft`).
5. **Breakdown card** — white, radius 26, padding 16. Title 13/600. A single 8px radius-4
   stacked bar (2px gaps between segments) using the accent ladder
   `#9184D9 → #C3BBEA → #DCD8F3 → #EFEDF9`, then a **2-column legend** (gap 9×14, 12px):
   9×9 radius-3 swatch + category + amount (600, tabular).

---

## Interactions & Behavior

- **Navigation:** 4 tabs, state preserved per tab (`IndexedStack` + per-tab `Navigator`).
  Tab switch is a 200ms cross-fade; the active pill slides to the new slot in 220ms
  `easeOutCubic`.
- **Quick add:** invoked from a global action (the prototype shows it as a modal sheet, not a
  FAB, on the Aurora direction — a FAB is acceptable if the codebase already has one).
  Sheet enters 260ms `easeOutCubic` from the bottom, scrim fades 180ms. Dismiss by tap-out,
  swipe-down, or back.
- **"Marquer comme fait":** pushes the New-entry form with type = Entretien, the linked
  maintenance type, today's date, and the last known odometer pre-filled; the linked banner is
  visible. On save, reset the interval and re-forecast.
- **Progress ring / bar:** animate from 0 to target over 700ms `easeOutCubic` on first
  appearance only; never on rebuild.
- **Charts:** the mileage polyline draws left-to-right over 600ms; bars grow bottom-up,
  40ms staggered. Both only on first appearance.
- **Row press:** scale to 0.985 with the shadow reduced one step, 120ms.
- **Urgency thresholds** (drive both the ring color use and the counters):
  urgent ≤ 14 days or ≤ 1 000 km · à surveiller ≤ 60 days or ≤ 5 000 km · OK beyond ·
  "à régler" when a maintenance type has no interval configured. The km thresholds must read
  from the user's configurable mileage-alert setting, not these constants.
- **Empty states:** every list needs one — a 15/500 line plus a 12 `muted` explainer and a
  single accent text action. No illustrations.
- **Loading:** shimmer the card silhouettes at their real radii (`#F0EEFA` → `#F8F8FD`), never
  a centred spinner over an empty screen.
- **Errors / offline:** a `SnackBar` on `ink` with `onDark` text and an `accent` action label.
- **Accessibility:** every tappable target ≥ 44×44 (the 38×38 chips must sit in a 44px
  `InkResponse`). Support text scaling to 1.3× — cards grow, they don't clip. All metadata
  text uses `#6A6B74` or darker on white for 4.5:1.

## State Management
Per screen, the state the UI needs (name it to your existing pattern — Riverpod/Bloc/etc.):

- **Global:** selected vehicle id; vehicle list; unit + locale; theme mode; mileage-alert
  thresholds; notifications enabled.
- **Home:** current odometer, monthly average, cost/km, cost/day, avg consumption, the single
  soonest due item (kind, label, remaining days *and* km, percent elapsed), recent entries
  (limit 2–3), unread reminder count.
- **Due:** counts by status; grouped list of forecasts (maintenance) + documents; active
  filter (`all | maintenance | documents`).
- **Quick add:** sheet visibility only.
- **New entry:** entry type; linked maintenance type id (nullable); title, date, odometer,
  cost, garage id, litres, isFullTank, category, note, attachments; per-field validation;
  `saving` flag.
- **Ledger:** query text, type filter, date range, garage filter; paginated entries grouped
  by month; period total, count, monthly average.
- **Reports:** period (3/6/12/24 months); mileage series; monthly spend series; category
  breakdown; consumption stats.

Data all comes from Supabase (existing repositories). Forecasts and L/100 km are **derived**,
computed client-side from odometer readings and full fill-ups — don't store them.

## Assets
- **Fonts:** Inter 400/500/600 — bundle via `google_fonts` or as a local asset.
- **Icons:** `phosphor_flutter`, regular + fill weights. No custom icon artwork.
- **Images:** none shipped. Vehicle photos and receipt/document scans are user content from
  Supabase Storage; the prototype shows empty placeholder slots where they go. Implement the
  photo placeholder as the `#E5E2F6 → #F5F4FB` gradient described above.
- **No logo** is specified in these screens.

## Files
- `Motora - Refonte.dc.html` — the design canvas. **Implement the top row, `2a — Nocturne
  Aurora`, only.** Rows `1a` and `1b` are rejected directions kept for reference.
- `ds/nocturne.css` — the Nocturne design-system tokens the accent and ink values come from.
- `image-slot.js`, `support.js` — runtime files the prototype needs in order to open. Not
  relevant to the implementation.

### Deviation to be aware of
Nocturne is natively a **dark** system. This direction deliberately carries its accent
(`#9184D9`) and ink (`#161826`) onto a **light** lavender ground. That is intentional and
approved. If the app also needs a dark theme, invert as follows: ground → `#161826`, cards →
`#232532`, text → `#E9E9ED`, accent unchanged, and drop the card shadows in favour of 1px
`rgba(233,233,237,0.16)` borders — that is stock Nocturne.
