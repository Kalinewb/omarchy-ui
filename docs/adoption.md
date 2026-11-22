# Adopting omarchy-ui in a plugin

A step-by-step guide for a plugin of the Omarchy shell. omarchy-ui is not a plugin and not a dependency you install: you **copy `ui/` into your repo** with a script, keep it unedited, and let a gate check that you did. Version 1.0.0.

Every command below was run, in a scratch plugin built from `dev/fixtures/plugin-clean/` and a clone of this repo, never against a real plugin; the ones that need the network (`git clone`, `git fetch`) were not. Paths assume the kit and your plugin sit side by side: `../omarchy-ui` and `.` (your plugin's root).

Read [migration-checklist.md](migration-checklist.md) next to this: the checklist is the tick-list, this page is the explanation. [components.md](components.md) is the reference for what you will use.

## 0. What you need, and what you keep

- The Omarchy shell (Quickshell on Qt 6) installed, `qt6-declarative` for `qmllint` and `qmltestrunner`, `node` for the pure-logic tests, and `/usr/share/omarchy` for the shell and the themes the harnesses load. ImageMagick helps for pictures; nothing else.
- Keep a migration to the view layer: view QML, `ui/`, wording, keys, motion and the README. The Corners migration (see below) left the service, the manifest, the settings keys and the IPC alone, and that is the scope this guide assumes.
- A migration changes what people see (hover, focus, wording, spacing). Say so in the plugin's changelog and bump its version as for any user-visible change.

## 1. Get the kit, at a release

```sh
git clone https://github.com/Kalinewb/omarchy-ui ../omarchy-ui
git -C ../omarchy-ui checkout v1.0.0        # a release tag; main is the next release
```

The sync reads files and `HEAD` from this checkout and never fetches, clones or pulls: updating the checkout is yours to do. It refuses a checkout with uncommitted changes under `ui/` or `dev/`, because the sha it records would not describe what was copied (`--allow-dirty` overrides it, for kit development only).

## 2. Before you change anything: a green baseline and a score

Make the plugin's own checks green on the unchanged code, and keep them green. Add what is missing first: a lint (`qmllint`), a render of the panel, a key test. The Corners migration began with exactly that commit (lint, a unit test, an offscreen render and a key test, all green on the **unchanged** panel), so that every later change is measured against something.

The kit can read your plugin as it is, with no `ui/` yet, from a commit:

```sh
../omarchy-ui/dev/check-ui.sh --repo . --ref HEAD --score      # static rules and the class table, nothing written
../omarchy-ui/dev/check-ui.sh --repo . --counts --no-walk      # the headline counts (literals, radii, durations, ...)
```

The first prints which gate rules your code fails today and a consistency score; the second is the "before" number for your changelog. `docs/BASELINE.md` shows the same figures for the five suite plugins.

## 3. Vendor the kit

```sh
../omarchy-ui/dev/sync-ui.sh --from ../omarchy-ui --to . --tools
```

| Flag | What it does |
|---|---|
| `--from <dir>` | the kit checkout (required) |
| `--to <dir>` | the plugin to write into; default is the repo the script lives in, which is why a plugin that already has `dev/sync-ui.sh` just runs `./dev/sync-ui.sh --from ../omarchy-ui` |
| `--only A,B,...` | a subset: the named components, what they use (a component's own `U` types and `.js` imports follow), and always `UTheme.qml`, `tokens.js` and `spring.js` |
| `--tools` | also copy the gate and the walk (`dev/check-ui.sh`, `dev/sync-ui.sh`, `dev/walk.sh`, `dev/harness/ui-walk.qml`, `dev/harness/walk.js`) and hash them |
| `--allow-dirty` | copy from a kit checkout with uncommitted `ui/` or `dev/` changes |

A **subset** is normal. Corners uses seven components and vendored `--only UClose,UButton,UNotice,URow,USection,UStepper,UKeys`, which brought `UTip`, `UTheme`, `tokens.js`, `spring.js` and `keys.js` with them (the same shape as `--only UButton,URow,USwitch,UKeys`, which copies 14 files with `--tools`). Names are the file names without `.qml`; an unknown name stops the sync.

What it writes:

```
ui/                the copied files (QML and .js), and
ui/KIT             omarchy-ui <40-hex sha>, major <n>, and a sha256 per copied file
dev/...            the five tool files, with --tools
```

Two things to know:

- **Run it again with the same flags.** A later sync with no `--only` copies all of `ui/` (22 files) and one without `--tools` drops the five tool lines from `ui/KIT`, so a hand edit of a tool would no longer be noticed. The list in `ui/KIT` is the set you used.
- **A smaller set removes** files the previous sync wrote and this one does not want.

Commit `ui/` and the tools together, so the hashes and the files match in one commit. Never edit them afterwards: see section 12.

## 4. Wire it in

The kit is not a singleton. Make one `UTheme` at the plugin's root, hand it down as `theme: theme`, and put `UKeys` around the page.

```qml
import "ui"

Item {                                          // the plugin's root: it has a `theme` for the walk, see section 8
  id: root
  UTheme { id: theme; host: surfaceHost }       // surfaceHost is null in a standalone window
  UKeys {
    anchors.fill: parent
    focus: true
    level: "back"
    open: depth > 0
    onEscaped: goBack()
    onCloseRequested: root.closeRequested()
    // ...
  }
}
```

- **`host`** is any `surfaceHost`-shaped object. Under the notch it is the host the notch gives your panel (contract 1: hosted-opaque, every colour a solid; contract 2: styled). In a window of your own it is `null` and the colours are Omarchy's. The modes are in the README and in [components.md](components.md#utheme). A plugin that declares a `palette` for the notch's contrast guard can use `theme.palette`.
- **`UKeys`** is the one place Esc is handled (section 7).
- Every component takes `theme: theme`. A component that cannot see it is a binding error at load, which the walk and `qmllint` report.

## 5. Replace private controls

`import "ui"` and swap each private control for the kit's. The gate's rules tell you which: it fails these outside `ui/`.

| You have | Use |
|---|---|
| `Switch`, `Toggle`, `ToggleSwitch`, a private `*Switch` | `USwitch` inside a `URow` |
| `Button`, `PanelActionButton`, a private button | `UButton` (`kind`: `quiet`, `primary`, `destructive`, `link`) |
| `TextField`, a number field, `-` / `+` text buttons | `UField`, `UStepper` |
| `Dropdown`, a `ComboBox` | `UPick` (3 or more options), `USegmented` (2 to 4) |
| `Choice`, chips, tabs, a per-row choice button | `USegmented` |
| `ConfirmDialog`, an inline "are you sure" card | `UConfirmSheet` |
| `ToolTip`, a private tip | `tip:` on the control, or `UTip` |
| a private `*Row`, `SettingRow`, `StackedRow` | `URow` (`variant: "stacked"`); a component that only names a configured row can stay: `component ProfileRow: URow { ... }` passes the gate, because its root is a `URow` |
| a section heading | `USection` |
| a spinner, a busy indicator | `URing` |
| an error card, a warning banner | `UNotice` (`tone`) with sentences from `errors.js` |
| a toast, a "saved" note that vanishes in 3 s | `UToast` |
| an empty state | `UEmpty` |
| a back glyph, a close glyph | `UBack` (not in the notch), `UClose` |

Also: no literal `pixelSize`, `"#rrggbb"`, `Qt.rgba(`, `radius:` or `duration:` outside `ui/`: sizes come from `theme.titleSize`, `bodySize`, `footnoteSize`; colours from the roles (`theme.label`, `secondary`, `metadata`, `accent`, `hairline`, ...); radii from `theme.radius(h)`; durations from `theme.controlMs`, `fadeOutMs`, ...; margins and gaps from `theme.sp.xs` to `theme.sp.xxl`. Dismiss words are Cancel, Done and Not now; a label "Close", "Keep", "Later", "Dismiss", "OK" or "Okay" fails. A line that must keep a literal (Corners' pure-black default colour is the point of that plugin) carries `// ui-allow: <reason>` and is listed by the gate.

A control that was only a mark of a selected row gets its own mark. Do not use the keyboard ring for it (section 6).

## 6. Under the notch

If the panel lives in the notch (the host has `panelBack` in `features`), the README's *Layout: the top-centre zone* applies: there is one back control, the strip at the top centre, and Esc is its alias. So:

- keep the **centre** of the top row clear by layout: title left, buttons right, no control or text in the zone (`surfaceHost.backZoneWidth` by `backZoneHeight`);
- draw `UBack` and any "esc goes back" hint only when the host has no such strip;
- answer the strip with `goBackInside()` (return `true` if you went back a step inside, `false` if there is nothing to step back to) and `canGoBack`;
- do not push the panel down for the strip: the host does not.

`notch backZone` (in the notch) lists every control and text inside the zone for the open panel; a panel's suite should assert both lists are empty for every route.

**Focus is not selection.** The kit draws focus as a 2 px ring and selection as a fill with an accent outline and semibold text. For a list whose rows are selected (a row of steppers), mark the selected row with its own mark that sits beside the text, as Corners does with an accent bar in the margin, so it reads without the keyboard ring.

**Contrast on fills.** `secondary` and `metadata` text is guaranteed 4.5:1 on the surface, `fill`, `hover` and `raised`; **only the label is guaranteed on `selected` and `pressed`**. Put quiet text on those fills and the gate's walk will fail it (Corners' "Following" value did, on a fill under the selected row).

## 7. Keys, tips, reduced motion

- Replace every `Keys.onEscapePressed` and `Key_Escape` with `UKeys` (the gate fails both outside `ui/`). Keys the plugin owns (Corners' F and Backspace) stay, and are named once on the foot line.
- `tip:` on a kit control floats a box under it. In the notch use the `foot` placement: declare `UTip { theme: theme; text: "..."; placement: "foot" }` inside the control (set `hovering` yourself if the control has no `hot`), and one `UTip { theme: theme; width: page.width; line: true }` at the foot of the page. See [components.md](components.md#utip).
- Reduced motion needs nothing from you: `theme.reduced`, and every duration and spring in the kit follow `OMARCHY_REDUCED_MOTION=1` (alias `NOTCH_REDUCED_MOTION=1`, or the host's `reducedMotion`). Copy the *Reduced motion* paragraph of the kit's README into yours, and make any animation of your own follow `theme.reduced`.

## 8. The gate, and the walk

```sh
./dev/check-ui.sh --score --walk Panel.qml        # your root file; the static rules, the score, and the walk
./dev/check-ui.sh --walk dev/walk-root.qml        # a second root, if the first shows too little
./dev/check-ui.sh --no-walk                       # the static rules only
```

It prints `pass` or `FAIL` with `file:line` for: a `ui/` that differs from `ui/KIT` (a hand edit, a missing or an unlisted file); a type in `ui/` not starting with `U`; literals outside `ui/`; private controls; dismiss words; raw Esc; and the walk. It exits 1 on any failure. It measures structure and rendered pixels, not behaviour, so write the key tests too (section 9).

**The walk** loads a root QML file under a fake `surfaceHost` offscreen, seven times (standalone; hosted black and white; styled black and white; hosted and standalone with reduced motion), and checks every focusable item has an `Accessible.name`, is at least 24 px, no text is under 11 px, every text is 4.5:1 against what it is drawn on **measured from the rendered pixels**, no animation loops under reduced motion, and no item is translucent in hosted mode. The root is any QML file with a `theme` property.

If the panel needs a model, a host or a service, give the walk a file that stands one in. `dev/walk-root.qml`, for a `SettingsPanel.qml` that takes a `theme`, a `surfaceHost` and a `model`:

```qml
import QtQuick

// The root `dev/check-ui.sh --walk` uses when the bare panel shows too little. The walk hands this file a
// `theme`; the panel gets that theme, its host, and a stand-in for whatever the plugin gives it.
Item {
  id: root
  property var theme: null
  implicitWidth: panel.item ? panel.item.implicitWidth : 420
  implicitHeight: panel.item ? panel.item.implicitHeight : 160

  QtObject { id: model; property int radius: 22 }

  // A Loader, not the SettingsPanel type: the walk runs under Quickshell's `qs:` scheme, where a folder
  // is importable only from the harness root, so this file names the panel by path instead.
  Loader {
    id: panel
    Component.onCompleted: setSource("../SettingsPanel.qml", {
      theme: root.theme,
      surfaceHost: root.theme ? root.theme.host : null,
      model: model
    })
  }
}
```

Show every row, button and notice in it, including the broken and empty states (Corners' root has three screens and a `panel.json` that is not valid JSON), because the walk sees only what is on screen.

## 9. Tests with a stub theme

`qmltestrunner` has no Quickshell and no `qs.Commons`, so it cannot load `UTheme`. Test your panel against a copy of the kit with the theme **swapped for a stub**: copy `dev/tests/qml/StubTheme.qml` from the kit to your `dev/tests/`, and build a scratch tree for each run. The plugin's own `ui/` is never touched.

```sh
#!/bin/bash
# dev/panel-test.sh: the panel under qmltestrunner with the kit's theme swapped for a stub.
set -euo pipefail
REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
stage="$work/panel"; mkdir -p "$stage"
cp "$REPO/SettingsPanel.qml" "$stage/"; cp -r "$REPO/ui" "$stage/ui"
cp "$REPO/dev/tests/StubTheme.qml" "$stage/ui/UTheme.qml"       # a scratch copy
sed -e "s#@STAGE@#$stage#g" "$REPO/dev/tests/tst_panel.qml.in" >"$work/tst_panel.qml"
cd "$work" && QT_QPA_PLATFORM=offscreen timeout 60 /usr/lib/qt6/bin/qmltestrunner -input "$work"
```

```qml
// dev/tests/tst_panel.qml.in
import QtQuick
import QtTest
import "file://@STAGE@" as Plugin
import "file://@STAGE@/ui" as Kit

TestCase {
  name: "panel"
  width: 480
  height: 240
  visible: true
  when: windowShown

  Kit.UTheme { id: stub }                      // the stub: ui/UTheme.qml in the scratch copy
  Plugin.SettingsPanel { id: panel; theme: stub; model: QtObject { property int radius: 22 } }

  function test_the_panel_is_built_on_the_stub() { compare(panel.implicitWidth, 420) }
  // keyClick(Qt.Key_Right) and friends, then compare what the stand-in recorded
}
```

Press real keys (`keyClick`) and check what the panel *asks for* (a stand-in that records every call), not how it looks. The kit's own `dev/tests/qml/tst_kit.qml` is the model.

**Keep the stub honest.** A stub that lacks a member the kit reads makes a test pass or fail for the wrong reason, and a new kit release can add one. This node test fails when a `theme.<name>` read in the panel or in `ui/` is missing from the stub or from `UTheme.qml` (`dev/tests/stub-surface.mjs`; run it in your `dev/test.sh`):

```js
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const REPO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..')
const read = f => fs.readFileSync(path.join(REPO, f), 'utf8').replace(/\/\/.*$/gm, '')
const declared = src => new Set([...src.matchAll(/(?:property\s+(?:readonly\s+)?[\w.<>]+\s+|function\s+)(\w+)/g)].map(m => m[1]))
const stub = declared(read('dev/tests/StubTheme.qml')), real = declared(read('ui/UTheme.qml'))
const files = ['SettingsPanel.qml', ...fs.readdirSync(path.join(REPO, 'ui')).filter(f => f.endsWith('.qml') && f !== 'UTheme.qml').map(f => 'ui/' + f)]
const reads = new Set(files.flatMap(f => [...read(f).matchAll(/\btheme\.(\w+)/g)].map(m => m[1])))
const missing = [...reads].filter(n => !stub.has(n) || !real.has(n))
console.log(`${reads.size} names read through \`theme\` by ${files.length} files; missing from the stub or UTheme: ${missing.join(', ') || 'none'}`)
process.exit(missing.length ? 1 : 0)
```

## 10. Before and after pictures

A migration changes how a panel looks; show it. Render the panel **offscreen** on a stand-in host, with the method of the kit's `dev/gallery.sh`: a small harness QML run by `quickshell -p <temp root> -n` with `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl` (the software renderer cannot run the Shapes the ring uses), a temp root with symlinks to `$OMARCHY_PATH/shell/Commons`, `.../shell/Ui` and your repo, a fake `surfaceHost` (radius 10, black and white), and `scene.grabToImage(...)` to a PNG. `dev/harness/ui-component.qml` and `dev/render-component.sh` in this repo are the shortest complete example (one component, a hosted and a standalone panel side by side); Corners' `dev/render.sh --all docs/screens` renders its own panel the same way. Nothing opens a window and nothing touches the running shell.

For "before", render the **commit before the kit** from a second checkout (`git worktree add ../my-plugin-before <commit>`) with the same harness and the same stand-in host, so the two pictures differ only by the migration. Pictures to take: hosted on black and white, standalone, a row selected, a notice or an error state, the empty state, and with reduced motion on. Optimise them (`magick in.png -strip out.png`) and keep each small.

## 11. Version, README, the scanner

- **Version.** Bump the plugin's `version` in `manifest.json` and its changelog for the user-visible changes (wording, hover and focus, spacing, any key that moved). Do not change manifest ids, capabilities, settings keys or IPC targets as part of a migration.
- **README.** Say the dependency is vendored: *no external dependencies at run time; `ui/` is vendored from omarchy-ui (copied in whole or in part by `dev/sync-ui.sh`, hashed in `ui/KIT`, never edited here: a fix goes to omarchy-ui and comes back through a re-sync)*; copy the *Reduced motion* paragraph; list the dev commands.
- **The scanner.** `dev/sync-ui.sh`, `dev/check-ui.sh` and `dev/walk.sh` contain no `git clone`, `fetch`, `pull`, `curl`, `wget`, `sudo`, `pkexec`, `systemctl` or `systemd-run`, which `dev/test.sh` in the kit greps for, and the sync is copy-only, so adding `ui/` and the scripts should not change a plugin's scan. The kit's tests ran the maintainer's scanner on a fixture with and without them and the verdict, findings and capabilities were identical. That is a fixture: run your marketplace scanner or preflight on the **pushed** commit as the publish documentation asks, and compare it with the commit before.

## 12. What not to hand-edit

- `ui/*` (every file) and `ui/KIT`: the gate fails the hash. A fix goes to the omarchy-ui repo, then a re-sync.
- The five `--tools` files (`dev/check-ui.sh`, `dev/sync-ui.sh`, `dev/walk.sh`, `dev/harness/ui-walk.qml`, `dev/harness/walk.js`): they are hashed in `ui/KIT` too.
- Not hashed, and yours: your own `dev/walk-root.qml`, the stub (re-copy it when a release adds a theme member), your tests and harnesses.

Never fix a problem in the vendored copy to get the gate green, and never commit while the gate is red: a red commit hides what the next one broke.

## 13. Updating later

See [VERSIONING.md](../VERSIONING.md#how-a-plugin-updates): read the CHANGELOG, check out the release in the kit, re-run the sync with the same flags, run the gate and your tests, commit `ui/` and the tools together.

## Worked example: OLED Corners

The first migration is the OLED Corners plugin ([Kalinewb/omarchy-oled-corners](https://github.com/Kalinewb/omarchy-oled-corners), merged as 1.2.0, `cbdc13f`; the migration commits are `f216e1e` to `29c0b51` in its history). The order it followed is the order of this page: tests and a render green on the unchanged panel (`f216e1e`); the kit vendored with a subset and `--tools` (`5238e0e`, kit `b88b2af`); the panel rebuilt on `USection`, `URow`, `UStepper`, `UButton`, `UClose`, `UNotice`, `UTip` and `UKeys`, with every colour, size, gap and radius from the theme (`3299bdd`); the README and `dev/test.sh` (`aac948a`); before and after pictures (`c04881f`); two intentional pure-black defaults marked `// ui-allow` (`7f4eee6`); and the selected row marked with an accent bar (`29c0b51`), because a fill under it failed the gate on a quiet value. Its `README.md` and `dev/` are the best place to see the harness, the stub, the walk root and the key tests as a real plugin keeps them.
