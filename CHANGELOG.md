# Changelog

All notable changes to omarchy-ui are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the versions follow [Semantic Versioning](https://semver.org) as [VERSIONING.md](VERSIONING.md) defines it for a vendored kit.

The entries for 1.0.0 are taken from `git log` (the short hashes are the commits). 1.0.0 is the first release: it has no date until it is tagged.

## [Unreleased]

`Tokens.MAJOR` stays 1: every change below is additive.

### Added

- `UField.secret` (bool, default `false`): a masked field for a password prompt. Bullets, no predictive text or history (`ImhSensitiveData`), the accessible name is the label and never the text, and Esc does not revert but is the next layer's at once (the `edit` layer is not joined), which `docs/components.md` documents. `UField.clear()` wipes the typed text. A plain field is unchanged.
- `UButton` icon-only form: `glyph` (the mark, drawn instead of `text`) and `name` (the accessible name and tooltip, required with a glyph; a warning without), `iconOnly` read-only. Same kinds, focus ring and selected rules, a square of `rowHeight` (`controlHeight` for a `link`), at least 24 px. No new class: the one button covers it. A button with no `glyph` is unchanged.
- `URow` list-item form: `icon`, `detail` (a second line), `badge`, `current` (an accent bar and a semibold label) and `listItem`, for a selectable entry with an icon, two lines, a badge and actions in `trailing`. All default off; a row that sets none of them is laid out as in 1.0. Accessible description (detail and badge) and `Accessible.selected` (`current`). The keyboard cursor is the existing `showFocus`.

### Changed

- `UNotice`: the mark's ring takes `theme.radius(height)` instead of a fixed circle, so it follows `host.radiusFor` (or Omarchy's corner radius) like every other shape. With a host radius of 10 or more it is still a circle (the mark is 20 px); on a squarer host it is a rounded or plain square. `dev/tests/kit.mjs` now fails any `radius:` in `ui/` that does not ask the theme.
- `URow`: the click area now sits below the row's slots, so a button or control in the control or `trailing` slot of a `clickable` row gets its own click and the row's `activated()` does not fire for it (in 1.0 the row's area covered them). `hot` is read from a `HoverHandler`, so a `clickable` row stays hovered while the pointer is over its own buttons. A non-clickable row is unaffected.
- `UConfirmSheet` sentences wrap. The 60-character cap and the warning at it are gone; the sentence sits beside the buttons when it fits one line and otherwise wraps over the full width with Cancel and the verb right-aligned under it (`stacked`, read-only). The soft limit is 400 characters (`sentenceMax`), which only logs a warning. Visible difference on a re-sync: a sentence that 1.0 elided with "..." because it did not fit beside the buttons is now shown whole on two or more lines, so that sheet is taller. A sentence that fits is drawn as before. Focus (Cancel first when destructive), Tab order and Esc are unchanged.

## [1.0.0] - 2026-11-21

`Tokens.MAJOR` (`ui/tokens.js`) is 1 for this release.

### Added

The kit and its tests (2026-10-28)

- `tokens.js`: every role colour worked out in the three modes (standalone, hosted-opaque, styled), with text held to 4.5:1 and marks to 3:1, `lift` (the host's `lift` of `plan-surface-v2.md`) and the one WCAG contrast body that omarchy-notch `Bar.qml` has. `spring.js` (the notch's curve), `errors.js` (one error table per plugin, made generic from omarchy-egpu's), `keys.js` (the key map and the Esc order). Node tests for each, over 16 hosts and all 51 installed themes. (376a1a1)
- `UTheme` (not a singleton; the one object every component reads) and `UKeys` (the one place Esc is handled), and the sixteen components `UBack`, `UClose`, `UButton`, `USwitch`, `USegmented`, `UPick`, `UField`, `UStepper`, `URow`, `USection`, `UTip`, `UToast`, `UNotice`, `UEmpty`, `URing` and `UConfirmSheet`. `dev/tests/kit.mjs` (the kit's shape), the qmltestrunner behaviour tests that press real keys through the components, and `dev/lint.sh` (qmllint against the installed Omarchy shell). (f3effba)
- `dev/gallery.qml`, every component in every state on one sheet, and `dev/harness/ui-gallery.qml`, which renders it offscreen in standalone, hosted-opaque and styled modes under a fake `surfaceHost` (radius 10, black or white), counts translucent items and prints the contrast table. `docs/gallery/` holds the five renders. (be278e8)
- The consistency walk, `dev/harness/ui-walk.qml` and `dev/walk.sh`: accessible names, 24 px targets, 11 px text, text contrast measured from rendered pixels, loops under reduced motion, no translucent item in hosted-opaque mode; `dev/fixtures/walk-bad.qml` is a root made to fail each clause. (27a8b8e)
- `dev/sync-ui.sh` (copy the kit, or a subset, into a plugin and write `ui/KIT`), `dev/check-ui.sh` (the consistency gate and its `--score`), `dev/baseline.sh` and `docs/BASELINE.md` (the five plugins' baselines). (63e53cc)
- `dev/test.sh`: lint, node, behaviour, the walk and the gate on fixtures made to fail, the sync round trip with a hand edit and a subset, the marketplace scanner on a fixture with and without the kit, and the gallery in every mode. (6751bd0)
- The README, which defines `OMARCHY_REDUCED_MOTION` (alias `NOTCH_REDUCED_MOTION`) in one place, and the MIT licence. (4f6caff)

Documentation of the top-centre zone (2026-11-20, README only)

- The top-centre zone and the one back control: under the notch the back step is the strip at the top centre, invisible at rest with a chevron on hover; a panel keeps the centre of its top row clear by layout, draws `UBack` only when the host has no such strip, and answers the strip through `goBackInside()` / `canGoBack`. (0d5b0c9, 8aea2c6, af0b376)

The refinements of 2026-11-20 (approved in `decisions-round4.md`, built before the first plugin migrates)

- The named spacing scale: `tokens.js` `SPACING` (`xs` 4, `sm` 8, `md` 12, `lg` 16, `xl` 24, `xxl` 32) and `UTheme.sp.<name>`, each through `Style.space()`; every `space(<n>)` in `ui/` and the gallery uses a name. Both densities kept; rendered pixels unchanged. (b17c031)
- The metadata text role, the third text level in the one monospace face: `roles.metadata` (secondary eased toward the surface and lifted to 4.5:1 on the surface and every fill, opaque, never louder than secondary), `UTheme.metadata` and `metadataWeight` (Light), used by the foot tip, `UNotice` details and `URow.valueQuiet`. (696eb92)
- The warning tone: `roles.warning` (an amber fallback repaired to 4.5:1, or the label in hosted-opaque unless the host hands one over), `UTheme.warning`, and `UNotice` `tone: "warning"` (mark `▲`, spoken "Warning:") beside `info` (`i`) and `error` (`!`, "Error:"). `UToast` has no tones. (c862619)
- `docs/gallery/*.png` regenerated for the three changes above. (b88b2af)

Documentation and release files for 1.0.0 (2026-11-21, no change to `ui/`)

- `VERSIONING.md`, this changelog, `docs/components.md` with a picture of every component in `docs/components/`, `docs/design-principles.md`, `docs/adoption.md`, `docs/migration-checklist.md`, `CONTRIBUTING.md`, `SECURITY.md`, the pull request and issue templates under `.github/`, a refreshed README and `RELEASE-NOTES-1.0.0.md`.
- `dev/render-component.sh`, `dev/specimens.qml` and `dev/harness/ui-component.qml`: one component at a time, a black hosted panel beside a standalone panel, offscreen, with the method of `dev/gallery.sh`.
- `dev/tests/docs.mjs` (run by `dev/test.sh`, also with `--quick`): every relative link and anchor in the markdown resolves, every component in `ui/` has a section in `docs/components.md` and a picture under 150 KB, and every property, signal and handler a `qml` example sets exists in that component's source.

### Fixed

- The README's example for `dev/sync-ui.sh` named no `--to`, which the script refuses when run from the kit (`--from and --to are the same directory`); it now shows `--to .`. Documentation only.

### Deprecated

- `UNotice` `tone: "warn"` is the old name of `"error"`. It still reads as `error` and the default tone is `error`. (c862619)

[1.0.0]: https://github.com/Kalinewb/omarchy-ui/releases/tag/v1.0.0
