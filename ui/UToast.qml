import QtQuick

// The one toast (plan-apple-ui.md 4.2 "Toast / notice"): a line on a raised,
// solid box, with at most one action and "Not now" to put it off. With an
// action it stays until acted on or put off; without one it stays 6 s,
// paused while the pointer is over it or a button in it has focus. The
// acknowledgement of an action is this, or the same line in secondary inline;
// never a 3 s note that is the only sign anything happened.
//
//   UToast { id: toast; theme: theme }
//   toast.show("Profile saved")
//   toast.show("Ana removed", "Undo")        // onActed, onDismissed
Item {
  id: root
  required property var theme
  property string text: ""
  // One verb ("Undo", "Open setup"), or empty.
  property string actionText: ""
  property bool shown: false
  signal acted()
  signal dismissed()

  readonly property bool paused: hoverArea.containsMouse || action.activeFocus || notNow.activeFocus

  function show(line, actionLabel) {
    text = line
    actionText = actionLabel || ""
    shown = true
    if (actionText === "") timeout.restart()
    else timeout.stop()
  }
  function hide() { shown = false; timeout.stop(); dismissed() }
  // Hovering or focusing the toast holds the 6 s; leaving starts them again.
  onPausedChanged: if (shown && actionText === "") { if (paused) timeout.stop(); else timeout.restart() }

  implicitWidth: box.width
  implicitHeight: box.height
  visible: box.opacity > 0
  Accessible.role: Accessible.AlertMessage
  Accessible.name: text

  Timer { id: timeout; interval: 6000; onTriggered: root.hide() }

  Rectangle {
    id: box
    opacity: root.shown ? 1 : 0
    // Arrives on the spring, leaves on OutCubic and shorter; with reduced motion only the fade remains.
    property real rise: root.shown ? 0 : root.theme.space(12)
    transform: Translate { y: box.rise }
    width: content.implicitWidth + 2 * root.theme.space(12)
    height: Math.max(root.theme.rowHeight, content.implicitHeight) + 2 * root.theme.space(4)
    radius: root.theme.radius(height)
    color: root.theme.raised
    Behavior on opacity { NumberAnimation { duration: root.shown ? root.theme.fadeInMs : root.theme.fadeOutMs; easing.type: Easing.OutCubic } }
    Behavior on rise {
      NumberAnimation {
        duration: root.shown ? root.theme.arriveMs : root.theme.exitMs
        easing.type: root.shown ? Easing.BezierSpline : Easing.OutCubic
        easing.bezierCurve: root.theme.arriveCurve
      }
    }

    MouseArea { id: hoverArea; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }

    Row {
      id: content
      anchors.centerIn: parent
      spacing: root.theme.space(8)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: root.theme.label
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.bodySize
      }
      UButton {
        id: action
        theme: root.theme
        visible: root.actionText !== ""
        kind: "link"
        text: root.actionText
        anchors.verticalCenter: parent.verticalCenter
        onClicked: { root.shown = false; timeout.stop(); root.acted() }
      }
      UButton {
        id: notNow
        theme: root.theme
        visible: root.actionText !== ""
        text: "Not now"
        anchors.verticalCenter: parent.verticalCenter
        onClicked: root.hide()
      }
    }
  }
}
