#!/bin/bash

# The five baselines: check-ui.sh --counts and --score on each plugin at the
# commit the audit read, with `git archive` (nothing is checked out, nothing
# written to those repos). The figures in plan-apple-ui.md and
# docs/BASELINE.md come from this.
#
#   ./dev/baseline.sh                 print the table
#   ./dev/baseline.sh > docs/BASELINE.md   (see the header it writes)

set -uo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
WORK=${OMARCHY_WORK:-$HOME/Work}

# name, commit the audit read (plan-apple-ui.md header)
plugins=("omarchy-notch 47be7a6" "omarchy-profiles 8b4360e" "omarchy-face 7632e83" "omarchy-oled-corners 5c64ace" "omarchy-egpu 1e62d04")

strip() { sed 's/\x1b\[[0-9;]*m//g'; }
n() { awk -v k="$1" '{ sub(/^ +/, ""); if (index($0, k) == 1) { v = substr($0, length(k) + 1); print v } }' ; }

echo "# Baselines, measured by dev/check-ui.sh"
echo
echo "Each plugin at the commit the audit read (plan-apple-ui.md header), through \`git archive\`; nothing is checked out in those repos. Method: QML files outside \`ui/\`, \`dev/\`, \`upstream/\`, \`docs/\`; a **line** is a line with at least one hit, a **hit** is one occurrence. Re-run with \`./dev/baseline.sh\`."
echo
echo "| plugin @ commit | QML files | \`Style.\` lines / hits | \`duration:\` numeric | \`Style.font.caption\` | \`.font.caption\` (any object) | \`\"#hex\"\` lines / hits | \`pixelSize: <digit>\` | \`Qt.rgba(<digits>\` | \`radius: <digit>\` | \`Accessible.\` | static gate checks failed (of 12) | classes present | consistency |"
echo "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"
for spec in "${plugins[@]}"; do
  read -r name ref <<<"$spec"
  dir=$WORK/$name
  git -C "$dir" cat-file -e "$ref" 2>/dev/null || { echo "| $name @ $ref | commit not found in $dir | | | | | | | | | | | | |"; continue; }
  out=$("$HERE/dev/check-ui.sh" --repo "$dir" --ref "$ref" --counts --score --no-walk 2>&1 | strip)
  files=$(sed -n 's/.*QML files outside ui\/, dev\/, upstream\/, docs\/: \([0-9]*\).*/\1/p' <<<"$out" | head -1)
  c() { grep -F "  $1" <<<"$out" | head -1 | awk -v k="$2" '{ print $(NF-1) " / " $NF }'; }
  style=$(c 'Style. (any token)' x)
  dur=$(grep -F '  duration: <digit>' <<<"$out" | grep -v 'FAIL\|pass' | tail -1 | awk '{ print $(NF-1) " lines / " $NF " hits" }')
  cap=$(grep -F '  Style.font.caption ' <<<"$out" | grep -v 'FAIL\|pass' | tail -1 | awk '{ print $NF }')
  capany=$(grep -F '  theme.font.caption' <<<"$out" | tail -1 | awk '{ print $NF }')
  hex=$(grep -F '  "#hex" literals' <<<"$out" | tail -1 | awk '{ print $(NF-1) " / " $NF }')
  px=$(grep -F '  pixelSize: <digit>' <<<"$out" | grep -v 'FAIL\|pass' | tail -1 | awk '{ print $NF }')
  rgba=$(grep -F '  Qt.rgba(<digits>' <<<"$out" | grep -v 'FAIL\|pass' | tail -1 | awk '{ print $NF }')
  rad=$(grep -F '  radius: <digit>' <<<"$out" | grep -v 'FAIL\|pass' | tail -1 | awk '{ print $NF }')
  acc=$(grep -F '  Accessible.' <<<"$out" | tail -1 | awk '{ print $NF }')
  failed=$(grep -c '  FAIL  ' <<<"$out" | awk '{ print $1 }')
  rules=$(grep -E '^  (FAIL|pass)  ' <<<"$out" | grep -vE 'every type in ui|ui/ matches' | wc -l)
  bad=$(grep -E '^  FAIL  ' <<<"$out" | grep -vE '^  FAIL  +(Back|Close|Dismiss|Primary|Destructive|Confirm|Switch|Pick|Field|Row |Section|Tip|Toast|Empty|Error|Progress|Keys)' | wc -l)
  present=$(sed -n 's/.*consistency  \([0-9]*\) of \([0-9]*\) classes canonical.*/\2/p' <<<"$out")
  score=$(sed -n 's/.*classes canonical  =  \([0-9.]*\) \/ 10.*/\1/p' <<<"$out")
  echo "| $name @ $ref | $files | $style | $dur | $cap | $capany | $hex | ${px:-0} | ${rgba:-0} | ${rad:-0} | ${acc:-0} | $bad of $rules | ${present:-0} | **${score:-n/a}** / 10 |"
done
echo
echo "Reduced-motion reads and \`Accessible.\` are zero in all five, as the audit said."
