#!/bin/bash

# Render the kit's gallery (dev/gallery.qml), or open it.
#
#   ./dev/gallery.sh [--outdir <dir>]  every mode to docs/gallery/*.png (or <dir>), contrast table printed
#   ./dev/gallery.sh --mode styled --host white --out /tmp/x.png
#   ./dev/gallery.sh --live [--mode ..]    a real window, no exit
#
# Offscreen with the OpenGL RHI, as omarchy-notch dev/glow.sh: the software
# renderer cannot run the Shapes the ring uses.

set -uo pipefail

REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
SHELL_PATH=${OMARCHY_PATH:-/usr/share/omarchy}

mode=""; host=black; out=""; live=0; reduced=0; theme=current; outdir="$REPO/docs/gallery"
while (($#)); do
  case $1 in
    --mode) mode=$2; shift 2 ;;
    --host) host=$2; shift 2 ;;
    --out) out=$2; shift 2 ;;
    --outdir) outdir=$2; shift 2 ;;
    --theme) theme=$2; shift 2 ;;
    --reduced) reduced=1; shift ;;
    --live) live=1; shift ;;
    *) echo "gallery: unknown argument $1" >&2; exit 2 ;;
  esac
done

root=$(mktemp -d "${TMPDIR:-/tmp}/omarchy-ui-gallery.XXXXXX")
trap 'rm -rf "$root"' EXIT
ln -s "$SHELL_PATH/shell/Commons" "$root/Commons"
ln -s "$SHELL_PATH/shell/Ui" "$root/Ui"
ln -s "$REPO" "$root/repo"
cp "$REPO/dev/harness/ui-gallery.qml" "$REPO/dev/harness/walk.js" "$root/"
mv "$root/ui-gallery.qml" "$root/shell.qml"

render() { # render <mode> <host> <png>
  local log="$root/log.$$"
  UI_GALLERY_MODE=$1 UI_GALLERY_HOST=$2 UI_GALLERY_OUT=$3 UI_GALLERY_THEME=$theme UI_GALLERY_REDUCED=$reduced \
    QT_QUICK_BACKEND=rhi QSG_RHI_BACKEND=opengl QT_QPA_PLATFORM=offscreen \
    timeout 60 quickshell -p "$root" -n >"$log" 2>&1
  sed -n 's/^.*UIG //p' "$log" | awk -F'|' '
    /^pair / { sub(/^pair /, "", $1); printf "  %-4s  %-30s %6s : 1   floor %s  (%s)\n", ($5 == "ok" ? "ok" : "FAIL"), $1, $3, $4, $2; next }
    { print }'
  sed 's/\x1b\[[0-9;]*m//g' "$log" | grep -E 'WARN scene|WARN qml|ERROR|ui: ' | head -20 | sed 's/^/  ! /'
}

if ((live)); then
  UI_GALLERY_LIVE=1 UI_GALLERY_MODE=${mode:-standalone} UI_GALLERY_HOST=$host UI_GALLERY_THEME=$theme UI_GALLERY_REDUCED=$reduced \
    exec quickshell -p "$root" -n
fi

if [[ -n $mode ]]; then
  render "$mode" "$host" "${out:-/tmp/ui-gallery-$mode-$host.png}"
  exit 0
fi

mkdir -p "$outdir"
for spec in "standalone black" "hosted black" "hosted white" "styled black" "styled white"; do
  read -r m h <<<"$spec"
  name=$m; [[ $m != standalone ]] && name=$m-$h
  echo "== $name"
  render "$m" "$h" "$outdir/$name.png"
done
