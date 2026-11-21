import QtQuick
import "../ui"
import "../ui/keys.js" as KeyMap

// One small sheet per component: what docs/components.md shows, rendered
// offscreen by dev/render-component.sh (through dev/harness/ui-component.qml)
// into docs/components/<Name>.png. The gallery (dev/gallery.qml) is every
// component on one sheet; this is one component at a time, with its states
// laid out by hand, because an offscreen render has no pointer: `hot`, `down`
// and `showFocus` are set to draw hover, press and the keyboard ring.
//
//   theme   a UTheme, handed in by the harness
//   name    a component file name without .qml: UButton, URow, ...
Item {
  id: root
  property var theme: null
  property string name: ""

  // The width a sheet with full-width parts (a row, a notice, a confirm) draws at; the others are as wide as their content.
  readonly property int sheetWidth: name === "UConfirmSheet" || name === "UKeys" ? 520 : (name === "UNotice" ? 460 : 420)
  implicitWidth: Math.max(300, content.item ? content.item.width : 0)
  implicitHeight: content.item ? content.item.height : 0

  // A variant with its caption under it.
  component Cap: Column {
    id: cap
    property string caption: ""
    // Room for a tip that a hovered control opens under itself, so it does not sit on the caption.
    property int gap: root.theme.sp.xs
    default property alias body: slot.data
    spacing: gap
    Item { id: slot; width: childrenRect.width; height: childrenRect.height }
    Text {
      text: cap.caption
      color: root.theme.secondary
      font.family: root.theme.fontFamily
      font.pixelSize: root.theme.footnoteSize
    }
  }

  Loader {
    id: content
    sourceComponent: ({
      UBack: backC, UButton: buttonC, UClose: closeC, UConfirmSheet: confirmC, UEmpty: emptyC,
      UField: fieldC, UKeys: keysC, UNotice: noticeC, UPick: pickC, URing: ringC, URow: rowC,
      USection: sectionC, USegmented: segmentedC, UStepper: stepperC, USwitch: switchC,
      UTheme: themeC, UTip: tipC, UToast: toastC
    })[root.name]
  }

  Component {
    id: backC
    Row {
      spacing: root.theme.sp.xl
      Cap { caption: "idle"; gap: 34; UBack { theme: root.theme } }
      Cap { caption: "hover (the tip opens under it)"; gap: 34; UBack { theme: root.theme; hot: true } }
      Cap { caption: "focus"; gap: 34; UBack { theme: root.theme; showFocus: true } }
    }
  }

  Component {
    id: buttonC
    Column {
      spacing: root.theme.sp.lg
      Row {
        spacing: root.theme.sp.sm
        Cap { caption: "quiet"; UButton { theme: root.theme; text: "Not now" } }
        Cap { caption: "destructive"; UButton { theme: root.theme; text: "Remove Ana"; kind: "destructive" } }
        Cap { caption: "primary"; UButton { theme: root.theme; text: "Install"; kind: "primary" } }
        Cap { caption: "link"; UButton { theme: root.theme; text: "Try again"; kind: "link" } }
      }
      Row {
        spacing: root.theme.sp.sm
        Cap { caption: "idle"; UButton { theme: root.theme; text: "Done"; kind: "primary" } }
        Cap { caption: "hover"; UButton { theme: root.theme; text: "Done"; kind: "primary"; hot: true } }
        Cap { caption: "pressed"; UButton { theme: root.theme; text: "Done"; kind: "primary"; down: true } }
        Cap { caption: "focus"; UButton { theme: root.theme; text: "Done"; kind: "primary"; showFocus: true } }
        Cap { caption: "disabled"; UButton { theme: root.theme; text: "Done"; kind: "primary"; enabled: false } }
      }
    }
  }

  Component {
    id: closeC
    Row {
      spacing: root.theme.sp.xl
      Cap { caption: "idle"; gap: 34; UClose { theme: root.theme } }
      Cap { caption: "hover (the tip opens under it)"; gap: 34; UClose { theme: root.theme; hot: true } }
      Cap { caption: "focus"; gap: 34; UClose { theme: root.theme; showFocus: true } }
    }
  }

  Component {
    id: confirmC
    Column {
      spacing: root.theme.sp.lg
      UConfirmSheet {
        theme: root.theme
        width: root.sheetWidth
        sentence: "Remove Ana? Her face data is erased."
        verb: "Remove Ana"
        destructive: true
        asking: true
      }
      Text {
        text: "destructive, asking: Cancel has the focus, Enter does not remove"
        color: root.theme.secondary
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.footnoteSize
      }
      UConfirmSheet {
        theme: root.theme
        width: root.sheetWidth
        sentence: "Remove Ana? Her face data is erased."
        verb: "Remove Ana"
        destructive: true
        UButton { text: "Remove Ana"; kind: "destructive"; theme: root.theme; anchors.right: parent.right }
      }
      Text {
        text: "before ask(): the row it replaces"
        color: root.theme.secondary
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.footnoteSize
      }
    }
  }

  Component {
    id: emptyC
    UEmpty { theme: root.theme; width: root.sheetWidth; text: "No profiles yet."; actionText: "Set up profiles" }
  }

  Component {
    id: fieldC
    Column {
      spacing: root.theme.sp.md
      Cap { caption: "empty: the placeholder"; UField { theme: root.theme; width: 220; label: "Name"; placeholder: "Name" } }
      Cap { caption: "a committed value"; UField { theme: root.theme; width: 220; label: "Name"; value: "Ana" } }
      Cap { caption: "focus"; UField { theme: root.theme; width: 220; label: "Name"; value: "Ana"; showFocus: true } }
    }
  }

  // UKeys draws nothing. The readout below is the specimen's, computed from the
  // registry the kit's own parts joined: a UField with an unsaved edit and a
  // UConfirmSheet asking, so Esc has two layers to choose between.
  Component {
    id: keysC
    UKeys {
      id: page
      width: root.sheetWidth
      height: col.height
      level: "back"
      open: true
      property var layers: []
      function refresh() { layers = Object.keys(KeyMap.shared.openLayers()) }
      Timer { interval: 100; running: true; repeat: true; onTriggered: page.refresh() }
      Column {
        id: col
        width: parent.width
        spacing: root.theme.sp.md
        UField {
          id: edited
          theme: root.theme
          width: 220
          label: "Name"
          value: "Ana"
          Component.onCompleted: { input.text = "Ana B"; focusTimer.start() }
          Timer { id: focusTimer; interval: 300; onTriggered: edited.input.forceActiveFocus() }
        }
        UConfirmSheet {
          theme: root.theme
          width: parent.width
          sentence: "Remove Ana? Her face data is erased."
          verb: "Remove Ana"
          destructive: true
          asking: true
        }
        Text {
          text: "open layers: " + (page.layers.length ? page.layers.join(", ") : "none")
          color: root.theme.label
          font.family: root.theme.fontFamily
          font.pixelSize: root.theme.bodySize
        }
        Text {
          text: "Esc goes to: " + KeyMap.escapeTarget(page.layers.reduce(function(o, l) { o[l] = true; return o }, {}))
          color: root.theme.label
          font.family: root.theme.fontFamily
          font.pixelSize: root.theme.bodySize
        }
        Text {
          text: "(the two lines above are drawn by this sheet, not by UKeys)"
          color: root.theme.metadata
          font.family: root.theme.fontFamily
          font.pixelSize: root.theme.footnoteSize
          font.weight: root.theme.metadataWeight
        }
      }
    }
  }

  Component {
    id: noticeC
    Column {
      spacing: root.theme.sp.sm
      UNotice { theme: root.theme; width: root.sheetWidth; tone: "info"; text: "Face ID will ask once for your password." }
      UNotice { theme: root.theme; width: root.sheetWidth; tone: "warning"; text: "The camera is covered. Face ID may not see you." }
      UNotice {
        theme: root.theme
        width: root.sheetWidth
        text: "The camera is busy. Close the app using it and try again."
        actionText: "Try again"
        details: "camera_busy"
        showDetails: true
      }
    }
  }

  Component {
    id: pickC
    Item {
      width: root.sheetWidth
      height: root.theme.controlHeight + root.theme.sp.xs + 4 * root.theme.rowHeight + 2 * root.theme.sp.xl
      UPick {
        theme: root.theme
        label: "Modifier"
        value: "ctrl"
        open: true
        options: [{ value: "super", label: "Super" }, { value: "ctrl", label: "Control" }, { value: "alt", label: "Alt" }, { value: "shift", label: "Shift" }]
      }
      Text {
        anchors.bottom: parent.bottom
        text: "open: the chosen row is bold with a check"
        color: root.theme.secondary
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.footnoteSize
      }
    }
  }

  Component {
    id: ringC
    Row {
      spacing: root.theme.sp.xxl
      Cap { caption: "determinate"; URing { theme: root.theme; value: 0.62; text: "Saving" } }
      Cap { caption: "indeterminate"; URing { theme: root.theme; text: "Installing, 3 left" } }
    }
  }

  Component {
    id: rowC
    Column {
      width: root.sheetWidth
      URow { theme: root.theme; label: "Show the date"; USwitch { theme: root.theme; label: "Show the date"; checked: true } }
      URow { theme: root.theme; label: "Version"; value: "1.4.0" }
      URow { theme: root.theme; label: "Update channel"; value: "Set by the installer"; valueQuiet: true }
      URow { theme: root.theme; label: "Manage profiles"; value: "›"; clickable: true; showFocus: true }
      URow {
        theme: root.theme
        label: "Hotkey"
        trailing: UButton { theme: root.theme; text: "Reset" }
        UField { theme: root.theme; label: "Hotkey"; value: "Super + K"; width: 140 }
      }
      URow { theme: root.theme; variant: "stacked"; label: "Greeting"
        UField { theme: root.theme; width: parent.width; label: "Greeting"; placeholder: "Say something" } }
    }
  }

  Component {
    id: sectionC
    USection {
      theme: root.theme
      width: root.sheetWidth
      title: "Appearance"
      first: true
      URow { theme: root.theme; label: "Show the date"; USwitch { theme: root.theme; label: "Show the date"; checked: true } }
      URow { theme: root.theme; label: "Show the battery"; USwitch { theme: root.theme; label: "Show the battery" } }
    }
  }

  Component {
    id: segmentedC
    Column {
      spacing: root.theme.sp.md
      Cap {
        caption: "three options"
        USegmented { theme: root.theme; label: "Scope"; value: "apps"
          options: [{ value: "all", label: "Everything" }, { value: "apps", label: "Apps" }, { value: "none", label: "Nothing" }] }
      }
      Cap {
        caption: "two options, focus"
        USegmented { theme: root.theme; label: "Mode"; value: "a"; showFocus: true
          options: [{ value: "a", label: "Light" }, { value: "b", label: "Dark" }] }
      }
    }
  }

  Component {
    id: stepperC
    Row {
      spacing: root.theme.sp.xl
      Cap { caption: "a value"; UStepper { theme: root.theme; label: "Corner radius"; from: 0; to: 40; value: 12; unit: " px" } }
      Cap { caption: "focus"; UStepper { theme: root.theme; label: "Corner radius"; from: 0; to: 40; value: 12; unit: " px"; showFocus: true } }
      Cap { caption: "at the minimum"; UStepper { theme: root.theme; label: "Corner radius"; from: 0; to: 40; value: 0; unit: " px" } }
    }
  }

  Component {
    id: switchC
    Row {
      spacing: root.theme.sp.xl
      Cap { caption: "off"; USwitch { theme: root.theme; label: "Off" } }
      Cap { caption: "on"; USwitch { theme: root.theme; label: "On"; checked: true } }
      Cap { caption: "on, focus"; USwitch { theme: root.theme; label: "On"; checked: true; showFocus: true } }
      Cap { caption: "off, focus"; USwitch { theme: root.theme; label: "Off"; showFocus: true } }
      Cap { caption: "disabled"; USwitch { theme: root.theme; label: "Disabled"; enabled: false } }
    }
  }

  // UTheme is not a widget. The sheet paints each colour role it hands out.
  Component {
    id: themeC
    Column {
      spacing: root.theme.sp.sm
      Text {
        text: root.theme.mode + ", " + root.theme.density + " density, reduced motion " + (root.theme.reduced ? "on" : "off")
        color: root.theme.label
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.bodySize
      }
      Grid {
        columns: 5
        spacing: root.theme.sp.md
        Repeater {
          model: ["surface", "label", "secondary", "metadata", "accent", "accentText", "destructive", "warning", "fill", "hover", "selected", "pressed", "raised", "hairline", "ring", "trackOn", "knobOn", "knobOff", "disabled"]
          Column {
            id: swatch
            required property string modelData
            spacing: root.theme.sp.xs
            Rectangle {
              width: 56
              height: 24
              radius: root.theme.radius(height)
              color: root.theme[swatch.modelData]
              border.width: root.theme.hairlineWidth
              border.color: root.theme.hairline
            }
            Text {
              text: swatch.modelData
              color: root.theme.secondary
              font.family: root.theme.fontFamily
              font.pixelSize: root.theme.footnoteSize
            }
          }
        }
      }
    }
  }

  Component {
    id: tipC
    Item {
      id: tips
      width: root.sheetWidth
      readonly property int captionY: root.theme.rowHeight + 2 * root.theme.sp.xl
      readonly property int footY: captionY + root.theme.footnoteSize + root.theme.sp.xl
      height: footY + 2 * root.theme.footnoteSize + root.theme.sp.xl
      UButton {
        theme: root.theme
        text: "Hover me"
        UTip { theme: root.theme; text: "Switches to the other profile."; armedHover: true }
      }
      Text {
        y: tips.captionY
        text: "float: a box under the control (hover armed)"
        color: root.theme.secondary
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.footnoteSize
      }
      UTip {
        theme: root.theme
        line: true
        y: tips.footY
        width: tips.width
        Component.onCompleted: root.theme.foot = "Shows the date next to the time."
      }
      Text {
        y: tips.footY + root.theme.footnoteSize + root.theme.sp.md
        text: "foot: one reserved line, no box"
        color: root.theme.secondary
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.footnoteSize
      }
    }
  }

  Component {
    id: toastC
    Column {
      spacing: root.theme.sp.lg
      Cap { caption: "no action: stays 6 s"; UToast { theme: root.theme; Component.onCompleted: show("Profile saved") } }
      Cap { caption: "with an action: stays until acted on or put off"; UToast { theme: root.theme; Component.onCompleted: show("Ana removed", "Undo") } }
    }
  }
}
