#!/bin/bash

# qmllint over the kit, the gallery and the harnesses, resolving `qs.*`
# against the installed Omarchy shell; then bash -n on every script.
#
#   ./dev/lint.sh
#
# Fails on qmllint exiting non-zero, on any warning that means "this will not
# load or bind" (syntax, import, missing-type, unresolved-type, incompatible-
# type, read-only-property, duplicated-name, required, ...), and on a
# `missing-property` on a real type (a typo against someone's API).
# Reported but not fatal: `unqualified` (the QML is written that way) and
# members "not found on type QObject" (`theme` arrives untyped).

set -uo pipefail

GREEN=$'\e[32m'; RED=$'\e[31m'; DIM=$'\e[2m'; BOLD=$'\e[1m'; RESET=$'\e[0m'
REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
QMLLINT=/usr/lib/qt6/bin/qmllint
SHELL_PATH=${OMARCHY_PATH:-/usr/share/omarchy}
[[ -x $QMLLINT ]] || { echo "lint: $QMLLINT is not installed (qt6-declarative)" >&2; exit 1; }
[[ -d $SHELL_PATH/shell ]] || { echo "lint: no Omarchy shell at $SHELL_PATH/shell" >&2; exit 1; }

work=$(mktemp -d "${TMPDIR:-/tmp}/omarchy-ui-lint.XXXXXX")
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/qmlpath"
ln -sfn "$SHELL_PATH/shell" "$work/qmlpath/qs"

FATAL='syntax|import|missing-type|unresolved-type|incompatible-type|read-only-property|duplicated-name|required|unresolved-alias|missing-enum-entry|recursion-depth-errors|attached-property-reuse|non-list-property|property-override|id-shadows-member'

cd "$REPO"
mapfile -t files < <(find ui dev -name '*.qml' -not -path 'dev/fixtures/*' -not -path 'dev/harness/*' | sort)
# The harnesses import "repo/ui" and "walk.js", which exist only in the temp root gallery.sh and walk.sh
# build: lint them in the same shape.
mkdir -p "$work/harness"
ln -s "$REPO" "$work/harness/repo"
cp dev/harness/*.qml dev/harness/walk.js "$work/harness/"
for f in "$work"/harness/*.qml; do files+=("$f"); done
failures=0

echo "${BOLD}QML lint${RESET}  ${DIM}${#files[@]} files, qs.* → $SHELL_PATH/shell${RESET}"
out=$("$QMLLINT" -I "$work/qmlpath" -I /usr/lib/qt6/qml "${files[@]}" 2>&1); rc=$?
out=${out//"$work/harness/"/dev/harness/}

fatal=$(sed -nE "s#^(Warning|Error): (.*) \[($FATAL)\]\$#  \2 [\3]#p" <<<"$out")
typos=$(grep -E '\[missing-property\]' <<<"$out" | grep -v 'on type "QObject"' | sed -E 's#^Warning: #  #')
counts=$(sed -nE 's#.*\[([a-z-]+)\]$#\1#p' <<<"$out" | sort | uniq -c | sort -rn | awk '{printf "%s %s, ", $1, $2}')
echo "  ${DIM}qmllint exit $rc; ${counts%, }${RESET}"

if (( rc != 0 )); then
  echo "  ${RED}FAIL${RESET}  qmllint exited $rc"
  grep -E '^Error:' <<<"$out" | head -20
  failures=$((failures + 1))
elif [[ -n $fatal ]]; then
  echo "  ${RED}FAIL${RESET}  warnings that mean the QML will not load or bind:"
  printf '%s\n' "$fatal" | head -20
  failures=$((failures + 1))
elif [[ -n $typos ]]; then
  echo "  ${RED}FAIL${RESET}  a member that does not exist on a real type:"
  printf '%s\n' "$typos" | head -20
  failures=$((failures + 1))
else
  echo "  ${GREEN}pass${RESET}  no QML errors, nothing that stops it loading, and no unknown members"
fi

echo
echo "${BOLD}Shell${RESET}"
mapfile -t scripts < <(find dev -name '*.sh' | sort)
bad=()
for script in "${scripts[@]}"; do bash -n "$script" 2>/dev/null || bad+=("$script"); done
if (( ${#bad[@]} )); then
  echo "  ${RED}FAIL${RESET}  syntax errors: ${bad[*]}"
  failures=$((failures + 1))
else
  echo "  ${GREEN}pass${RESET}  ${#scripts[@]} scripts parse"
fi

echo
if (( failures )); then echo "${RED}$failures check(s) failed${RESET}"; exit 1; fi
echo "${GREEN}everything passes${RESET}"
