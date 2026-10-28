import QtQuick

// An inline notice: what happened and what to do, in one place on the page
// (plan-apple-ui.md 4.2 "Error"). The sentence comes from the plugin's own
// table (errors.js); an unknown code reads "Something went wrong." and the
// code appears only under Details. A code never reaches the surface any other
// way. The mark is a glyph in a ring as well as a colour, so the state never
// rests on colour alone.
//
//   UNotice { theme: theme; text: errors.message(code); details: errors.details(code)
//             actionText: "Try again"; onActed: retry() }
Rectangle {
  id: root
  required property var theme
  // "warn" or "info"
  property string tone: "warn"
  property string text: ""
  property string details: ""
  // One recovery verb, "Try again", or empty.
  property string actionText: ""
  property bool showDetails: false
  signal acted()

  readonly property color ink: tone === "warn" ? theme.destructive : theme.label

  implicitWidth: 360
  implicitHeight: column.implicitHeight + 2 * theme.space(8)
  radius: theme.radius(Math.min(height, theme.rowHeight))
  color: theme.fill
  Accessible.role: Accessible.StaticText
  Accessible.name: text

  Column {
    id: column
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.margins: root.theme.space(12)
    spacing: root.theme.space(4)

    Row {
      spacing: root.theme.space(8)
      Rectangle {
        id: mark
        width: 20
        height: 20
        radius: width / 2
        color: root.theme.none
        border.width: root.theme.hairlineWidth
        border.color: root.ink
        property bool uiMark: true
        Text {
          anchors.centerIn: parent
          text: root.tone === "warn" ? "!" : "i"
          color: root.ink
          font.family: root.theme.fontFamily
          font.pixelSize: root.theme.footnoteSize
          font.weight: root.theme.headlineWeight
        }
      }
      Text {
        width: column.width - mark.width - parent.spacing
        text: root.text
        wrapMode: Text.WordWrap
        color: root.theme.label
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.bodySize
      }
    }
    Row {
      leftPadding: mark.width + root.theme.space(8)
      spacing: root.theme.space(8)
      visible: root.actionText !== "" || root.details !== ""
      UButton {
        theme: root.theme
        visible: root.actionText !== ""
        kind: "link"
        text: root.actionText
        onClicked: root.acted()
      }
      UButton {
        theme: root.theme
        visible: root.details !== ""
        kind: "link"
        text: root.showDetails ? "Hide details" : "Details"
        onClicked: root.showDetails = !root.showDetails
      }
    }
    Text {
      visible: root.showDetails && root.details !== ""
      x: mark.width + root.theme.space(8)
      width: column.width - x
      text: root.details
      wrapMode: Text.WrapAnywhere
      color: root.theme.secondary
      font.family: root.theme.fontFamily
      font.pixelSize: root.theme.footnoteSize
    }
  }
}
