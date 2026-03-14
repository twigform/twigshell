import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    anchors.bottom: true
    anchors.left: true
    margins.bottom: 0
    margins.left: 4

    implicitWidth: popupShown ? 152 : 0
    implicitHeight: popupShown ? 152 : 0
    color: "transparent"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    property int volumeLevel: 0
    property int lastVolume: -1
    property bool ready: false
    property bool popupShown: false
    property real displayVolume: 0

    onVolumeLevelChanged: displayVolume = volumeLevel

    Behavior on displayVolume {
        NumberAnimation {
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    Process {
        id: getVol
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: SplitParser {
            onRead: function (line) {
                let m = line.match(/Volume:\s*([0-9.]+)/);
                if (!m)
                    return;
                let v = Math.max(0, Math.min(Math.round(parseFloat(m[1]) * 100), 100));
                if (root.ready && v !== root.lastVolume) {
                    root.volumeLevel = v;
                    popup.show();
                } else {
                    root.volumeLevel = v;
                }
                root.lastVolume = v;
            }
        }
    }

    Timer {
        interval: 200
        repeat: true
        running: true
        onTriggered: getVol.running = true
    }

    Timer {
        interval: 1000
        running: true
        onTriggered: root.ready = true
    }

    Item {
        id: popup
        anchors.fill: parent
        opacity: 0
        scale: 0.85

        Behavior on opacity {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutExpo
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutBack
            }
        }

        Timer {
            id: hideTimer
            interval: 2200
            onTriggered: popup.hide()
        }

        Timer {
            id: collapseTimer
            interval: 360
            onTriggered: root.popupShown = false
        }

        function show() {
            collapseTimer.stop();
            root.popupShown = true;
            hideTimer.restart();
            popup.opacity = 1.0;
            popup.scale = 1.0;
        }

        function hide() {
            hideTimer.stop();
            popup.opacity = 0;
            popup.scale = 0.85;
            collapseTimer.restart();
        }

        Rectangle {
            width: 140
            height: 140
            radius: width / 2
            anchors.centerIn: parent
            color: colors.surface

            Canvas {
                id: ringCanvas
                anchors.fill: parent
                anchors.margins: 8
                antialiasing: true

                onPaint: {
                    let ctx = getContext("2d");
                    let w = width;
                    let h = height;
                    let size = Math.min(w, h);
                    let centerX = w / 2;
                    let centerY = h / 2;
                    let radius = (size / 2) - 6;
                    let start = -Math.PI / 2;
                    let progress = Math.max(0, Math.min(root.displayVolume / 100, 1.0));

                    ctx.clearRect(0, 0, w, h);
                    ctx.lineWidth = 6;
                    ctx.lineCap = "round";

                    ctx.strokeStyle = colors.secondary_container;
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, radius, 0, Math.PI * 2, false);
                    ctx.stroke();

                    if (progress > 0) {
                        ctx.strokeStyle = colors.primary;
                        ctx.beginPath();
                        ctx.arc(centerX, centerY, radius, start, start + (Math.PI * 2 * progress), false);
                        ctx.stroke();
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: Math.round(root.displayVolume) + "%"
                color: colors.on_surface
                font.family: styles.fontFamily
                font.bold: true
                font.pixelSize: 26
            }

            Connections {
                target: root
                function onDisplayVolumeChanged() {
                    ringCanvas.requestPaint();
                }
            }

            Component.onCompleted: ringCanvas.requestPaint()
        }
    }
}
