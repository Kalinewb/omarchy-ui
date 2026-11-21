# Migration checklist

A tick-list for moving a plugin onto omarchy-ui 1.0. Copy it into the migration's pull request and tick as you go. Each item says where to read more in [adoption.md](adoption.md). The lessons marked *(Corners)* come from the OLED Corners migration, a branch `ui-kit` (commits `f216e1e` to `29c0b51`) that is **not merged**.

## Before you touch the plugin

- [ ] The plugin's own checks pass on the **unchanged** panel: a lint, a render, a key test (adoption 2). *(Corners: the first commit added exactly these, green on the old panel.)*
- [ ] The kit checkout is at a release tag and clean: `git -C ../omarchy-ui describe --tags` and `git -C ../omarchy-ui status --porcelain -- ui dev` (adoption 1).
- [ ] A baseline score and counts, from the commit as it is: `../omarchy-ui/dev/check-ui.sh --repo . --ref HEAD --score` and `--counts --no-walk` (adoption 2). Paste the two into the PR.
- [ ] "Before" pictures rendered offscreen from the commit before the kit, on a stand-in host, black and white and standalone (adoption 10). Render them now: afterwards the old panel is gone.
- [ ] The scope is the view layer: no change to the service, the manifest ids or capabilities, the settings keys or the IPC targets.

## Vendor

- [ ] `../omarchy-ui/dev/sync-ui.sh --from ../omarchy-ui --to . --tools [--only ...]` (adoption 3). Note the flags in the commit message: the next sync needs the **same** ones.
- [ ] `head -n 2 ui/KIT` shows the release's sha and `major 1`.
- [ ] `ui/` and the five tool files are committed **together**, in a commit of their own, and nothing else is in it.
- [ ] `./dev/check-ui.sh --no-walk` passes the hash line (`ui/ matches ui/KIT`).

## Build

- [ ] One `UTheme { host: ... }` at the root, `theme: theme` passed down, `UKeys` around the page (adoption 4).
- [ ] Every private control replaced (the table in adoption 5): switch, button, field, stepper, pick, choice, confirm, tip, row, section, spinner, notice, toast, empty.
- [ ] No literal `pixelSize`, `"#hex"`, `Qt.rgba(`, `radius:` or `duration:` outside `ui/`; margins and gaps are `theme.sp.<name>`. A literal that must stay carries `// ui-allow: <reason>`. *(Corners: the two pure-black defaults.)*
- [ ] Dismiss words are Cancel, Done, Not now; destructive actions are verb plus object, last, never the default, and go through `UConfirmSheet` unless undo exists.
- [ ] Esc is only in `UKeys`: no `Keys.onEscapePressed`, no `Key_Escape`.
- [ ] **Selection and focus are different things.** The keyboard ring is focus; a selected row, tab or choice has a mark of its own (the kit's selected fill with an accent outline for a control; for a row, a mark beside the text). *(Corners: the selected row got an accent bar in the margin, so it reads without the ring.)*
- [ ] **Contrast on fills.** Only the label is guaranteed 4.5:1 on `selected` and `pressed`; `secondary` and `metadata` text only on the surface, `fill`, `hover` and `raised`. No quiet text on a selected row's fill. *(Corners: a fill under the selected row failed the gate on the "Following" value.)*
- [ ] **Metadata text on a fill needs 4.5:1**, like all text. The kit holds `metadata` to it on the surface, `fill`, `hover` and `raised` (`tokens.js` `pairs()`); a `valueQuiet` value or `theme.metadata` text on a `selected` or `pressed` fill, or on a fill of your own, is outside what the kit guarantees, and the walk measures it from the rendered pixels and fails it. Move the mark beside the text, or use the label colour.
- [ ] Under the notch: the centre of the top row is clear by layout, `UBack` and "esc" hints only without a `panelBack` strip, `goBackInside()` answers the strip, nothing is pushed down (adoption 6). Tips use `placement: "foot"` and one `UTip { line: true }` on the page.
- [ ] Every focusable control has a name, every target is 24 px or more, no text is under 11 px (the walk checks these).
- [ ] Any animation of your own follows `theme.reduced`.

## Gate and tests

- [ ] `./dev/check-ui.sh --score --walk <root.qml>` exits 0: the static rules and the walk's seven configurations (adoption 8).
- [ ] If the root shows too little, `dev/walk-root.qml` stands in a model and shows every row, button and notice, including the broken and empty states, and `./dev/check-ui.sh --walk dev/walk-root.qml` exits 0.
- [ ] Key tests under `qmltestrunner` with the kit's theme swapped for the stub, pressing real keys and checking what the panel asks for (adoption 9). The same keys write the same settings as before.
- [ ] `dev/tests/stub-surface.mjs`: every `theme.<name>` read is in the stub and in `UTheme.qml`.
- [ ] The plugin's `dev/test.sh` runs lint, the tests, the gate and the walk in one command and prints one summary.
- [ ] **Never commit while the gate is red.** If a rule fails and the fix is in `ui/`, stop: fix it in omarchy-ui, release, re-sync. Do not edit the copy.

## Pictures and docs

- [ ] "After" pictures from the same harness and the same stand-in host as the "before" ones (adoption 10), compressed (`magick in.png -strip out.png`), under the plugin's `docs/`.
- [ ] README: *no external dependencies at run time; ui/ is vendored from omarchy-ui*, the *Reduced motion* paragraph, the dev commands.
- [ ] The plugin's version and changelog say what a person will notice.

## Release hygiene

- [ ] The marketplace scanner or preflight on the pushed commit: the verdict and capabilities match the commit before (adoption 11).
- [ ] `git diff --stat -- ui dev` against the previous commit shows only what you meant to change.
- [ ] The PR lists the `// ui-allow` lines the gate printed.
- [ ] After merge, note the kit release in the plugin's changelog, so `head -n 2 ui/KIT` has a tag to go with it (VERSIONING: `git tag --contains <sha>`).
