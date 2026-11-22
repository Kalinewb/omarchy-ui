# omarchy-ui

The shared UI kit for the kalinewb Omarchy plugins (notch, profiles, face, corners, egpu): one set of tokens, motion and controls, so every plugin looks and behaves the same. One back, one close, three dismiss words, one switch, one confirm, one key map. **Version 1.0.0** ([CHANGELOG](CHANGELOG.md), [VERSIONING](VERSIONING.md)). MIT.

**What it is.** A folder of QML components (`ui/`), the pure-JavaScript logic behind them (colour roles held to contrast floors, the key map, the spring curve, an error table), and the tools that go with it: a sync script, a consistency gate and an offscreen render harness. Eighteen QML files: a theme, a key router and sixteen components, from a button to a confirm row.

**What it is not.** It is **not a plugin**: there is no `manifest.json`, and it is never listed or installable. It is not a dependency you install or import from somewhere else: each plugin **copies `ui/` into its own repo** with `dev/sync-ui.sh` (no symlinks, no cross-plugin imports, installs stay one `git clone`) and keeps the copy unedited, which a gate checks by hash. It is not a light theme, a gesture toolkit or a design system for apps other than Omarchy shell plugins.

![standalone](docs/gallery/standalone.png)

## Quick start

```sh
git clone https://github.com/Kalinewb/omarchy-ui ../omarchy-ui && git -C ../omarchy-ui checkout v1.0.0     # in your plugin's repo
../omarchy-ui/dev/sync-ui.sh --from ../omarchy-ui --to . --tools --only UButton,URow,USwitch,UKeys     # or no --only for all of ui/
# in your QML: import "ui" / UTheme { id: theme; host: surfaceHost } / UButton { theme: theme; text: "Done" }
./dev/check-ui.sh --walk Panel.qml                                                                       # the gate, with the walk on your root
# then: docs/adoption.md, and tick docs/migration-checklist.md
```

## Three modes

| mode | when | colour |
|---|---|---|
| **standalone** | `host` is null | Omarchy's palette (`Commons.Color`), alpha fills |
| **hosted-opaque** | `host` set, `host.styled` not true (surface contract 1) | only what the notch hands over (`color`, `foreground`, `secondary`, `accent`), every colour a computed **solid**: never a translucent item, gradient or blur |
| **styled** | `host.styled === true` (contract 2) | the kit's own roles and alpha fills over the host's surface; when the notch's guard falls back, `styled` goes false and the same bindings give hosted-opaque by themselves |

`host` is any `surfaceHost`-shaped object (`color`, `foreground`, `secondary`, `accent`, `radiusFor(size)` or `radius`, `fontFamily`, optionally `styled`, `reducedMotion` and `warning`). Density follows: **notch** rows are 30 px with 12 px body, **standalone** 32 px with 13; both use the one spacing scale below.

![hosted, black](docs/gallery/hosted-black.png)

## Documentation

| | |
|---|---|
| [docs/components.md](docs/components.md) | every component: properties, signals, keys, roles, an example and a picture ([docs/components/](docs/components/)) |
| [docs/design-principles.md](docs/design-principles.md) | the decisions, each with its reason, where it lives in the code and how it is held |
| [docs/adoption.md](docs/adoption.md) | adopting the kit in a plugin, step by step |
| [docs/migration-checklist.md](docs/migration-checklist.md) | the tick-list a migration follows, with the lessons of the first one |
| [VERSIONING.md](VERSIONING.md) | semver for a vendored kit, what is breaking, how `ui/KIT` and `Tokens.MAJOR` relate, how a plugin updates |
| [CHANGELOG.md](CHANGELOG.md) | what changed |
| [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md) | proposing a component and the gate; what the kit can and cannot do, and how to report |
| [docs/BASELINE.md](docs/BASELINE.md) | where the five plugins stood before adopting it |
| [docs/gallery/](docs/gallery/) | every component in every mode on one sheet |

## Using it, in more detail

