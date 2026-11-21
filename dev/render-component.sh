#!/bin/bash

# Render one component (dev/specimens.qml), or all of them, offscreen: a black hosted panel and a
# standalone panel side by side, to a PNG. These are the pictures in docs/components/.
#
#   ./dev/render-component.sh UButton --out /tmp/button.png      one component
#   ./dev/render-component.sh --all [--outdir <dir>]             every ui/*.qml to docs/components/<Name>.png
#   ./dev/render-component.sh --all --theme gruvbox              standalone colours from a stock Omarchy theme
#   ./dev/render-component.sh --host white UButton               the hosted panel white instead of black
#
# Offscreen with the OpenGL RHI, as gallery.sh. Nothing opens a window and nothing touches the running shell.
# `--theme current` (the default) reads the live Omarchy theme; docs/components/ is rendered with
# `--theme gruvbox`, so that it can be reproduced on any Omarchy install.

set -uo pipefail

REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
SHELL_PATH=${OMARCHY_PATH:-/usr/share/omarchy}

names=(); out=""; outdir="$REPO/docs/components"; all=0; theme=current; host=black
while (($#)); do
  case $1 in
    --out) out=$2; shift 2 ;;
    --outdir) outdir=$2; shift 2 ;;
    --all) all=1; shift ;;
    --theme) theme=$2; shift 2 ;;
    --host) host=$2; shift 2 ;;
    -*) echo "render-component: unknown argument $1" >&2; exit 2 ;;
    *) names+=("${1%.qml}"); shift ;;
  esac
done
if ((all)); then
  names=(); for f in "$REPO"/ui/U*.qml; do b=${f##*/}; names+=("${b%.qml}"); done
fi
((${#names[@]})) || { echo "render-component: name a component (UButton) or pass --all" >&2; exit 2; }
((${#names[@]} == 1)) || [[ -z $out ]] || { echo "render-component: --out takes one component" >&2; exit 2; }

root=$(mktemp -d "${TMPDIR:-/tmp}/omarchy-ui-component.XXXXXX")
trap 'rm -rf "$root"' EXIT
ln -s "$SHELL_PATH/shell/Commons" "$root/Commons"
ln -s "$SHELL_PATH/shell/Ui" "$root/Ui"
ln -s "$REPO" "$root/repo"
cp "$REPO/dev/harness/ui-component.qml" "$root/shell.qml"

mkdir -p "$outdir"
status=0
for name in "${names[@]}"; do
  [[ -f $REPO/ui/$name.qml ]] || { echo "render-component: no ui/$name.qml" >&2; status=1; continue; }
  png=${out:-$outdir/$name.png}
  log="$root/log.$name"
  UI_COMPONENT=$name UI_COMPONENT_OUT=$png UI_COMPONENT_THEME=$theme UI_COMPONENT_HOST=$host \
    QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl QT_QPA_PLATFORM=offscreen \
    timeout 60 quickshell -p "$root" -n >"$log" 2>&1
  echo "== $name"
  sed 's/\x1b\[[0-9;]*m//g' "$log" | sed -n 's/^.*UIC //p' | grep -E '^(loaded|size|saved)' | sed 's/^/  /'
  sed 's/\x1b\[[0-9;]*m//g' "$log" | grep -E 'WARN scene|WARN qml|ERROR|ui: |ReferenceError|TypeError' | head -10 | sed 's/^/  ! /'
  [[ -s $png ]] || { echo "  ! no PNG written" >&2; status=1; }
done
exit $status
