import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

// Every kind of thing the gate rejects, once. Never shipped.
Item {
  component MySwitch: Item {}
  component LabelRow: Item {}
  Text { font.pixelSize: 13 }
  Rectangle { color: "#ff0000"; radius: 4 }
  Rectangle { color: Qt.rgba(1, 1, 1, 0.5) }
  Behavior on x { NumberAnimation { duration: 120 } }
  Text { font.pixelSize: Style.font.caption }
  ConfirmDialog { }
  Button { text: "Close" }
  TextField { }
  Text { label: "Dismiss" }
  Keys.onEscapePressed: console.log("raw esc")
  Item { focus: true; Keys.onPressed: function(e) { if (e.key === Qt.Key_Escape) console.log("raw") } }
  Rectangle { radius: 3 }   // ui-allow: a shape under a mask
}
