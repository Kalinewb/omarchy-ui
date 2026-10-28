#!/bin/bash

# The behaviour tests: dev/tests/qml/tst_kit.qml under qmltestrunner, offscreen.
# Real key presses go through the kit's components with a stub theme, so no
# Quickshell is needed. Esc order, activation keys, arrows, clamping, timings.

set -uo pipefail
REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
RUNNER=/usr/lib/qt6/bin/qmltestrunner
[[ -x $RUNNER ]] || { echo "qml tests: $RUNNER is not installed (qt6-declarative)" >&2; exit 1; }

out=$(cd "$REPO" && QT_QPA_PLATFORM=offscreen timeout 120 "$RUNNER" -input dev/tests/qml/tst_kit.qml 2>&1); rc=$?
sed -E 's/^PASS   : qmltestrunner::kit::/  pass  /; s/^FAIL!  : qmltestrunner::kit::/  FAIL  /; s/^(   Loc|   Actual|   Expected)/      \1/' <<<"$out" | grep -E '^  (pass|FAIL)|^      |Totals' | grep -v 'initTestCase\|cleanupTestCase'
exit $rc
