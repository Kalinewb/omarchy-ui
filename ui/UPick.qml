pragma ComponentBehavior: Bound
import QtQuick
import "keys.js" as KeyMap

// Three or more options, or long ones (plan-apple-ui.md 4.2). Written new over
// the look of Omarchy's Dropdown (ConfigView.qml:395); no notch code seeded it.
// Opens a list under the control, drawn over its siblings and clipped by
// nothing the kit owns; Esc (the "pick" layer of UKeys), picking a row, or
// leaving the control closes it. Down, Space, Enter and Right open it; Up and
// Down move; Enter picks.
Item {
  id: root
  required property var theme
  property var options: []
  property string value: ""
  property string label: ""
  property string tip: ""
  property bool open: false
  signal picked(string value)

  property bool hot: mouse.containsMouse
  property bool showFocus: activeFocus
  property int cursor: -1

  readonly property int index: {
    for (var i = 0; i < options.length; i++) if (options[i].value === value) return i
    return -1
  }
  readonly property string shown: index >= 0 ? options[index].label : ""

  implicitWidth: 200
  implicitHeight: theme.controlHeight
  activeFocusOnTab: enabled
  z: open ? 1000 : 0
  Accessible.role: Accessible.ComboBox
  Accessible.name: label
  onActiveFocusChanged: if (!activeFocus) open = false
  onOpenChanged: if (open) cursor = index >= 0 ? index : 0

  Rectangle {
    anchors.fill: parent
    radius: root.theme.radius(height)
    color: root.open || root.hot ? root.theme.hover : root.theme.fill
    border.width: root.showFocus ? 2 : root.theme.hairlineWidth
    border.color: root.showFocus ? root.theme.ring : root.theme.hairline
    property bool uiMark: true
    Behavior on color { ColorAnimation { duration: root.theme.focusMs } }
    Behavior on border.color { ColorAnimation { duration: root.theme.focusMs } }
  }
  Text {
    anchors.left: parent.left
    anchors.right: chevron.left
    anchors.leftMargin: root.theme.space(12)
    anchors.verticalCenter: parent.verticalCenter
    text: root.shown
    elide: Text.ElideRight
    color: root.enabled ? root.theme.label : root.theme.disabled
    font.family: root.theme.fontFamily
    font.pixelSize: root.theme.bodySize
  }
  Text {
    id: chevron
    anchors.right: parent.right
    anchors.rightMargin: root.theme.space(12)
    anchors.verticalCenter: parent.verticalCenter
    text: root.open ? "▴" : "▾"
    color: root.theme.secondary
    font.family: root.theme.fontFamily
    font.pixelSize: root.theme.footnoteSize
  }
  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.open = !root.open
  }

  // The list: solid, level 2, a hairline.
  Rectangle {
    id: list
    visible: root.open
    y: root.height + root.theme.space(4)
    width: root.width
    height: root.options.length * root.theme.rowHeight + 2 * root.theme.hairlineWidth
    radius: root.theme.radius(root.theme.rowHeight)
    color: root.theme.raised
    border.width: root.theme.hairlineWidth
    border.color: root.theme.hairline
    property bool uiMark: true
    Column {
      anchors.fill: parent
      anchors.margins: root.theme.hairlineWidth
      Repeater {
        model: root.options
        Item {
          id: choice
          required property var modelData
          required property int index
          readonly property bool chosen: index === root.index
          width: list.width - 2 * root.theme.hairlineWidth
          height: root.theme.rowHeight
          Accessible.role: Accessible.ListItem
          Accessible.name: modelData.label
          Accessible.onPressAction: root.choose(index)
          Rectangle {
            anchors.fill: parent
            radius: list.radius
            color: root.cursor === choice.index || rowMouse.containsMouse ? root.theme.hover : root.theme.none
          }
          Text {
            anchors.left: parent.left
            anchors.leftMargin: root.theme.space(12)
            anchors.verticalCenter: parent.verticalCenter
            text: choice.modelData.label
            color: root.theme.label
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.bodySize
            font.weight: choice.chosen ? root.theme.headlineWeight : Font.Normal
          }
          Text {
            anchors.right: parent.right
            anchors.rightMargin: root.theme.space(12)
            anchors.verticalCenter: parent.verticalCenter
            visible: choice.chosen
            text: "✓"
            color: root.theme.accentText
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.bodySize
          }
          MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.cursor = choice.index
            onClicked: root.choose(choice.index)
          }
        }
      }
    }
  }

  function choose(i) {
    open = false
    if (i >= 0 && i < options.length) picked(options[i].value)
  }

  Keys.onPressed: function(event) {
    var a = KeyMap.action(open ? "pickOpen" : "pick", event.key)
    if (a === "none") return
    event.accepted = true
    if (a === "open") open = true
    else if (a === "prev") cursor = KeyMap.step(cursor, -1, 0, options.length - 1)
    else if (a === "next") cursor = KeyMap.step(cursor, 1, 0, options.length - 1)
    else if (a === "first") cursor = 0
    else if (a === "last") cursor = options.length - 1
    else if (a === "activate") choose(cursor)
  }

  UKeys { level: "pick"; open: root.open; onEscaped: root.open = false }
  UTip { theme: root.theme; text: root.tip; enabled: !root.open }
}
