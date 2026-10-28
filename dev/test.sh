#!/bin/bash

# Everything: lint, the node tests, the walk's self-test, the gate's self-test
# (a clean and a dirty plugin), the sync round trip, and the gallery rendered
# in every mode.
#
#   ./dev/test.sh              all of it
#   ./dev/test.sh --quick      lint and node only
#
# Each part prints its own pass/FAIL lines; this prints one summary.

set -uo pipefail

GREEN=$'\e[32m'; RED=$'\e[31m'; DIM=$'\e[2m'; BOLD=$'\e[1m'; RESET=$'\e[0m'
REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
quick=0; [[ ${1:-} == --quick ]] && quick=1
cd "$REPO" || exit 1

failures=0; checks=0
check() { # check <description> <expected> <actual>
  checks=$((checks + 1))
  if [[ $2 == "$3" ]]; then echo "  ${GREEN}pass${RESET}  $1"
  else echo "  ${RED}FAIL${RESET}  $1 ${DIM}(expected '$2', got '$3')${RESET}"; failures=$((failures + 1)); fi
}
part() { echo; echo "${BOLD}== $1${RESET}"; }
run() { # run <name> <command...>: a part that prints its own checks
  local name=$1; shift
  part "$name"
  if "$@"; then :; else failures=$((failures + 1)); echo "  ${RED}FAIL${RESET}  $name exited non-zero"; fi
}

run "QML lint and script syntax" ./dev/lint.sh
for t in kit keys spring errors contrast; do run "node: $t" node dev/tests/$t.mjs; done
run "behaviour: real key presses through the components (qmltestrunner)" ./dev/tests/qml.sh
((quick)) && { echo; ((failures)) && { echo "${RED}$failures part(s) failed${RESET}"; exit 1; }; echo "${GREEN}quick checks pass${RESET}"; exit 0; }

