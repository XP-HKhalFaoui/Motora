# Prompt for Claude Code

Paste the block below into Claude Code, from the root of the Motora repository, with this
handoff folder available (drop it in the repo, e.g. `docs/design_handoff_motora_aurora/`).

---

I'm redesigning the UI of this Flutter + Supabase app (Motora, a car-maintenance tracker).
The full design specification is in `docs/design_handoff_motora_aurora/README.md`. Read it
completely before writing any code — it contains exact colors, type sizes, spacing, radii,
shadows, animation timings, and per-screen component breakdowns. It is high-fidelity: treat
every value in it as literal.

There is also an HTML prototype in that folder (`Motora - Refonte.dc.html`). It's a design
reference, not code to port. It's a pannable canvas with three directions — **implement only
the top row, labelled `2a — Nocturne Aurora`**; the rows below it are rejected alternatives.

Work in this order and stop for my review after each step:

1. **Survey first.** Map the existing code: theme/tokens, navigation, widget conventions,
   state management, Supabase repositories and models, l10n setup. Tell me what you found and
   how the redesign maps onto it — which screens already exist, what needs to be created, and
   anything in the spec that conflicts with the current architecture. Don't write UI yet.
2. **Theme layer.** Implement the design tokens from the spec as a single source of truth
   (colors, text styles with Inter 400/500/600 and tabular figures where specified, radii,
   shadows, the screen background gradient). Add `phosphor_flutter`. Then add a scratch
   gallery route that renders every token and every shared widget so I can eyeball it.
3. **Shared widgets.** Build the reusable pieces the spec keeps reusing: the soft white card,
   the list row with its icon chip, the count chip, the pill segmented control, the filter
   chip, the accent primary button, the dark hero card, the 38×38 app-bar chip (in a 44px
   tap target), the progress ring, the floating pill nav bar, and the image/receipt slot.
   Match the spec's exact values. Keep them dumb and stateless.
4. **Screens, one at a time**, in this order: Home → Due → Quick-add sheet → New entry →
   Ledger → Reports. Wire each to the real repositories; no mock data left behind. Reuse the
   existing state-management pattern — don't introduce a new one.
5. **Behavior pass.** The animations, press states, urgency thresholds (read from the user's
   configurable mileage-alert setting, not hardcoded), empty states, shimmer loading states,
   and error snackbars described in the spec.
6. **Polish pass.** Verify 44px minimum tap targets, text scaling to 1.3× without clipping,
   4.5:1 contrast on all metadata text, French copy and number formatting exactly as written
   in the spec (`3 148,60 €`, `6,4 L/100`, thin-space thousands), and 96px bottom padding on
   every scroll view that sits under the floating nav.

Constraints:

- Use the codebase's existing patterns and libraries. Don't add dependencies beyond
  `phosphor_flutter` and a font package without asking me first.
- Don't invent colors, sizes, or spacing. Every value comes from the spec; if something isn't
  covered, ask instead of guessing.
- Don't refactor unrelated code, and don't touch the Supabase schema.
- Keep all copy in French and route it through the existing l10n setup if there is one.
- Screens must fit above the floating nav bar without clipping — the spec notes exactly where
  content was tightened to make that work.

Start with step 1.
