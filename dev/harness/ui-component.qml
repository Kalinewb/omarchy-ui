import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import qs.Commons as Commons
import "repo/ui"

// One component (dev/specimens.qml) under a UTheme in two modes side by side,
// rendered to a PNG: a black hosted panel (contract 1, hosted-opaque, radius 10)
// on the left and a standalone panel (Omarchy's palette, alpha fills) on the
// right. Run by dev/render-component.sh under Quickshell with
// QT_QPA_PLATFORM=offscreen and the OpenGL RHI, as ui-gallery.qml.
//
//   UI_COMPONENT        a component file name without .qml (UButton, URow, ...)
//   UI_COMPONENT_OUT    PNG path
//   UI_COMPONENT_THEME  current (default) or a theme name from the Omarchy themes
//   UI_COMPONENT_HOST   black (default) or white: the hosted panel's colour
ShellRoot {
  id: shell

  readonly property string component: Quickshell.env("UI_COMPONENT") || "UButton"
  readonly property string out: Quickshell.env("UI_COMPONENT_OUT") || "/tmp/ui-component.png"
  readonly property string themeName: Quickshell.env("UI_COMPONENT_THEME") || "current"
  readonly property string hostKind: Quickshell.env("UI_COMPONENT_HOST") || "black"

  function say(key, value) { console.log("UIC " + key + " " + value) }

  FileView {
    id: colors
    blockLoading: true
    path: shell.themeName === "current"
      ? Quickshell.env("HOME") + "/.local/state/omarchy/current/theme/colors.toml"
      : "/usr/share/omarchy/themes/" + shell.themeName + "/colors.toml"
  }
  Component.onCompleted: Commons.Color.loadColors(colors.text())

  // A contract-1 surfaceHost as a panel sees it (SURFACE-HOSTING.md section 3).
  QtObject {
    id: fakeHost
    readonly property bool black: shell.hostKind !== "white"
    readonly property color color: black ? "#000000" : "#ffffff"
    readonly property color foreground: black ? "#ffffff" : "#000000"
    readonly property color secondary: black ? "#99EBEBF5" : "#993C3C43"
    readonly property color accent: foreground
    readonly property real radius: 10
    readonly property string fontFamily: Commons.Style.font.family
    readonly property bool styled: false
    function radiusFor(size) { return Math.max(0, Math.min(radius, size / 2)) }
  }

  UTheme { id: hostedTheme; host: fakeHost }
  UTheme { id: standaloneTheme }

  Window {
    id: win
    visible: true
    readonly property int pad: 20
    readonly property int gap: 16
    readonly property int panelWidth: Math.max(left.item ? left.item.implicitWidth : 300, right.item ? right.item.implicitWidth : 300)
    readonly property int panelHeight: Math.max(left.item ? left.item.implicitHeight : 100, right.item ? right.item.implicitHeight : 100)
    width: 2 * pad + gap + 2 * (panelWidth + 2 * pad)
    height: 2 * pad + panelHeight + 2 * pad + 28
    color: "#3a3a3a"   // the scene behind the two panels; neither panel's colour

    Rectangle {
      id: scene
      anchors.fill: parent
      color: "#3a3a3a"

      Row {
        x: win.pad
        y: win.pad
        spacing: win.gap

        Column {
          spacing: 6
          Rectangle {
            width: win.panelWidth + 2 * win.pad
            height: win.panelHeight + 2 * win.pad
            color: hostedTheme.surface
            radius: 10
            Loader { id: left; x: win.pad; y: win.pad
              Component.onCompleted: setSource("repo/dev/specimens.qml", { theme: hostedTheme, name: shell.component }) }
          }
          Text { text: "hosted-opaque, " + shell.hostKind + " host"; color: "#9a9a9a"; font.pixelSize: 11; font.family: hostedTheme.fontFamily }
        }
        Column {
          spacing: 6
          Rectangle {
            width: win.panelWidth + 2 * win.pad
            height: win.panelHeight + 2 * win.pad
            color: standaloneTheme.surface
            radius: 10
            Loader { id: right; x: win.pad; y: win.pad
              Component.onCompleted: setSource("repo/dev/specimens.qml", { theme: standaloneTheme, name: shell.component }) }
          }
          Text { text: "standalone"; color: "#9a9a9a"; font.pixelSize: 11; font.family: standaloneTheme.fontFamily }
        }
      }
    }

    Timer {
      interval: 1500
      running: true
      onTriggered: {
        shell.say("component", shell.component)
        shell.say("loaded", (left.item ? "yes" : "no") + " " + (right.item ? "yes" : "no"))
        shell.say("size", Math.round(win.width) + "x" + Math.round(win.height))
        scene.grabToImage(function(result) {
          shell.say("saved", result.saveToFile(shell.out))
          Qt.exit(0)
        })
      }
    }
  }
}
