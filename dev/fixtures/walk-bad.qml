import QtQuick
import "../../ui"

// A root the walk must reject, once for each clause of rule 5. Never shipped:
// dev/test.sh runs it and expects every one of these to be reported.
Item {
  id: root
  property var theme: null
  implicitWidth: 400
  implicitHeight: 200

  // names + hit: focusable, 18 px, no Accessible.name
  Item { x: 10; y: 10; width: 18; height: 18; activeFocusOnTab: true }

  // hit: a primary shorter than the row
  UButton { x: 40; y: 10; theme: root.theme; kind: "primary"; text: "Save"; height: 20 }

  // text: 9 px
  Text { x: 10; y: 50; text: "Too small"; color: root.theme.label; font.pixelSize: 9 }

  // contrast: text one step off the surface
  Text { x: 10; y: 80; text: "Invisible words"; color: Qt.rgba(root.theme.surface.r + 0.04, root.theme.surface.g + 0.04, root.theme.surface.b + 0.04, 1); font.pixelSize: 13 }

  // opaque (contract 1): a translucent fill
  Rectangle { x: 10; y: 110; width: 80; height: 20; color: Qt.rgba(1, 1, 1, 0.5) }

  // loops: an endless animation under reduced motion
  Rectangle {
    x: 120; y: 110; width: 20; height: 20; color: root.theme.label
    RotationAnimation on rotation { from: 0; to: 360; duration: 900; loops: Animation.Infinite; running: true }
  }
}
