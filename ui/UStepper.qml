import QtQuick
import "keys.js" as KeyMap

// A number with a minus and a plus (plan-apple-ui.md 4.2); one tab stop,
// Left and Right step it. Replaces text "-" / "+" and per-plugin number fields.
// It asks (`modified(next)`), the owner sets `value`.
//
//   UStepper { theme: theme; label: "Radius"; from: 0; to: 40; value: radius; unit: " px"
//              onModified: function(v) { radius = v } }
Item {
  id: root
  required property var theme
  property string label: ""
  property int value: 0
  property int from: 0
  property int to: 100
  property int stepSize: 1
  // Shown after the number: " px".
  property string unit: ""
  property string tip: ""
  signal modified(int value)

  property bool showFocus: activeFocus
  property bool hotMinus: minus.containsMouse
  property bool hotPlus: plus.containsMouse

  implicitHeight: theme.controlHeight
  implicitWidth: 2 * theme.controlHeight + Math.max(56, number.implicitWidth + 2 * theme.space(8))
  activeFocusOnTab: enabled
  Accessible.role: Accessible.SpinBox
  Accessible.name: label + " " + value + unit
  Accessible.onIncreaseAction: root.nudge(1)
  Accessible.onDecreaseAction: root.nudge(-1)

  function nudge(direction) {
    var next = KeyMap.step(value, direction * stepSize, from, to)
    if (next !== value) modified(next)
  }

  Rectangle {
    anchors.fill: parent
    radius: root.theme.radius(height)
    color: root.theme.fill
    border.width: root.showFocus ? 2 : root.theme.hairlineWidth
    border.color: root.showFocus ? root.theme.ring : root.theme.hairline
    property bool uiMark: true
    Behavior on border.color { ColorAnimation { duration: root.theme.focusMs } }
  }

  // Minus
  Rectangle {
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: 2
    width: root.height - 4
    height: root.height - 4
    radius: root.theme.radius(height)
    enabled: root.value > root.from
    color: minus.pressed ? root.theme.pressed : (root.hotMinus ? root.theme.hover : root.theme.none)
    Text {
      anchors.centerIn: parent
      text: "−"
      color: parent.enabled && root.enabled ? root.theme.label : root.theme.disabled
      font.family: root.theme.fontFamily
      font.pixelSize: root.theme.titleSize
    }
    MouseArea {
      id: minus
      anchors.fill: parent
      anchors.margins: -2   // the hit target is the whole cell
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.nudge(-1)
    }
  }

  Text {
    id: number
    anchors.centerIn: parent
    text: root.value + root.unit
    color: root.enabled ? root.theme.label : root.theme.disabled
    font.family: root.theme.fontFamily
    font.pixelSize: root.theme.bodySize
    font.weight: root.theme.headlineWeight
  }

  // Plus
  Rectangle {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.rightMargin: 2
    width: root.height - 4
    height: root.height - 4
    radius: root.theme.radius(height)
    enabled: root.value < root.to
    color: plus.pressed ? root.theme.pressed : (root.hotPlus ? root.theme.hover : root.theme.none)
    Text {
      anchors.centerIn: parent
      text: "+"
      color: parent.enabled && root.enabled ? root.theme.label : root.theme.disabled
      font.family: root.theme.fontFamily
      font.pixelSize: root.theme.titleSize
    }
    MouseArea {
      id: plus
      anchors.fill: parent
      anchors.margins: -2   // the hit target is the whole cell
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.nudge(1)
    }
  }

  Keys.onPressed: function(event) {
    var a = KeyMap.action("stepper", event.key)
    if (a === "none") return
    root.nudge(a === "inc" ? 1 : -1)
    event.accepted = true
  }
  UTip { theme: root.theme; text: root.tip }
}
