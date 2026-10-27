# omarchy-ui

The shared UI kit for the kalinewb Omarchy plugins (notch, profiles, face, corners, egpu): one set of tokens, motion and controls, so every plugin looks and behaves the same.

Not a plugin. Each plugin copies `ui/` into its own repo (no symlinks, no cross-plugin imports) with `dev/sync-ui.sh --from <checkout>`.

Status: planning. See the suite plan for the design.
