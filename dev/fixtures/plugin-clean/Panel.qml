import QtQuick
import "ui"

// A plugin panel that follows the kit: nothing in it the gate rejects, and a
// `theme` property for the walk to hand a fake host to. dev/test.sh vendors
// the kit into a copy of this folder with sync-ui.sh and runs check-ui.sh on it.
Item {
  id: root
  property var theme: null
  implicitWidth: 420
  implicitHeight: 260

  UKeys {
    anchors.fill: parent
    focus: true
    level: "back"
    open: false
    onCloseRequested: console.log("close")

    Column {
      x: 16
      y: 16
      width: root.implicitWidth - 32
      Item {
        width: parent.width
        height: root.theme.rowHeight
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "Corners"
          color: root.theme.label
          font.family: root.theme.fontFamily
          font.pixelSize: root.theme.titleSize
          font.weight: root.theme.titleWeight
        }
        UClose { theme: root.theme; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
      }
      USection {
        theme: root.theme
        title: "Shape"
        first: true
        URow { theme: root.theme; label: "Follow the screen"; USwitch { theme: root.theme; label: "Follow the screen"; checked: true } }
        URow { theme: root.theme; label: "Radius"; UStepper { theme: root.theme; label: "Radius"; from: 0; to: 40; value: 12; unit: " px" } }
      }
      Item { width: 1; height: root.theme.space(16) }
      Row {
        spacing: root.theme.space(8)
        anchors.right: parent.right
        UButton { theme: root.theme; text: "Cancel" }
        UButton { theme: root.theme; text: "Done"; kind: "primary" }
      }
    }
  }
}
