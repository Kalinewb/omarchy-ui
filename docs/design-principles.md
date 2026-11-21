# Design principles

The decisions the kit is built on, each with the reason, where it lives in the code, and **how it is held**: by a test, by the gate, or by convention only. Where the code does less than the principle says, this page says so. Version 1.0.0.

Several of these were confirmed on 2026-11-20 when the gallery (`docs/gallery/`) was approved: monospace type, black backgrounds, thin outlines, compact controls, small radii and a theme-driven accent were explicitly kept.

## Look

### 1. One monospace face, with glyphs for icons

- **Why.** The kit has no icon assets and ships no font: the marks are characters of the one family (`‹`, `✕`, `✓`, `▲`, `−`, `+`, `›`), so a plugin has nothing to bundle and every mark takes the text colour and size. One family keeps type quiet next to the notch's own.
- **Where.** `UTheme.fontFamily` is the host's `fontFamily`, else Omarchy's `Commons.Style.font.family`; every `Text` in `ui/` sets `font.family: theme.fontFamily`. Weights: `headlineWeight` and `titleWeight` DemiBold, `metadataWeight` Light, Regular otherwise.
- **Held by.** Convention. The kit does not check that the family is monospace; it takes whatever Omarchy or the host hands over. A face without a Light weight shows Regular.

### 2. Black, OLED-friendly surfaces

- **Why.** The notch is pitch black and the kit's job is to sit on it: no scrim, no blur, no gradient, no shadow. Depth is a faint tint of the label colour over the surface, not a lighter slab.
- **Where.** The kit does not paint a black background of its own; the surface is `host.color` (hosted) or Omarchy's background (standalone), and `tokens.js` `roles()` builds the levels from it: level 0 the surface, `fill` 4 %, `hover` and `raised` 8 %, `selected` 18 %, `pressed` 22 % (`ALPHA`), each capped so the label on it keeps 4.5:1. `raised` (a tip, a toast, an open pick) is a solid colour in every mode because it floats over content. `ui/` has no shadow, blur or gradient (grep it).
- **Held by.** `dev/tests/contrast.mjs` (every role pair on 16 hosts and every installed theme); the gallery's black and white hosts.

### 3. Thin outlines

- **Why.** A hairline defines a control without adding weight or a fill, which suits a black surface. The 2 px line is kept for the keyboard focus ring.
- **Where.** `tokens.js` `HAIRLINE` (1 px), `UTheme.hairlineWidth`; the `hairline` role is the label at 40 % or the least alpha that clears 3:1 on the surface, whichever is more (a 25 % ring is about 1.6:1 on black). Every border, ring, track, knob and arc declares `uiMark: true`.
- **Held by.** The contrast gate (`hairline on surface`, `focus ring on surface`: 3:1, in every mode).

### 4. Compact controls

- **Why.** A notch panel is narrow (a settings panel budgets 30 px rows and 12 px body), and a keyboard-first desktop needs no touch targets.
- **Where.** `tokens.js` `DENSITY`: row 30 px with body 12 in the notch, 32 px with 13 standalone; `UTheme.rowHeight`; form controls (`UField`, `UStepper`, `UPick`, `USegmented`) are `controlHeight`, 4 px shorter than the row, so a row holds them. `MIN_HIT` is 24 px; the switch track is 22 by 42. Density changes the row height only; there are no other fixed heights.
- **Held by.** The walk: every focusable item at least 24 px, a primary button at least the row height, no text under 11 px.

### 5. Small radii, from the host

- **Why.** One radius runs through the surface: the notch's (`radiusFor`), or Omarchy's corner radius standalone, never more than half a control's height. The kit has none of its own.
- **Where.** `tokens.js` `radius(hostRadius, h)` and `UTheme.radius(h)`; every `Rectangle` in `ui/` takes `radius: theme.radius(height)`.
- **Held by.** The gate fails `radius: <digit>` outside `ui/`, so a plugin cannot hard-code one.

### 6. A theme-driven accent, used sparingly

- **Why.** Most controls are not coloured; the accent marks what is active or selected, so there is at most one colour on the page and it means something. The colours follow Omarchy's themes (and the OLED forks of them); a fixed palette would not.
- **Where.** The accent is used for: the primary button's outline and the chosen segment's outline of `USegmented` (selected); the on track of `USwitch` (active); link text and the `✓` of the chosen row of `UPick` (`accentText`); the arc of `URing` (progress); the selection colour of `UField`. It comes from `Commons.Color.accent` standalone and styled, and from `host.accent` hosted; the notch's accent is its foreground, so on the notch nothing is coloured. It is repaired to 3:1 as a mark and to 4.5:1 as text. **The focus ring is not the accent**: it is the label colour at an alpha that clears 3:1.
- **Held by.** The contrast gate (`accent mark`, `accent text`). Using it sparingly is convention.
- **A fallback, not a theme colour.** Omarchy has no yellow, so `warning` is an amber default (`tokens.js` `WARNING_DEFAULT`) unless the host hands one over.

### 7. Three text levels in one face

