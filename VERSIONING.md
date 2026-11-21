# Versioning

omarchy-ui follows [Semantic Versioning 2.0.0](https://semver.org). The first release is **1.0.0**. A release is a git tag `vMAJOR.MINOR.PATCH` on `main`; the history of each is in [CHANGELOG.md](CHANGELOG.md).

The kit is vendored: a plugin copies `ui/` into its own repo, so a release does nothing to a plugin until its owner re-runs the sync. That is why the rules below are strict about what a MAJOR number covers: it is the promise that a re-sync followed by the gate, with no other edit, still works.

## The one place the major lives

`ui/tokens.js` has `var MAJOR = 1`. It is the only number the code knows. `dev/sync-ui.sh` reads it (`grep -oP '^var MAJOR = \K[0-9]+'`) and writes it as line 2 of the plugin's `ui/KIT`; `dev/test.sh` checks that the sync wrote `major 1`. Nothing else in the repo carries a version, so there is nothing to keep in step by hand except the tag.

**The rule: the tag's MAJOR is `Tokens.MAJOR` at that commit.** v1.0.0 is consistent with it: `tokens.js` has `MAJOR = 1` on this branch and on `main` at `b88b2af`. Before tagging, check it:

```sh
tag=v1.0.0
[ "$(grep -oP '^var MAJOR = \K[0-9]+' ui/tokens.js)" = "$(echo "${tag#v}" | cut -d. -f1)" ] && echo "MAJOR matches $tag"
```

Raising `MAJOR` is part of the breaking change itself (the same commit), and `dev/test.sh` has `major 1` written into one check, which then changes with it. Minor and patch numbers live only in the tag and the CHANGELOG; `ui/KIT` does not record them.

## What a plugin's `ui/KIT` says

```
omarchy-ui <40-hex sha of the checkout's HEAD when it was synced>
major <n>
<sha256>  ui/UButton.qml        one line for every copied file (and, with --tools, the five dev/ scripts)
...
```

- The **sha** says exactly which commit was copied. It is not a version: find the release that first contains it with `git -C ../omarchy-ui tag --contains <sha> --sort=v:refname | head -n 1`.
- The **major** says which compatibility line the copy is on. A plugin on `major 1` can take any 1.x by re-syncing.
- The **per-file sha256** is what `dev/check-ui.sh` holds the copy to: a listed file that differs, or a file in `ui/` that is not listed, fails the gate. It is also how two commits can have different shas and identical `ui/` (a docs-only commit moves the sha, not a single hash). A re-sync after a docs-only release rewrites line 1 and nothing else.

`ui/KIT` is written by the sync and never by hand. The format above is part of the contract (see below).

## What counts as breaking (MAJOR)

A change is breaking if a plugin that re-syncs, changes nothing else and runs the gate can stop working, or if a plugin's own tests can stop passing. For this kit that is:

1. **The component API.** Removing or renaming a component, a property, a signal, a function, a `kind`/`tone`/`variant` value, or a layer name of `UKeys`; changing the type, meaning or default of one so that existing code behaves differently; changing what a key does (the key map in `keys.js`, the Esc order).
2. **Token and role names.** Removing or renaming a `UTheme` member (`label`, `secondary`, `metadata`, `accent`, `hairline`, `sp.md`, `rowHeight`, `controlMs`, ...), a role in `tokens.js` `roles()`, a spacing step, a motion token, or a pair name in `pairs()`.
3. **The `theme:` contract.** Every component declares `required property var theme` and reads nothing else. Making a component read a `theme.<name>` that `UTheme` did not have is fine (it is in the same copy); making `UTheme` require a different `host` is not. Plugins that test with a stub theme (the kit's own is `dev/tests/qml/StubTheme.qml`; Corners keeps a copy and a node test that lists every `theme.<name>` the kit reads) have to add the new member to the stub: that is announced in the CHANGELOG under the release and counts as MINOR, not MAJOR, because the stub is the plugin's own test double and the test names the missing member (see [docs/adoption.md](docs/adoption.md)).
4. **The hosted contract.** *Contract 1* (hosted-opaque: `color`, `foreground`, `secondary`, `accent`, `radiusFor(size)` or `radius`, `fontFamily`) and *contract 2* (styled: `host.styled === true`) are the shape of `host` in `UTheme { host: ... }`, which comes from the notch's surface contract. Requiring a new `host` member, changing how a present one is read, or changing what a contract-1 host is promised (every colour opaque, no alpha item) is breaking. Reading one more *optional* member (`host.warning` was added this way) is not.
5. **The gate rules.** The list in the README under *Checking* and `dev/check-ui.sh`: a rule that did not exist, or a pattern that now matches code that passed before, can turn a green plugin red. Adding or widening a failing rule is MAJOR. Narrowing a rule, fixing a false positive, or reporting something without failing is MINOR or PATCH. The walk's configurations and floors (24 px, 11 px, 4.5:1 text, 3:1 marks) are part of the rules.
6. **The sync tool.** The arguments of `dev/sync-ui.sh` (`--from`, `--to`, `--only`, `--tools`, `--allow-dirty`), what it copies, that it is copy-only, and the `ui/KIT` format that `check-ui.sh` reads. The set of five files `--tools` copies is part of it.
7. **The vendoring rules.** The `U` prefix on every type in `ui/`, no file in `ui/` other than the kit's, no import from outside `ui/` other than `qs.Commons`/Quickshell in `UTheme.qml`.

## What does not (MINOR and PATCH)

**MINOR**, backwards compatible: a new component; a new optional property, signal, `kind`, `tone` or role with a default that changes nothing for existing code; a new `UTheme` member; a new doc; a visual refinement that keeps every contrast floor and every size the walk checks (the CHANGELOG says so, so that a plugin's before/after render is expected to differ); a gate rule that only reports.

**PATCH**: a fix that makes a component do what its documentation and tests already say; a doc comment, README or docs change; a test or tooling change that does not change a rule or the sync's behaviour.

A change to the README or `docs/` never touches a `ui/` hash, so it never makes a plugin re-sync necessary. (A doc comment inside a `ui/` file does change that file's hash; a re-sync picks it up and nothing else changes.)

When in doubt it is MAJOR. Deprecation: a name that is going away stays for one MINOR release, works, and is listed under *Deprecated* in the CHANGELOG (`UNotice.tone: "warn"` is the one example in 1.0.0: it still reads as `error`).

## How a plugin updates

1. Read the CHANGELOG from the release you are on (`head -n 2 ui/KIT`, then the tag as above) to the one you want. *Changed*, *Deprecated* and *Removed* are what can need an edit.
2. In the kit checkout: `git fetch --tags && git checkout vX.Y.Z` (the sync reads the checkout's files and HEAD, and never fetches).
3. In the plugin, run the sync again with the **same file set**: `../omarchy-ui/dev/sync-ui.sh --from ../omarchy-ui --to . --tools` plus the `--only ...` you used the first time (the files listed in `ui/KIT` are the set; without `--only` it copies all of `ui/`). It rewrites `ui/` and `ui/KIT`, and removes files the kit no longer has.
4. `git diff --stat -- ui dev` shows what moved. Run `./dev/check-ui.sh --walk <root.qml>` (and the plugin's own tests). A MINOR or PATCH update should need no other edit; a failing line names the file and line.
5. Re-render the before/after pictures if the CHANGELOG lists a visual change, and commit `ui/` and the five tools together, so the hashes and the files match in one commit.

Never fix a problem in the vendored copy: the gate fails the hash. Fix it here, release, and re-sync (see [CONTRIBUTING.md](CONTRIBUTING.md)).

## Support policy

omarchy-ui is maintained by one person alongside the plugins that use it. In that spirit:

- Only the **latest release of the latest major** is supported. Fixes go to `main` and are released as a new PATCH or MINOR; they are not backported.
- A new MAJOR is announced in the CHANGELOG with a migration note for each breaking item, and the plugins of the kalinewb suite move to it in their own commits. After it ships, the previous major gets no further releases, except a fix for something security-relevant, if one is ever found (the kit has no network access and runs no privileged code, so this is expected to be rare), and that on a best-effort basis.
- A plugin that stays on an older sync is not broken by a new release: `ui/` is its own copy, the hashes still match, and the gate still passes. It simply does not get the fixes.
- Supported platform: the Omarchy shell (Quickshell, Qt 6) as installed when the release was made. `dev/test.sh` is the check; it is run against the installed Omarchy shell and its themes, not a pinned one.
