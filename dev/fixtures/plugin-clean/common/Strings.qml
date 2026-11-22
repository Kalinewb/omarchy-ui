pragma Singleton
import QtQuick

// A singleton in another folder, with the qmldir next to it: the walk has to reach it.
QtObject {
  readonly property string heading: "Shape"
}
