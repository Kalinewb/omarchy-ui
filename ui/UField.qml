import QtQuick

// One line of text (plan-apple-ui.md 4.2). Enter commits, Esc reverts to the
// last committed value (the "edit" layer of UKeys: while there is a change
// not yet committed, Esc is the field's, and the panel does not close).
//
//   UField { theme: theme; label: "Name"; value: saved; onCommitted: function(t) { saved = t } }
Item {
  id: root
  required property var theme
  // The accessible name, and what the placeholder says when `placeholder` is empty.
  property string label: ""
  property string placeholder: ""
  // The committed text; the owner updates it from `committed`.
  property string value: ""
  property string tip: ""
  property alias input: edit
  signal committed(string text)

  property bool hot: mouse.containsMouse
  property bool showFocus: edit.activeFocus
  readonly property bool dirty: edit.text !== value

  implicitWidth: 200
  implicitHeight: theme.controlHeight

  Rectangle {
    anchors.fill: parent
    radius: root.theme.radius(height)
    color: root.showFocus || root.hot ? root.theme.hover : root.theme.fill
    border.width: root.showFocus ? 2 : root.theme.hairlineWidth
    border.color: root.showFocus ? root.theme.ring : root.theme.hairline
    property bool uiMark: true
    Behavior on color { ColorAnimation { duration: root.theme.focusMs } }
    Behavior on border.color { ColorAnimation { duration: root.theme.focusMs } }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
    cursorShape: Qt.IBeamCursor
  }

  TextInput {
    id: edit
    anchors.fill: parent
    anchors.leftMargin: root.theme.space(12)
    anchors.rightMargin: root.theme.space(12)
    verticalAlignment: TextInput.AlignVCenter
    clip: true
    text: root.value
    color: root.enabled ? root.theme.label : root.theme.disabled
    selectionColor: root.theme.accent
    selectedTextColor: root.theme.knobOn
    font.family: root.theme.fontFamily
    font.pixelSize: root.theme.bodySize
    activeFocusOnTab: root.enabled
    Accessible.role: Accessible.EditableText
    Accessible.name: root.label
    onAccepted: root.committed(text)
    // The owner moved `value`: show it, unless the person is mid-edit.
    Connections { target: root; function onValueChanged() { edit.text = root.value } }

    Text {
      anchors.fill: parent
      verticalAlignment: Text.AlignVCenter
      visible: edit.text === "" && !edit.activeFocus
      text: root.placeholder !== "" ? root.placeholder : root.label
      color: root.theme.secondary
      font: edit.font
    }
  }

  UKeys { level: "edit"; open: root.dirty && edit.activeFocus; onEscaped: edit.text = root.value }
  UTip { theme: root.theme; text: root.tip; target: edit }
}
