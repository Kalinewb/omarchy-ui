## What and why

<!-- One or two sentences. Link the issue (a component request, a bug). -->

## Kind of change

- [ ] Docs only (no change under `ui/`)
- [ ] Fix (a component does not do what its docs and tests say)
- [ ] New property, `kind`, `tone` or role (MINOR)
- [ ] New component (opened as a component request first)
- [ ] Breaking (MAJOR: see VERSIONING.md; `Tokens.MAJOR` raised in this PR)

## Checklist

- [ ] `./dev/test.sh` passes (paste the last lines)
- [ ] No literal colour, size, duration or radius in `ui/`; every colour a role; margins from `theme.sp`
- [ ] Contrast: any new role or pair is in `tokens.js` `pairs()`, in every mode
- [ ] Keys: Esc only through `UKeys`; new keys are in `keys.js` and tested
- [ ] `docs/components.md`, `CHANGELOG.md` and (for a visual change) the pictures updated: `./dev/gallery.sh`, `./dev/render-component.sh --all --theme gruvbox`
- [ ] Sync round trip into a scratch plugin: the gate passes
- [ ] `ui/KIT` not hand-edited (it is written by `dev/sync-ui.sh` in a plugin, never here)
