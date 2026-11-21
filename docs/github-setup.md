# GitHub setup for 1.0.0

Everything the maintainer runs to publish 1.0.0: nothing here has been run, and none of it is run by the tools in this repo. Run it from a checkout whose `main` is what you want to release, after reading the diff (`git log --oneline main..release-1.0`). `gh` must be logged in as an account that can write to `Kalinewb/omarchy-ui`.

## 1. Check, merge

```sh
cd ~/Work/omarchy-ui-release
./dev/test.sh                                              # must end with "everything passes"
git log --oneline main..release-1.0                        # the commits being released
git diff --stat main..release-1.0 -- ui                    # should print nothing: no change to ui/ in this release
```

Either a fast-forward on `main` (it is at `b88b2af` and the branch descends from it):

```sh
git -C ~/Work/omarchy-ui merge --ff-only release-1.0
```

or a pull request, if you want to read it on GitHub first:

```sh
git push -u origin release-1.0
gh pr create --repo Kalinewb/omarchy-ui --base main --head release-1.0 --title "Release 1.0.0: docs, changelog, versioning, renders" --body "Docs, changelog, versioning, component pictures and release files for 1.0.0. No change under ui/."
gh pr merge release-1.0 --repo Kalinewb/omarchy-ui --merge          # or --squash / --rebase, as you prefer
git -C ~/Work/omarchy-ui pull --ff-only
```

## 2. Date the release, tag it

`CHANGELOG.md` says `## [1.0.0] - Unreleased` until now. In `~/Work/omarchy-ui` on `main`:

```sh
cd ~/Work/omarchy-ui
tag=v1.0.0
[ "$(grep -oP '^var MAJOR = \K[0-9]+' ui/tokens.js)" = "$(echo "${tag#v}" | cut -d. -f1)" ] && echo "MAJOR matches $tag"   # must print this
sed -i "s/^## \[1.0.0\] - Unreleased/## [1.0.0] - $(date +%F)/" CHANGELOG.md
git commit -am "Release 1.0.0"
git tag -a "$tag" -m "omarchy-ui 1.0.0"
git push origin main "$tag"
```

## 3. The release

First remove the `DRAFT` comment at the top of the notes and check the Status lines against the plugin repos that day, then:

```sh
cd ~/Work/omarchy-ui
sed -i '1{/^<!-- DRAFT/d}' RELEASE-NOTES-1.0.0.md && sed -i '1{/^$/d}' RELEASE-NOTES-1.0.0.md
gh release create v1.0.0 --repo Kalinewb/omarchy-ui --title "omarchy-ui 1.0.0" --notes-file RELEASE-NOTES-1.0.0.md --verify-tag --latest
gh release view v1.0.0 --repo Kalinewb/omarchy-ui
```

The release attaches no files: a plugin copies from a checkout, not from a download. Do **not** submit omarchy-ui to the plugin marketplace; it is not a plugin.

## 4. Repository settings

Description, and topics (deliberately without `omarchy-plugin` or similar: it is not one):

```sh
gh repo edit Kalinewb/omarchy-ui \
  --description "Shared QML UI kit for the kalinewb Omarchy shell plugins: tokens, motion, sixteen components and a consistency gate. Vendored into each plugin; not a plugin itself." \
  --add-topic omarchy --add-topic quickshell --add-topic qml --add-topic ui-kit --add-topic hyprland --add-topic accessibility
gh repo edit Kalinewb/omarchy-ui --enable-issues
```

`SECURITY.md` asks for private reports through GitHub's private vulnerability reporting. Turn it on (the API call below is the documented one; you can also use Settings, Code security):

```sh
gh api --method PUT repos/Kalinewb/omarchy-ui/private-vulnerability-reporting
```

Check the result:

```sh
gh repo view Kalinewb/omarchy-ui --json description,repositoryTopics,hasIssuesEnabled,isSecurityPolicyEnabled,licenseInfo,latestRelease
gh api repos/Kalinewb/omarchy-ui/private-vulnerability-reporting
```

## 5. After the release

- The plugins' `ui/KIT` line 1 holds the sha they synced from (`b88b2af` for the two migration branches); `git -C ../omarchy-ui tag --contains <sha>` now answers `v1.0.0`. Their `ui/` hashes equal 1.0.0's, so a re-sync only rewrites that line.
- Update the status table in `README.md` and `RELEASE-NOTES-1.0.0.md` as the plugins merge their migrations.
- Pin nothing in the quick start: it names `v1.0.0`, which now exists.
