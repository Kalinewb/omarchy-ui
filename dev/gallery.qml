import QtQuick
import "../ui"
import "../ui/tokens.js" as Tokens

// Every kit component in every state, on one sheet (plan-apple-ui.md 6.3
// Phase 0). It is the thing the user approves, and the root the consistency
// walk (dev/harness/ui-walk.qml) runs against.
//
//   ./dev/gallery.sh            render the sheet in each mode to docs/gallery/*.png
//   ./dev/gallery.sh --live     open it in a window and click around
//
// `theme` is a UTheme made by the harness; the sheet reads nothing else. The
// state strips set the controls' state inputs (`hot`, `down`, `showFocus`)
// by hand, because an offscreen render has no pointer.
Item {
  id: root
  property var theme: null

  readonly property int columnWidth: 500
  readonly property int gutter: 32
  implicitWidth: 2 * columnWidth + 3 * gutter
  implicitHeight: Math.max(leftCol.height, rightCol.height) + 2 * gutter
  width: implicitWidth
  height: implicitHeight

  // Held by the sheet, so the controls have something to change when clicked.
  property bool showDate: true
  property bool showBattery: false
  property string scope: "all"
  property string modifier: "super"
  property int radiusValue: 10
  property string nameValue: "Ana"
  property string greeting: ""
  property bool unset: false

  component Spec: Column {
    id: spec
    property string caption: ""
    default property alias body: slot.data
    spacing: 4
    Item { id: slot; width: childrenRect.width; height: childrenRect.height }
    Text {
      text: spec.caption
      color: root.theme.secondary
      font.family: root.theme.fontFamily
      font.pixelSize: root.theme.footnoteSize
    }
  }

  // ------------------------------------------------------------------ left
  Column {
    id: leftCol
    x: root.gutter
    y: root.gutter
    width: root.columnWidth
    spacing: 0

    Item {
      width: parent.width
      height: root.theme.rowHeight
      UBack { id: back; theme: root.theme; visible: root.theme.mode === "standalone"; anchors.verticalCenter: parent.verticalCenter }
      Text {
        anchors.left: root.theme.mode === "standalone" ? back.right : parent.left
        anchors.leftMargin: root.theme.mode === "standalone" ? root.theme.space(4) : 0
        anchors.verticalCenter: parent.verticalCenter
        text: "Appearance"
        color: root.theme.label
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.titleSize
        font.weight: root.theme.titleWeight
      }
      UClose { theme: root.theme; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
    }
    Item { width: 1; height: root.theme.space(8) }

    USection {
      theme: root.theme
      title: "Rows"
      first: true
      URow { theme: root.theme; label: "Show the date"; tip: "Shows the date next to the time."
        USwitch { theme: root.theme; label: "Show the date"; checked: root.showDate; onToggled: root.showDate = !root.showDate } }
      URow { theme: root.theme; label: "Show the battery"
        USwitch { theme: root.theme; label: "Show the battery"; checked: root.showBattery; onToggled: root.showBattery = !root.showBattery } }
      URow { theme: root.theme; label: "Update channel"; value: "Set by the installer" }
      URow { theme: root.theme; label: "Scope"
        USegmented { theme: root.theme; label: "Scope"; value: root.scope; onPicked: function(v) { root.scope = v }
          options: [{ value: "all", label: "Everything" }, { value: "apps", label: "Apps" }, { value: "none", label: "Nothing" }] } }
      URow { theme: root.theme; label: "Modifier"
        UPick { theme: root.theme; label: "Modifier"; value: root.modifier; onPicked: function(v) { root.modifier = v }
          options: [{ value: "super", label: "Super" }, { value: "ctrl", label: "Control" }, { value: "alt", label: "Alt" }, { value: "shift", label: "Shift" }] } }
      URow { theme: root.theme; label: "Corner radius"
        UStepper { theme: root.theme; label: "Corner radius"; from: 0; to: 40; value: root.radiusValue; unit: " px"; onModified: function(v) { root.radiusValue = v } } }
      URow { theme: root.theme; label: "Name"
        UField { theme: root.theme; label: "Name"; value: root.nameValue; onCommitted: function(t) { root.nameValue = t } } }
      URow { theme: root.theme; variant: "stacked"; label: "Greeting"
        UField { theme: root.theme; width: parent.width; label: "Greeting"; placeholder: "Say something"; value: root.greeting; onCommitted: function(t) { root.greeting = t } } }
      URow { theme: root.theme; label: "Manage profiles"; value: "›"; clickable: true }
    }

    USection {
      theme: root.theme
      title: "Buttons"
      Row {
        spacing: root.theme.space(8)
        height: root.theme.rowHeight
        UButton { theme: root.theme; text: "Not now" }
        UButton { theme: root.theme; text: "Remove Ana"; kind: "destructive" }
        UButton { theme: root.theme; text: "Install Face ID"; kind: "primary" }
        UButton { theme: root.theme; text: "Try again"; kind: "link" }
      }
    }

    USection {
      theme: root.theme
      title: "States, left to right: idle, hover, pressed, focus, disabled"
      Column {
        spacing: root.theme.space(8)
        Row {
          spacing: root.theme.space(8)
          UButton { theme: root.theme; text: "Done"; kind: "primary" }
          UButton { theme: root.theme; text: "Done"; kind: "primary"; hot: true }
          UButton { theme: root.theme; text: "Done"; kind: "primary"; down: true }
          UButton { theme: root.theme; text: "Done"; kind: "primary"; showFocus: true }
          UButton { theme: root.theme; text: "Done"; kind: "primary"; enabled: false }
        }
        Row {
          spacing: root.theme.space(8)
          UButton { theme: root.theme; text: "Cancel" }
          UButton { theme: root.theme; text: "Cancel"; hot: true }
          UButton { theme: root.theme; text: "Cancel"; down: true }
          UButton { theme: root.theme; text: "Cancel"; showFocus: true }
          UButton { theme: root.theme; text: "Cancel"; enabled: false }
        }
        Row {
          spacing: root.theme.space(16)
          USwitch { theme: root.theme; label: "Off" }
          USwitch { theme: root.theme; label: "On"; checked: true }
          USwitch { theme: root.theme; label: "On, focused"; checked: true; showFocus: true }
          USwitch { theme: root.theme; label: "Off, focused"; showFocus: true }
          USwitch { theme: root.theme; label: "Disabled"; enabled: false }
        }
        Row {
          spacing: root.theme.space(8)
          UField { theme: root.theme; width: 150; label: "Empty"; placeholder: "Name" }
          UField { theme: root.theme; width: 150; label: "Focused"; value: "Ana"; hot: true }
          UStepper { theme: root.theme; label: "Radius"; value: 0; from: 0; to: 40; unit: " px" }
        }
        Row {
          spacing: root.theme.space(16)
          UBack { theme: root.theme }
          UBack { theme: root.theme; hot: true }
          UBack { theme: root.theme; showFocus: true }
          UClose { theme: root.theme }
          UClose { theme: root.theme; hot: true }
          UClose { theme: root.theme; showFocus: true }
        }
        Item { width: 1; height: root.theme.space(24) }
      }
    }
  }

  // ----------------------------------------------------------------- right
  Column {
    id: rightCol
    x: root.columnWidth + 2 * root.gutter
    y: root.gutter
    width: root.columnWidth
    spacing: 0

    USection {
      theme: root.theme
      title: "Feedback"
      first: true
      spacing: root.theme.space(8)
      UToast { id: toastPlain; theme: root.theme; Component.onCompleted: show("Profile saved") }
      UToast { id: toastAction; theme: root.theme; Component.onCompleted: show("Ana removed", "Undo") }
      UNotice {
        theme: root.theme
        width: parent.width
        text: "The camera is busy. Close the app using it and try again."
        actionText: "Try again"
        details: "camera_busy"
        showDetails: true
      }
      UNotice { theme: root.theme; width: parent.width; tone: "info"; text: "Face ID will ask once for your password." }
      UEmpty { theme: root.theme; width: parent.width; text: "No profiles yet."; actionText: "Set up profiles" }
      Row {
        spacing: root.theme.space(24)
        URing { theme: root.theme; value: 0.62; text: "Saving" }
        URing { theme: root.theme; text: "Installing, 3 left" }
      }
    }

    USection {
      theme: root.theme
      title: "Confirm: the row it replaces, then the question"
      spacing: root.theme.space(8)
      UConfirmSheet {
        theme: root.theme
        width: parent.width
        sentence: "Remove Ana? Her face data is erased."
        verb: "Remove Ana"
        destructive: true
        asking: true
      }
      UConfirmSheet {
        theme: root.theme
        width: parent.width
        sentence: "Remove Ana? Her face data is erased."
        verb: "Remove Ana"
        destructive: true
        UButton { text: "Remove Ana"; kind: "destructive"; theme: root.theme; anchors.right: parent.right }
      }
    }

    USection {
      theme: root.theme
      title: "Tips: float (standalone) and the foot line (notch)"
      Item {
        width: parent.width
        height: root.theme.rowHeight + 44
        UButton {
          id: tipTarget
          theme: root.theme
          text: "Hover me"
          UTip { theme: root.theme; text: "Switches to the other profile."; armedHover: true }
        }
        UTip { theme: root.theme; line: true; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
          Component.onCompleted: root.theme.foot = "Shows the date next to the time." }
      }
    }

    USection {
      theme: root.theme
      title: "Contrast, measured from the roles in this mode"
      Column {
        width: parent.width
        height: childrenRect.height
        Repeater {
          model: root.theme ? Tokens.check(root.theme.roles) : []
          Item {
            id: ratio
            required property var modelData
            width: parent ? parent.width : 0
            height: root.theme.footnoteSize + 4
            Text {
              anchors.left: parent.left
              text: ratio.modelData.name
              color: root.theme.secondary
              font.family: root.theme.fontFamily
              font.pixelSize: root.theme.footnoteSize
            }
            Text {
              anchors.right: parent.right
              text: ratio.modelData.ratio.toFixed(2) + " : 1   (" + ratio.modelData.floor + ")   " + (ratio.modelData.pass ? "ok" : "FAIL")
              color: root.theme.label
              font.family: root.theme.fontFamily
              font.pixelSize: root.theme.footnoteSize
            }
          }
        }
      }
    }
  }
}
