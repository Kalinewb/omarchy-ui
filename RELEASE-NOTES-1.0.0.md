<!-- DRAFT, not published. Before `gh release create`: delete this comment, set the date, and re-check the Status lines against the plugin repos on that day. -->

# omarchy-ui 1.0.0

The first release of the shared UI kit for the kalinewb Omarchy plugins: one set of tokens, motion and controls, so every plugin looks and behaves the same. One back, one close, three dismiss words, one switch, one confirm, one key map.

omarchy-ui is **not a plugin**: it has no manifest and is never listed or installable. A plugin **copies `ui/` into its own repo** with `dev/sync-ui.sh` and keeps it unedited; `dev/check-ui.sh` fails the plugin if it is not.

## What is in it

- **Eighteen QML files in `ui/`**: `UTheme`, `UKeys` and sixteen components (`UBack`, `UClose`, `UButton`, `USwitch`, `USegmented`, `UPick`, `UField`, `UStepper`, `URow`, `USection`, `UTip`, `UToast`, `UNotice`, `UEmpty`, `URing`, `UConfirmSheet`), and the pure-JavaScript libraries behind them (`tokens.js`, `keys.js`, `spring.js`, `errors.js`).
- **Three modes** from one `UTheme { host: ... }`: standalone (Omarchy's palette), hosted-opaque (only what the notch hands over, every colour a solid) and styled.
- **Contrast as a gate**: text 4.5:1 and every mark 3:1 in every mode, on 16 hosts and every installed Omarchy theme; the consistency walk measures text contrast from rendered pixels.
- **A named spacing scale** (`xs` 4 to `xxl` 32), **three text levels** (primary, secondary, metadata) and a **warning tone** for notices, added in the last refinement round.
- **Reduced motion** (`OMARCHY_REDUCED_MOTION=1`, alias `NOTCH_REDUCED_MOTION=1`).
- **The tools**: `dev/sync-ui.sh` (copy-only, with `--only` subsets and `--tools`), `dev/check-ui.sh` (the gate and its score), the walk, the offscreen gallery and per-component renders, and `dev/test.sh` (everything, one summary).
- **Documentation**: a reference for every component with a picture ([docs/components.md](docs/components.md)), the [design principles](docs/design-principles.md), an [adoption guide](docs/adoption.md) and [migration checklist](docs/migration-checklist.md), [VERSIONING.md](VERSIONING.md), [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).

No network access and no privileged code: `ui/` draws and handles keys, and the scripts a plugin copies run locally and contain no `clone`, `fetch`, `pull`, `curl`, `sudo`, `pkexec` or `systemctl`.

## Adopting it

```sh
git clone https://github.com/Kalinewb/omarchy-ui ../omarchy-ui && git -C ../omarchy-ui checkout v1.0.0
../omarchy-ui/dev/sync-ui.sh --from ../omarchy-ui --to . --tools --only UButton,URow,USwitch,UKeys
./dev/check-ui.sh --walk Panel.qml
```

Then follow [docs/adoption.md](docs/adoption.md). `ui/KIT` records the commit, `major 1` and a sha256 per file; a later release is taken the same way ([VERSIONING.md](VERSIONING.md#how-a-plugin-updates)).

## Status and known limits

- **No plugin has adopted it as merged code yet.** OLED Corners has a migration on an unmerged `ui-kit` branch and eGPU has one in progress; Profiles, Face and the Notch have not started.
- `styled` mode (surface contract 2) is exercised against a fake host; nothing has been tried inside the running notch.
- The metadata text level differs from secondary by a few hundredths of a contrast ratio on many themes; the Light weight carries the rest, and a face without a Light weight shows Regular.
- `warning` is an amber default unless a host hands one over (Omarchy's palette has no yellow). In hosted-opaque mode warning and error are told apart by their glyph and spoken word, not colour.
- `UStepper` has no typed entry. A `float` tip is clipped by any ancestor that clips; under the notch use the `foot` placement.
- Dark only.

## Versioning

Semantic Versioning, with `Tokens.MAJOR` in `ui/tokens.js` as the one number the code knows (1 for every 1.x). What counts as breaking, and the support policy, are in [VERSIONING.md](VERSIONING.md). The full history is in [CHANGELOG.md](CHANGELOG.md).
