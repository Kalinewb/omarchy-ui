# Baselines, measured by dev/check-ui.sh

Each plugin at the commit the audit read (plan-apple-ui.md header), through `git archive`; nothing is checked out in those repos. Method: QML files outside `ui/`, `dev/`, `upstream/`, `docs/`; a **line** is a line with at least one hit, a **hit** is one occurrence. Re-run with `./dev/baseline.sh`.

| plugin @ commit | QML files | `Style.` lines / hits | `duration:` numeric | `Style.font.caption` | `.font.caption` (any object) | `"#hex"` lines / hits | `pixelSize: <digit>` | `Qt.rgba(<digits>` | `radius: <digit>` | `Accessible.` | static gate checks failed (of 12) | classes present | consistency |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| omarchy-notch @ 47be7a6 | 34 | 346 / 377 | 33 lines / 33 hits | 24 | 24 | 49 / 60 | 0 | 8 | 6 | 0 | 10 of 12 | 14 | **0.7** / 10 |
| omarchy-profiles @ 8b4360e | 10 | 230 / 232 | 0 lines / 0 hits | 80 | 80 | 0 / 0 | 0 | 0 | 0 | 0 | 6 of 12 | 10 | **1.0** / 10 |
| omarchy-face @ 7632e83 | 15 | 207 / 210 | 8 lines / 8 hits | 66 | 66 | 5 / 5 | 0 | 4 | 0 | 0 | 8 of 12 | 9 | **0.0** / 10 |
| omarchy-oled-corners @ 5c64ace | 3 | 3 / 3 | 0 lines / 0 hits | 0 | 0 | 4 / 4 | 6 | 0 | 0 | 0 | 3 of 12 | 1 | **0.0** / 10 |
| omarchy-egpu @ 1e62d04 | 20 | 21 / 30 | 5 lines / 5 hits | 4 | 17 | 0 / 0 | 0 | 0 | 0 | 0 | 4 of 12 | 8 | **1.2** / 10 |

Reduced-motion reads and `Accessible.` are zero in all five, as the audit said.
