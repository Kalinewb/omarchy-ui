import QtQuick

// The surface of UTheme that the kit's components read, with fixed values, so
// the behaviour tests run under qmltestrunner with no Quickshell and no
// qs.Commons. dev/tests/theme-surface.mjs keeps it honest: every `theme.<name>`
// any ui/ file reads must be declared here and in UTheme.qml.
QtObject {
  property string mode: "standalone"
  property string density: "standalone"
  property bool reduced: false

  property color surface: "#000000"
  property color label: "#ffffff"
  property color secondary: "#8d8d93"
  property color accent: "#ffffff"
  property color accentText: "#ffffff"
  property color destructive: "#ff6b6b"
  property color fill: "#0a0a0a"
  property color hover: "#141414"
  property color selected: "#2e2e2e"
  property color pressed: "#383838"
  property color raised: "#141414"
  property color hairline: "#6e6e6e"
  property color ring: "#8e8e8e"
  property color trackOn: "#ffffff"
  property color knobOn: "#000000"
  property color trackOff: "#0a0a0a"
  property color knobOff: "#8d8d93"
  property color disabled: "#5e5e5e"
  readonly property color none: "transparent"

  property string fontFamily: "monospace"
  property int bodySize: 13
  property int titleSize: 14
  property int footnoteSize: 11
  property int headlineWeight: Font.DemiBold
  property int titleWeight: Font.DemiBold

  property int minHit: 24
  property int rowHeight: 32
  property int controlHeight: 28
  property int switchWidth: 42
  property int switchHeight: 22
  property int hairlineWidth: 1
  property int tipMax: 60
  function space(n) { return n }
  function radius(h) { return Math.min(10, h / 2) }

  property var arriveCurve: [0.3, 0.5, 0.7, 1.0, 1, 1]
  property var controlCurve: [0.3, 0.5, 0.7, 1.0, 1, 1]
  property var celebrateCurve: [0.3, 0.5, 0.7, 1.0, 1, 1]
  property int arriveMs: reduced ? 0 : 350
  property int controlMs: reduced ? 0 : 200
  property int celebrateMs: reduced ? 0 : 450
  property int exitMs: reduced ? 0 : 180
  property int fadeOutMs: 90
  property int fadeInMs: 150
  property int focusMs: 90
  property real pressScale: reduced ? 1 : 0.97
  property int pressMs: reduced ? 0 : 60
  property int ringMs: 900
  function staggerDelay(i) { return reduced ? 0 : Math.min(i * 40, 240) }
  property string foot: ""
}