work=$(mktemp -d "${TMPDIR:-/tmp}/omarchy-ui-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

# ---------------------------------------------------------------- the walk rejects what it should
part "the walk, on a root made to fail"
out=$(./dev/walk.sh --root dev/fixtures/walk-bad.qml --mode hosted --reduced 2>&1)
for clause in names hit text loops opaque contrast; do
  check "walk reports $clause" "FAIL" "$(sed -n "s/^$clause \(FAIL\).*/\1/p" <<<"$out" | head -1)"
done
echo "${DIM}$(grep -E '^(names|hit|text|loops|opaque|contrast)' <<<"$out" | cut -c1-140 | sed 's/^/    /')${RESET}"

# ---------------------------------------------------------------- the gate rejects what it should
part "the gate, on a dirty plugin and a clean one"
mkdir -p "$work/dirty" "$work/clean"
cp dev/fixtures/plugin-dirty/Panel.qml "$work/dirty/"
out=$(./dev/check-ui.sh --repo "$work/dirty" --no-walk 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
rc=$?
for needle in 'pixelSize: <digit>' '"#hex"' 'Qt.rgba(<digits>' 'radius: <digit>' 'duration: <digit>' 'Style.font.caption' \
  'no private Switch' 'every *Row' 'no ToggleSwitch' 'no Button, Toggle or TextField' 'no Close, Keep' 'no raw Key_Escape'; do
  check "dirty plugin fails: $needle" "FAIL" "$(grep -F "FAIL  $needle" <<<"$out" | head -1 | grep -o FAIL)"
done
check "a // ui-allow line is not a failure (it appears once: under its heading)" "1" "$(grep -c 'radius: 3' <<<"$out")"
check "the allowed line is under its own heading" "1" "$(grep -c 'Allowed with // ui-allow' <<<"$out")"
./dev/check-ui.sh --repo "$work/dirty" --no-walk >/dev/null 2>&1; check "check-ui exits 1 on the dirty plugin" "1" "$?"

# ---------------------------------------------------------------- sync, hash, subset
part "sync-ui.sh and the KIT hash"
cp dev/fixtures/plugin-clean/Panel.qml dev/fixtures/plugin-clean/manifest.json "$work/clean/"
git init -q "$work/clean" && git -C "$work/clean" config user.email t@t && git -C "$work/clean" config user.name t
# the kit at HEAD is what sync reads; a dirty ui/ or dev/ is refused, so sync from a snapshot of the working tree
snap="$work/kit"; mkdir -p "$snap" && cp -r ui dev "$snap/" && rm -rf "$snap/dev/fixtures" "$snap/docs"
git -C "$snap" init -q && git -C "$snap" add -A && git -C "$snap" -c user.email=t@t -c user.name=t commit -qm snapshot
sha=$(git -C "$snap" rev-parse HEAD)
out=$("$snap/dev/sync-ui.sh" --from "$snap" --to "$work/clean" --tools 2>&1); check "sync-ui copies the kit and the tools" "0" "$?"
echo "${DIM}    $out${RESET}"
check "ui/KIT line 1 is omarchy-ui and the checkout's HEAD" "omarchy-ui $sha" "$(head -n 1 "$work/clean/ui/KIT")"
check "ui/KIT line 2 is the major" "major 1" "$(sed -n 2p "$work/clean/ui/KIT")"
check "ui/KIT has a sha256 for every file ($(ls "$work/clean/ui" | grep -vc '^KIT$') in ui/, 5 tools)" "$(( $(ls "$work/clean/ui" | grep -vc '^KIT$') + 5 ))" "$(tail -n +3 "$work/clean/ui/KIT" | wc -l)"
check "every hash in KIT is the file's own" "0" "$(cd "$work/clean" && tail -n +3 ui/KIT | sha256sum -c --quiet 2>&1 | wc -l)"
check "sync-ui keeps the executable bit on the tools" "yes" "$([[ -x $work/clean/dev/check-ui.sh && -x $work/clean/dev/sync-ui.sh ]] && echo yes)"
printf 'uncommitted\n' >>"$snap/ui/UBack.qml"
"$snap/dev/sync-ui.sh" --from "$snap" --to "$work/clean" >/dev/null 2>&1; check "sync-ui refuses a kit checkout with uncommitted changes" "1" "$?"
git -C "$snap" checkout -q -- ui/UBack.qml
if grep -nE '(^|[^[:alnum:]_])(git +(-C +[^ ]+ +)?(clone|fetch|pull)|curl|wget|sudo|pkexec|systemctl|systemd-run)( |$)' dev/sync-ui.sh dev/check-ui.sh dev/walk.sh >/dev/null; then
  check "sync-ui, check-ui and walk have no clone, fetch, pull, curl, sudo, pkexec or systemctl" "none" "$(grep -nE '(git +(-C +[^ ]+ +)?(clone|fetch|pull)|curl|wget|sudo|pkexec|systemctl|systemd-run)' dev/sync-ui.sh dev/check-ui.sh dev/walk.sh | head -2 | tr '\n' ' ')"
else check "sync-ui, check-ui and walk have no clone, fetch, pull, curl, sudo, pkexec or systemctl" "none" "none"; fi

part "the gate on the clean plugin, with the kit vendored in"
out=$(cd "$work/clean" && ./dev/check-ui.sh --walk Panel.qml 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); rc=$?
echo "${DIM}$(grep -E 'pass|FAIL|skip' <<<"$out" | cut -c1-150 | sed 's/^/    /')${RESET}"
(cd "$work/clean" && ./dev/check-ui.sh --walk Panel.qml >/dev/null 2>&1); check "check-ui exits 0 on the clean plugin (static rules and the walk in 7 configurations)" "0" "$?"
check "the KIT hash line passes" "1" "$(grep -c 'pass  ui/ matches ui/KIT' <<<"$out")"

part "a hand edit, a stray file, a stray type"
echo '// edit' >>"$work/clean/ui/URow.qml"
out=$(cd "$work/clean" && ./dev/check-ui.sh --no-walk 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); (cd "$work/clean" && ./dev/check-ui.sh --no-walk >/dev/null 2>&1); check "an edited kit file fails the gate" "1" "$?"
check "…and names the file" "1" "$(grep -c 'edited:   ui/URow.qml' <<<"$out")"
cp "$snap/ui/URow.qml" "$work/clean/ui/URow.qml"
printf 'import QtQuick\nItem {}\n' >"$work/clean/ui/Strange.qml"
out=$(cd "$work/clean" && ./dev/check-ui.sh --no-walk 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
check "a file in ui/ that does not start with U fails (and is not in KIT)" "2" "$(grep -cE 'does not start with U|not in KIT: ui/Strange.qml' <<<"$out")"
rm "$work/clean/ui/Strange.qml"
printf 'import QtQuick\nItem {\n  component Local: Item {}\n}\n' >"$work/clean/ui/UOdd.qml"
out=$(cd "$work/clean" && ./dev/check-ui.sh --no-walk 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
check "an inline component in ui/ not starting with U fails" "1" "$(grep -c 'does not start with U' <<<"$out")"
rm "$work/clean/ui/UOdd.qml"

part "a subset: sync-ui --only UButton,URow"
mkdir -p "$work/sub"; cp dev/fixtures/plugin-clean/manifest.json "$work/sub/"
"$snap/dev/sync-ui.sh" --from "$snap" --to "$work/sub" --only UButton,URow >/dev/null 2>&1; check "sync --only succeeds" "0" "$?"
check "UButton brings what it uses (UTip, UKeys, keys.js) and the core (UTheme, tokens.js, spring.js)" "yes" \
  "$(cd "$work/sub/ui" && [[ -f UButton.qml && -f UTip.qml && -f UKeys.qml && -f keys.js && -f UTheme.qml && -f tokens.js && -f spring.js && -f URow.qml ]] && echo yes)"
check "…and nothing else" "no" "$(cd "$work/sub/ui" && ls | grep -qE 'USwitch|UField|UPick|UToast|errors.js' && echo yes || echo no)"
check "the subset passes the gate's hash check" "0" "$(cd "$work/sub" && "$REPO/dev/check-ui.sh" --no-walk --repo . >/dev/null 2>&1; echo $?)"
"$snap/dev/sync-ui.sh" --from "$snap" --to "$work/sub" --only URow >/dev/null 2>&1
check "syncing a smaller set removes what the kit put there before" "no" "$(cd "$work/sub/ui" && ls | grep -qE 'UButton' && echo yes || echo no)"

# ---------------------------------------------------------------- the marketplace scanner
part "the marketplace scanner, on a fixture plugin with and without the kit and its scripts"
SCAN=${OMARCHY_SCAN:-$HOME/Work/plans/omarchy-suite/bin/scan.mjs}
if [[ -f $SCAN ]] && command -v node >/dev/null; then
  mkdir -p "$work/scan-before" "$work/scan-after"
  cp dev/fixtures/plugin-clean/Panel.qml dev/fixtures/plugin-clean/manifest.json "$work/scan-before/"
  cp -r "$work/clean/." "$work/scan-after/" 2>/dev/null; rm -rf "$work/scan-after/.git"
  for d in scan-before scan-after; do git init -q "$work/$d"; git -C "$work/$d" add -A; done
  before=$(node "$SCAN" "$work/scan-before" fixture/clean 2>&1 | jq -c '{outcome, findings: [.findings[].id], caps: [.caps[].id]}' 2>/dev/null)
  after=$(node "$SCAN" "$work/scan-after" fixture/clean 2>&1 | jq -c '{outcome, findings: [.findings[].id], caps: [.caps[].id]}' 2>/dev/null)
  echo "${DIM}    before: $before${RESET}"; echo "${DIM}    after:  $after${RESET}"
  check "verdict, findings and capabilities are unchanged by ui/ and the three dev scripts" "$before" "$after"
  check "the scanner ran (not an error)" "1" "$([[ $before == *outcome* ]] && echo 1 || echo 0)"
else
  echo "  ${DIM}skip  no scan.mjs at $SCAN (set OMARCHY_SCAN)${RESET}"
fi

# ---------------------------------------------------------------- the gallery
part "the gallery, rendered offscreen in every mode"
mkdir -p "$work/gallery"
out=$(./dev/gallery.sh --outdir "$work/gallery" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
for name in standalone hosted-black hosted-white styled-black styled-white; do
  png=$work/gallery/$name.png
  check "$name.png rendered (a PNG over 20 kB)" "yes" "$([[ -f $png ]] && head -c 4 "$png" | grep -q PNG && (( $(stat -c %s "$png") > 20000 )) && echo yes)"
done
check "no QML warnings while rendering" "0" "$(grep -c '^  ! ' <<<"$out")"
check "hosted-opaque, black host: zero translucent items" "0" "$(awk '/^== hosted-black/{f=1} f && /^translucent /{print $2; exit}' <<<"$out")"
check "hosted-opaque, white host: zero translucent items" "0" "$(awk '/^== hosted-white/{f=1} f && /^translucent /{print $2; exit}' <<<"$out")"
check "standalone does use alpha fills (the count is how many)" "yes" "$([[ $(awk '/^== standalone/{f=1} f && /^translucent /{print $2; exit}' <<<"$out") -gt 0 ]] && echo yes)"
check "the three modes were each rendered" "standalone hosted-opaque styled" "$(grep '^mode ' <<<"$out" | awk '{print $2}' | sort -u | tr '\n' ' ' | sed 's/ $//' | awk '{n=split($0,a," "); for(i=1;i<=n;i++) m[a[i]]=1; printf "%s %s %s", (m["standalone"]?"standalone":""), (m["hosted-opaque"]?"hosted-opaque":""), (m["styled"]?"styled":"")}')"
echo "${DIM}$(grep -E '^(==|mode|size|translucent )' <<<"$out" | tr '\n' ' ' | sed 's/== /\n    /g')${RESET}"
part "the contrast table the gallery printed (hosted-opaque, black host)"
awk '/^== hosted-black/{f=1;next} /^== /{f=0} f && /^  (ok|FAIL)/' <<<"$out"

echo
if ((failures)); then echo "${RED}$failures check(s) failed${RESET} (of $checks checks, plus the parts above)"; exit 1; fi
echo "${GREEN}everything passes${RESET} ${DIM}($checks checks here, plus the parts above)${RESET}"
