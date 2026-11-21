# Contributing

omarchy-ui is the shared UI kit of the kalinewb Omarchy plugins, and it is deliberately small: one canonical component per class of control, and a gate that fails the variants. Contributions are welcome when they keep it that way. By contributing you agree that your work is released under the [MIT licence](LICENSE).

Start with [docs/design-principles.md](docs/design-principles.md) (what is decided and why), [docs/components.md](docs/components.md) (what exists) and [VERSIONING.md](VERSIONING.md) (what a change costs a plugin).

## Proposing a component

Open an issue with the **component request** template first, before code. A new component is accepted when:

- **Two or more plugins would use it** and today each draws its own. The kit does not hold a component for one plugin; that stays a plugin's own, built from the kit's parts.
- **It is the one canonical form of its class.** Not a variant of something that exists (a second switch, a third button look): a variant is a gate failure in every plugin. If an existing component is missing a case, propose the case (a `kind`, a `tone`, a property) instead.
- **It fits the principles**: monospace and glyph marks, thin outlines, compact, small radii, the accent used sparingly, three text levels, the named spacing scale.

A pull request for a component brings, in small commits:

1. `ui/U<Name>.qml`: the `U` prefix (a bare `Row` or `Button` collides with QtQuick and `qs.Ui`); `required property var theme`; it reads **nothing but `theme`** (no `Style`, no `Color`, no `qs.Commons`: only `UTheme.qml` imports those); no colour, size, duration or radius literal (use roles, `theme.sp.<name>`, `theme.radius(h)` and the motion tokens); a `hot`, `down` and `showFocus` state input for anything with a pointer or focus; an `Accessible.role` and `Accessible.name`; a hit target of at least 24 px and text of at least 11 px; one tab stop; Esc through `UKeys`, never `Key_Escape`.
2. Its colours, if it needs a new role or pair: in `ui/tokens.js` `roles()` and `pairs()`, so the contrast tests hold it to 4.5:1 for text and 3:1 for a mark in **every mode** (standalone, hosted-opaque, styled), and in hosted-opaque every colour is opaque.
3. Tests: node for pure logic (`dev/tests/`), and `dev/tests/qml/tst_kit.qml` for behaviour with real key presses. Add the theme names it reads to `dev/tests/qml/StubTheme.qml` (`dev/tests/kit.mjs` fails if they differ from `UTheme.qml`).
4. It on the gallery sheet (`dev/gallery.qml`), a sheet in `dev/specimens.qml`, and then the pictures: `./dev/gallery.sh` and `./dev/render-component.sh --all --theme gruvbox`.
5. Its section in `docs/components.md` (properties, signals, keys, roles, a minimal example: `./dev/test.sh` fails an example that sets a name the component does not have), a line in the README table, and an entry in `CHANGELOG.md`.

## The rules a change must keep

- **`ui/` is the kit; a plugin copies it and never edits the copy.** Nothing in `ui/` imports from outside it, nothing in it touches the network, a process or a file.
- **Never hand-edit `ui/KIT`.** The kit repo has none of its own (it cannot name its own HEAD). In a plugin it is written by `dev/sync-ui.sh`: line 1 the checkout's sha, line 2 the major, then a sha256 per copied file. `dev/check-ui.sh` fails a plugin whose `ui/` differs from it.
- **The gate's rules** (README, *Checking*): `dev/check-ui.sh` fails a hand-edited `ui/`, a type in `ui/` not starting with `U`, literals outside `ui/`, private controls, banned dismiss words and raw Esc. The kit's own `dev/` and `docs/` are not scanned; its own components follow the rules anyway, and `dev/tests/kit.mjs` holds `ui/` to several of them (the `U` prefix, no `qs.Commons` or Quickshell import outside `UTheme.qml`, no hex literal, no `space(<n>)` literal for a scale step).
- **The dismiss words** are Cancel, Done and Not now. Destructive actions are verb plus object and need a confirmation.
- **Motion** follows `theme.reduced`; **colour** follows the contrast floors; **spacing** uses the named scale.
- **Breaking changes** need a MAJOR (see [VERSIONING.md](VERSIONING.md)): a renamed role, a removed property, a new `host` requirement, a rule that fails what passed, a changed sync or `ui/KIT` format. Raising `Tokens.MAJOR` in `ui/tokens.js` is part of that commit; `dev/test.sh` has `major 1` in one check and moves with it.
- **No new behaviour in a docs change, and no docs change that claims more than the code does.**

## Running the tests

```sh
./dev/test.sh --quick     # lint, node (kit, keys, spring, errors, contrast, docs), qmltestrunner
./dev/test.sh             # everything: also the walk and the gate on fixtures made to fail, the sync round trip, the scanner on a fixture, the gallery in every mode
```

They need the installed Omarchy shell (`/usr/share/omarchy`, or set `OMARCHY_PATH`), `qt6-declarative` (`qmllint`, `qmltestrunner`) and `node`. The scanner part is skipped when `OMARCHY_SCAN` (default `~/Work/plans/omarchy-suite/bin/scan.mjs`) does not exist. Everything runs offscreen: nothing opens a window, installs, reloads the shell or touches a plugin. A pull request should leave `./dev/test.sh` green and say so.

## The sync round trip

Every change to `ui/` or to the tools must survive a sync into a plugin:

```sh
git commit ...                       # the sync refuses a kit with uncommitted changes under ui/ or dev/
cd ../a-scratch-plugin               # never a real plugin repo for this
../omarchy-ui/dev/sync-ui.sh --from ../omarchy-ui --to . --tools
./dev/check-ui.sh --score --walk Panel.qml      # the gate: hash, rules, the walk in 7 configurations
```

`dev/test.sh` does this on `dev/fixtures/plugin-clean/` (and the failures on `plugin-dirty`): a hand edit, a stray file and a subset must each be caught. A fix for a plugin's problem goes here, then a release, then a re-sync there.

## Style

Match the surrounding code: two-space QML indent, comments that say why. Keep commits small and their messages specific. Docs are plain: say what the code does, with the file or property, and run the example. `node dev/tests/docs.mjs` checks every relative link and the names in every `qml` example.