- **Why.** Hierarchy by colour and weight, not by size and not by a second face: primary for what a row is called, secondary for values, captions and section titles, metadata for tips, codes and small print.
- **Where.** `UTheme.label`, `UTheme.secondary` and `UTheme.metadata` with `metadataWeight` (Light). `metadata` is secondary eased 40 % toward the surface, lifted to 4.5:1 on the surface and every fill, and never louder than secondary. Used by the foot tip, the Details line of `UNotice` and `URow` with `valueQuiet`.
- **Held by.** `contrast.mjs` (`metadata on surface`, `metadata on fill`, "never louder than secondary").
- **A limit.** On a theme whose secondary already sits near 4.5:1 the colour step is small (a few hundredths of a ratio on most stock themes, a real step on a black host) and the weight carries the rest.

### 8. A named spacing scale

- **Why.** One short list of gaps keeps panels on one rhythm, and it follows the user's spacing setting.
- **Where.** `tokens.js` `SPACING`: `xs` 4, `sm` 8, `md` 12, `lg` 16, `xl` 24, `xxl` 32; `UTheme.sp.<name>`, each through `Style.space()`. Both densities use it. `space(n)` stays for a value that is not on the scale.
- **Held by.** `dev/tests/kit.mjs` for `ui/` (no `space(<n>)` literal, every `theme.sp.<name>` on the scale). The gate does **not** check a plugin's margins; it is convention there.

## Behaviour

### 9. Destructive actions: red, a verb and an object, and a confirmation

- **Why.** A destructive action should be recognisable by wording and position as well as colour, and must not be the one Enter lands on.
- **Where.** `UButton` `kind: "destructive"`: the quiet shape with a hairline, in the `destructive` colour. Red only where the panel owns its colours (standalone, styled); in hosted-opaque it is the label colour, so wording and position carry it (`tokens.js`: `destructive = opaque || urgent === undefined ? label : ...`). `UConfirmSheet` is the inline confirm: one sentence of at most 60 characters naming the consequence, then Cancel and the verb. With `destructive: true` Cancel takes the initial focus and Enter does not fire the verb; any other verb takes the focus, so Enter confirms. Esc is Cancel.
- **Held by.** Behaviour tests in `dev/tests/qml/tst_kit.qml` for the focus and Esc. The wording ("Remove Ana", not "OK") and "last in the row, never the default" are convention; the gate only fails the banned dismiss words (Close, Keep, Later, Dismiss, OK, Okay).

### 10. Dismiss words: Cancel, Done, Not now

- **Why.** Three words, each meaning one thing: Cancel abandons, Done finishes, Not now defers. Action verbs are an open set ("Remove Ana", "Install Face ID") plus "Try again" and "Undo".
- **Where.** `UConfirmSheet` (Cancel), `UToast` (Not now).
- **Held by.** The gate (`dev/check-ui.sh` rule 4), by exact match on a label.

### 11. Feedback: three notice tones, a toast, a confirm and progress

The notice has **three** tones; feedback as a whole has four kinds.

- **Why.** A saved toast should not weigh what a camera failure weighs. Each kind has its own shape: `UToast` is a solid raised line with at most one action and "Not now" (6 s without an action, paused on hover and focus); `UNotice` is an inline filled box with a ringed glyph (`info` `i`, `warning` `▲`, `error` `!`) and a spoken word ("Warning: ", "Error: "), so the state never rests on colour alone; `UConfirmSheet` replaces the action row in place; `URing` is progress (determinate or a 900 ms indeterminate turn).
- **Where.** The four components. The sentence in a notice comes from the plugin's own table (`errors.js`); an unknown code reads "Something went wrong." and the code shows only under Details.
- **Held by.** `dev/tests/kit.mjs` (the tones and their glyphs), `tst_kit.qml` (the marks and names). In hosted-opaque the error colour is the label, and so is the warning colour unless the host hands one over, so there the glyph and the word carry it.

### 12. Focus and selection look different

- **Why.** A keyboard ring and a chosen item answer different questions, and one must not stand in for the other (a row that is only *focused* must not look *chosen*).
- **Where.** Focus is the 2 px `ring` border (`showFocus`). Selection is the `selected` fill with an accent hairline and semibold text (`UButton` primary, the chosen segment of `USegmented`). The gallery's state strips and `docs/components/` show both. In a list a selected row is marked with its own mark (the Corners panel, on its unmerged `ui-kit` branch, uses an accent bar in the margin), not by the ring.
- **Held by.** Convention and the pictures; no test compares them.

### 13. One back, one close

- **Why.** Two ways back or two close glyphs make people guess.
- **Where.** `UBack` (the chevron, "Back" as tooltip and name) and `UClose` (the one `✕` at the top right). Esc goes back one step and, at the root, closes (`UKeys`). A cross on a chip or a row removes that item; it is not `UClose`. In the notch the back step is the strip at the top centre, and `UBack` is not drawn there.
- **Held by.** Convention, and `dev/check-ui.sh --score` reports the Back and Close classes. The gate only fails raw `Key_Escape` and `onEscapePressed`.

