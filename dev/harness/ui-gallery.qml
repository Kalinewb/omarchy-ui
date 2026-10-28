import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import qs.Commons as Commons
import "repo/ui"
import "repo/ui/tokens.js" as Tokens
import "walk.js" as Walk

// The kit's gallery (dev/gallery.qml) under a UTheme in each of the three
// modes, rendered to a PNG, with its contrast table printed.
// Run by dev/gallery.sh under Quickshell with QT_QPA_PLATFORM=offscreen and
// the OpenGL RHI (as omarchy-notch dev/glow.sh); nothing here opens a real window
// unless UI_GALLERY_LIVE=1.
//
// Settings come from the environment:
//   UI_GALLERY_MODE     standalone | hosted | styled
//   UI_GALLERY_HOST     black | white           (the fake surfaceHost's colour)
//   UI_GALLERY_REDUCED  1 turns reduced motion on
//   UI_GALLERY_THEME    current (default) or a theme name from the Omarchy themes
//   UI_GALLERY_OUT      PNG path
//   UI_GALLERY_LIVE     1 keeps the window open
ShellRoot {
  id: shell

  readonly property string mode: Quickshell.env("UI_GALLERY_MODE") || "standalone"
  readonly property string hostKind: Quickshell.env("UI_GALLERY_HOST") || "black"
  readonly property bool live: Quickshell.env("UI_GALLERY_LIVE") === "1"
  readonly property string out: Quickshell.env("UI_GALLERY_OUT") || "/tmp/ui-gallery.png"
  readonly property string themeName: Quickshell.env("UI_GALLERY_THEME") || "current"

  function say(key, value) { console.log("UIG " + key + " " + value) }

  // The palette is read once from the theme's colors.toml, so a render does not
  // depend on how fast Omarchy's own loader got there.
  FileView {
    id: colors
    blockLoading: true
    path: shell.themeName === "current"
      ? Quickshell.env("HOME") + "/.local/state/omarchy/current/theme/colors.toml"
      : "/usr/share/omarchy/themes/" + shell.themeName + "/colors.toml"
  }
  Component.onCompleted: Commons.Color.loadColors(colors.text())

  // What a contract-1 or contract-2 surfaceHost looks like to a panel
  // (SURFACE-HOSTING.md section 3): radius 10, black or white.
  QtObject {
    id: fakeHost
    readonly property bool black: shell.hostKind !== "white"
    readonly property color color: black ? "#000000" : "#ffffff"
    readonly property color foreground: black ? "#ffffff" : "#000000"
    readonly property color secondary: black ? "#99EBEBF5" : "#993C3C43"
    readonly property color accent: foreground
    readonly property real radius: 10
    readonly property string fontFamily: Commons.Style.font.family
    readonly property bool styled: shell.mode === "styled"
    function radiusFor(size) { return Math.max(0, Math.min(radius, size / 2)) }
  }

  UTheme {
    id: theme
    host: shell.mode === "standalone" ? null : fakeHost
    reducedOverride: Quickshell.env("UI_GALLERY_REDUCED") === "1" ? true : undefined
  }

  Window {
    id: win
    visible: true
    width: gallery.item ? gallery.item.implicitWidth : 1000
    height: gallery.item ? gallery.item.implicitHeight : 800
    color: theme.surface

    Rectangle {
      id: scene
      anchors.fill: parent
      color: theme.surface
      Loader {
        id: gallery
        Component.onCompleted: setSource("repo/dev/gallery.qml", { theme: theme })
      }
    }

    Timer {
      interval: 1500
      running: !shell.live
      onTriggered: {
        var g = gallery.item
        shell.say("mode", theme.mode)
        shell.say("host", shell.mode === "standalone" ? "none" : shell.hostKind)
        shell.say("density", theme.density)
        shell.say("reduced", theme.reduced)
        shell.say("size", Math.round(g.width) + "x" + Math.round(g.height))
        Tokens.check(theme.roles).forEach(function(p) { shell.say("pair", p.name + "|" + p.role + "|" + p.ratio.toFixed(2) + "|" + p.floor + "|" + (p.pass ? "ok" : "FAIL")) })
        var tl = Walk.translucent(g)
        shell.say("translucent", tl.length)
        tl.slice(0, 12).forEach(function(t) { shell.say("translucent-item", t) })
        scene.grabToImage(function(result) {
          shell.say("saved", result.saveToFile(shell.out))
          Qt.exit(0)
        })
      }
    }
  }
}