```sh
# in a plugin repo, once, with a local checkout of this repo beside it (--to . is the plugin)
../omarchy-ui/dev/sync-ui.sh --from ../omarchy-ui --to . --tools                              # all of ui/, and the gate's scripts
../omarchy-ui/dev/sync-ui.sh --from ../omarchy-ui --to . --tools --only UButton,URow,USwitch  # or a subset (what they use comes too)
./dev/check-ui.sh --walk Panel.qml                                                           # the gate, with the walk on this root
# later: ./dev/sync-ui.sh --from ../omarchy-ui, with the same flags (the script is now in the plugin, so --to defaults to it)
```

```qml
import "ui"

Item {                                   // the plugin's root
  UTheme { id: theme; host: surfaceHost }   // once; host is null for a standalone window
  UKeys {                                    // the one place Esc is handled
    anchors.fill: parent; focus: true
    level: "back"; open: depth > 0; onEscaped: goBack(); onCloseRequested: root.closeRequested()
    URow { theme: theme; label: "Show the date"; USwitch { theme: theme; label: "Show the date"; checked: on; onToggled: on = !on } }
  }
}
```

`UTheme` is not a singleton (a singleton cannot see a plugin's `surfaceHost`); it is passed down as `theme: theme`, and every component declares `required property var theme` and reads nothing else. The `U` prefix is mandatory: a bare `Row`, `Button` or `Switch` collides with QtQuick, QtQuick.Controls and `qs.Ui`, where the last import wins.

`ui/KIT` (written by the sync, never by hand) holds `omarchy-ui <40-hex sha of the checkout's HEAD>`, `major <n>`, and a sha256 per copied file. `dev/check-ui.sh` fails if a listed file was edited or an unlisted file sits in `ui/`: a fix goes here, then a re-sync. The sync is copy-only: it never clones, fetches or pulls, and never runs anything from the checkout, so the marketplace scanner has nothing to ask about (`dev/test.sh` runs the scanner on a fixture with and without it). It refuses a checkout with uncommitted changes under `ui/` or `dev/`, so the sha always describes what was copied.

## What is in `ui/`

| class | component | |
|---|---|---|
| Back | `UBack` | chevron left of the title, "Back" tooltip and name. In the notch (a host with `panelBack`) the back step is the top-middle strip and Esc its alias, so this is not drawn there; see *Layout: the top-centre zone* |
| Close | `UClose` | the one `✕`, top-right |
| Buttons | `UButton` | `primary` (one per surface), `quiet`, `destructive` (verb + object, last, never default), `link` (the `flow` variant); an icon-only form (`glyph` + `name`) for rows of actions |
| Switch | `USwitch` | 22 x 42 track in a 24 px target |
| Pick | `USegmented` (2 to 4), `UPick` (3 or more) | |
| Field | `UField` (Enter commits, Esc reverts; `secret: true` masks it and Esc cancels at once), `UStepper` (`-` / `+`, Left / Right) | |
| Row, section | `URow` (`row` and `stacked`, a `trailing` slot), `USection` | |
| Tip | `UTip` | `float` (a box) or `foot` (one reserved line, no box) |
| Toast, notice | `UToast`, `UNotice` | `UNotice` has three tones: `info` (`i`), `warning` (`▲`) and `error` (`!`, the old `warn`), each a glyph and a spoken word as well as a colour; `UToast` has no tones. A code never reaches the surface; unknown codes read "Something went wrong." |
| Empty, progress | `UEmpty`, `URing` | the ring is determinate or indeterminate, and holds still under reduced motion |
| Confirm | `UConfirmSheet` | an inline row that replaces the action row, never an overlay |
| Keys | `UKeys`, `keys.js` | Esc closes, in order: an edit, a tip, an open pick, a modal, then goes back, then closes |
| | `UTheme`, `tokens.js`, `spring.js`, `errors.js` | roles, density and motion; the springs; one error table per plugin |

**Layout: the top-centre zone.** Under the notch there is one back control, the strip at the top centre of every panel (`surfaceHost.backZoneWidth` by `backZoneHeight`: the resting notch's footprint, 180 by 32 by default). The whole zone is the press target and it sits above the panel. At rest it is invisible; under the pointer a small chevron fades in at its centre (no pill, border, box or wash; the pointer becomes a hand), and Esc is its invisible alias. The host does **not** push a panel down for it, so a panel built from this kit (1) keeps the *centre* of its top row clear by layout, title left and buttons right, so that no button, `MouseArea`, `TapHandler` item, field, tab stop **or text** is inside the zone (a header narrower than three zones starts its first row below `backZoneHeight` instead); (2) draws `UBack` and any "esc goes back" hint only when the host has no such strip (`host.features` lacks `panelBack`), and keeps a hint only for what Esc does that is not obvious ("esc stops the check"); (3) answers the strip through `goBackInside()` / `canGoBack`. `notch backZone` lists every control (`hits`) and text (`texts`) of the open panel inside the zone, and a panel's suite should assert both lists are empty for each route.

**Dismiss words** are three: **Cancel** (abandon), **Done** (finish), **Not now** (defer). "Close", "Keep", "Later", "Dismiss", "OK" and "Okay" are out. Action verbs are an open set and are not dismiss words ("Remove Ana", "Install Face ID"), plus the named recoveries "Try again" and "Undo".

**Colour.** Text is held to 4.5:1 and every mark (a border, ring, track, knob or arc, each declaring `uiMark: true`) to 3:1, in every mode, on every host: `tokens.js` repairs what it is handed with `lift` (the host's `lift` of `plan-surface-v2.md`, same vectors) and caps each fill so the text on it keeps its floor. Hairlines and the focus ring are raised to 3:1 (a 25 % ring is about 1.6:1 on black). The **warning** role (`theme.warning`, amber) is worked out like the others and held to 4.5:1 on the surface, hover and fill; it is amber only where the panel owns its colours (standalone, styled, or a host that hands one over), and the label in hosted-opaque, as for destructive, so the glyph and the word carry it there. `contrast` is the one WCAG body that `Bar.qml` in omarchy-notch has; the test compares them. Destructive is red only where the panel owns its colours.

**Spacing.** One named scale for both densities: `theme.sp.xs` 4, `sm` 8, `md` 12, `lg` 16, `xl` 24, `xxl` 32 (`tokens.js` `SPACING`), each through `theme.space()` so it follows the user's spacing scale. Margins, gaps and insets use the names; `space(n)` stays for a value that is not on the scale. Density changes the row height only (30 notch, 32 standalone); there are no other fixed heights.

**Text.** Three levels in the one monospace face. *Primary* is `theme.label` (headlines are `headlineWeight`). *Secondary* is `theme.secondary`: values, captions, section titles. *Metadata* is `theme.metadata` with `metadataWeight` (Light): tips on the foot line, codes under Details, small print (`URow.valueQuiet`). `metadata` is secondary eased toward the surface and lifted to the same 4.5:1 on the surface and every fill, so it is never louder than secondary, but on a theme whose secondary already sits near 4.5:1 the colour step is small and the weight carries the difference. A face with no Light weight shows Regular. `MIN_TEXT` (11 px) still holds for all three.

**Motion.** `arrive` 0.72 / 0.6 / 350 ms (anything that grows; 3.8 % overshoot), `control` 0.85 / 0.55 / 200 ms, `celebrate` 0.60 / 450 ms (one use), `exit` OutCubic 180 ms, `fade` out 90 / in 150, `press` scale 0.97 over 60 ms, `stagger` 40 ms capped at 240. Springs only for what arrives; never on a colour or an opacity.

### Reduced motion

`OMARCHY_REDUCED_MOTION=1` in the environment turns reduced motion on; `NOTCH_REDUCED_MOTION=1` is an alias that the notch (`Bar.reducedMotion`) and `UTheme` both read; a host may provide `reducedMotion` instead. (`OMARCHY_` is only a prefix: it is not an Omarchy variable and this section is its one definition. Copy it into each plugin's README.) When on: springs are off, `press` and `stagger` are off, fades stay (they carry no movement), loops stop and show their final frame (the indeterminate ring is a steady half arc).

## Checking

```sh
./dev/test.sh              # everything: lint, node tests, behaviour tests, the walk's and the gate's self-tests, sync, scanner, gallery
./dev/test.sh --quick      # lint, node (including the docs check) and the behaviour tests
./dev/gallery.sh           # render the gallery in every mode to docs/gallery/*.png and print the contrast table
./dev/gallery.sh --live    # open it in a real window
./dev/render-component.sh --all --theme gruvbox   # one picture per component to docs/components/*.png
./dev/check-ui.sh --score  # the consistency gate and score, on this repo or  --repo <dir> --ref <sha>
./dev/baseline.sh          # the five plugins' baselines
```

- `dev/tests/*.mjs` (node): `keys.js` (the key map and Esc order), `tokens.js` (every role pair in every mode on 16 hosts and on all 51 installed themes, `lift`, the one contrast body), `spring.js` (`Spring.overshoot` and the sampled curves), `errors.js`, the kit's shape, and `docs.mjs` (every relative link in the markdown, a section and a picture for every component, and that every name a `qml` example sets exists in the component).
- `dev/tests/qml/tst_kit.qml` (`qmltestrunner`, a stub theme): real key presses through the components, including the full Esc order.
- `dev/gallery.qml` is every component in every state on one sheet; `dev/harness/ui-gallery.qml` renders it with a fake `surfaceHost` (radius 10, black or white) offscreen (`QT_QPA_PLATFORM=offscreen`, OpenGL RHI, as omarchy-notch `dev/glow.sh`).
- `dev/harness/ui-walk.qml` walks a root's `children` and checks names, 24 px targets, 11 px text, text contrast **measured from rendered pixels**, loops under reduced motion, and no translucent item in hosted-opaque mode. `dev/check-ui.sh` runs it in seven configurations.

The gate (`dev/check-ui.sh`) fails on: a hand-edited `ui/`; a type in `ui/` not starting with `U`; outside `ui/`, `pixelSize: <digit>`, `"#hex"`, `Qt.rgba(<digits>`, `radius: <digit>`, `duration: <digit>`, `Style.font.caption`; a private Switch, Toggle, Choice, Chip, Confirm, Tip or Toast component, a `*Row` that is not a `URow`, `ToggleSwitch`, `ConfirmDialog`, `Dropdown`, `PanelActionButton`, `ToolTip`, `Button`, `Toggle`, `TextField`; a dismiss label of Close, Keep, Later, Dismiss, OK, Okay; raw `Key_Escape` or `onEscapePressed`. A line that must stay carries `// ui-allow: <reason>` and is listed. It measures structure, not behaviour. See `docs/BASELINE.md` for where the five plugins stand.

## Status

**1.0.0**, the first release. `Tokens.MAJOR` is 1, `./dev/test.sh` passes (lint, 7 node suites, the behaviour tests, the walk and gate on fixtures, the sync round trip, the scanner on a fixture, the gallery in every mode), and the gallery and `docs/components/` are rendered from this source. Nothing has been tried inside the running notch: `styled` mode is exercised against a fake host until the notch's guard is live, and `gallery.sh --live` (a real window) is written and not part of the tests.

**Which plugins use it.** As of 2026-11-21:

| plugin | state |
|---|---|
| OLED Corners | **adopted**: 1.2.0 on `main` of [Kalinewb/omarchy-oled-corners](https://github.com/Kalinewb/omarchy-oled-corners) (`cbdc13f`), vendored from kit commit `b88b2af` |
| eGPU | **adopted**: on `main` of [Kalinewb/omarchy-egpu](https://github.com/Kalinewb/omarchy-egpu) (`93a125e`), vendored from kit commit `b88b2af` |
| Profiles, Face, Notch | not started |

The adopters vendor the same `ui/` as 1.0.0 (a docs-only release does not change a hash). `docs/BASELINE.md` has the audit figures for all five from before any of this.

## Not here

Plugin migrations beyond the two above (each its own gate); anything installable; a light theme (dark only); gestures and 44 px targets (the minimum is 24 px).

## Licence

MIT, see [LICENSE](LICENSE).