### 14. A keep-clear zone at the top centre, in the notch

- **Why.** The notch's back strip is an invisible hit area at the top centre of every panel (`surfaceHost.backZoneWidth` by `backZoneHeight`, 180 by 32 by default); a control or text under it would be covered.
- **Where.** The zone belongs to the notch. The kit's part is to draw no back of its own there, and the README describes what a panel must do: keep the centre of its top row clear by layout, title left and buttons right. The check is the notch's `notch backZone` command, which lists the controls and texts inside the zone.
- **Held by.** Not by this repo's gate or tests. A plugin's suite should assert the two lists are empty for each route (the Corners plugin has `dev/panel-zone.sh`).

### 15. Every colour opaque in hosted mode

- **Why.** The notch's surface contract 1 forbids a translucent item, gradient or blur in a hosted panel, so a panel stays legible on the notch's black without it knowing what is behind.
- **Where.** `tokens.js` `roles()`: in `hosted` mode `tint()` is `mix()`, a computed solid, never an alpha; `raised` and `disabled` are solid in every mode.
- **Held by.** The walk (`opaque`: not one translucent item in hosted mode) and `dev/test.sh` (the gallery counts translucent items: zero on the black and white hosts).

### 16. Reduced motion

- **Why.** Motion that carries no information can be turned off.
- **Where.** `OMARCHY_REDUCED_MOTION=1` in the environment (`NOTCH_REDUCED_MOTION=1` as an alias), or `host.reducedMotion`; `tokens.js` `reducedFrom` and `UTheme.reduced`. With it on every duration that moves something is 0, `press` and `stagger` are off, fades stay, and the indeterminate ring stops on a steady half arc. The README is its one definition (`OMARCHY_` is only a prefix, not an Omarchy variable).
- **Held by.** The walk: with reduced motion on, no running looped `Animation` (declared, and two renders 300 ms apart identical); checked in two of the walk's seven configurations.

### 17. Contrast is a gate

- **Why.** Legibility on every host and theme should not depend on someone looking.
- **Where.** `tokens.js`: text is held to 4.5:1 and every mark to 3:1, in every mode, on every host. `roles()` repairs what it is handed with `lift` (the same vectors as the host's) instead of trusting it, and caps each fill so the text on it keeps its floor; on a mid-tone host where nothing else can reach it a role falls back to the label. Disabled text is exempt (WCAG 1.4.3).
- **Held by.** `dev/tests/contrast.mjs` (57 checks: every pair, every mode, 16 hosts, every installed theme, and against omarchy-notch's `Bar.qml` when a checkout is beside this one); the gallery's printed table; the walk measures text contrast from rendered pixels.

### 18. Motion: springs for what arrives, short eases for controls

- **Why.** A spring suits a thing that grows or arrives; a colour or an opacity should not overshoot.
- **Where.** `tokens.js` `MOTION`: `arrive` (damping 0.72, 350 ms, about 3.8 % overshoot, used by `UToast`'s rise), `control` (0.85, 200 ms, about 0.6 % overshoot, so a settle rather than a bounce: the `USwitch` knob and the `UButton` press release), `celebrate` (0.60, 450 ms, about 9.5 %, one use), `exit` (OutCubic 180 ms), fades (out 90, in 150), `press` (scale 0.97 over 60 ms), `focus` (colours, 90 ms), `stagger`. `spring.js` samples the closed-form spring into a Bezier spline. Never on a colour or an opacity: those use `OutCubic` or a plain `ColorAnimation`.
- **Held by.** `dev/tests/spring.mjs` (the overshoot each damping gives, the curve landing on 1). The shape of the notch itself, where springs matter most, is the notch's. `celebrate` and `staggerDelay` are defined but no component in 1.0.0 uses them.

### 19. One key map, one place for Esc

- **Why.** Esc should mean the same thing everywhere: close, in order, an edit, a tip, an open pick, a modal, then go back, then close.
- **Where.** `ui/keys.js` (`action`, the layer order, the registry) and `ui/UKeys.qml`. See [components.md](components.md#ukeys).
- **Held by.** `dev/tests/keys.mjs` and `tst_kit.qml` (real key presses through the components); the gate fails `Key_Escape` and `onEscapePressed` outside `ui/`.

### 20. Vendored, copied and checked

- **Why.** A plugin install is one `git clone`: no symlinks, no cross-plugin import, no network at run time. The cost (the kit copied into each plugin) is answered by a hash.
- **Where.** `dev/sync-ui.sh` (copy only) and `ui/KIT`; `dev/check-ui.sh` rule 1. See [VERSIONING.md](../VERSIONING.md).
- **Held by.** `dev/test.sh` (the sync round trip, a hand edit, a stray file, a subset, the marketplace scanner on a fixture).

## What the kit does not decide

A light theme (dark only; the white-host renders exist to prove the roles, not to ship one), gestures and 44 px targets (the minimum is 24 px), notification buttons in the notch toast, and anything about a plugin's own layout beyond the keep-clear zone.
