import QtQuick
import "../ui"
import "../common"

// A view in a folder of its own, importing the kit and a sibling folder, as a plugin's views/ do.
Item {
  id: view
  required property var theme
  implicitWidth: 388
  implicitHeight: section.implicitHeight

  // A *Row component is allowed when its root is a URow (the gate once flagged this one).
  component NamedRow: URow {}

  USection {
    id: section
    theme: view.theme
    width: parent.width
    title: Strings.heading
    first: true
    NamedRow { theme: view.theme; label: "Corners"; value: "Rounded" }
    URow { theme: view.theme; label: "Follow the screen"; USwitch { theme: view.theme; label: "Follow the screen"; checked: true } }
    URow { theme: view.theme; label: "Radius"; UStepper { theme: view.theme; label: "Radius"; from: 0; to: 40; value: 12; unit: " px" } }
  }
}
