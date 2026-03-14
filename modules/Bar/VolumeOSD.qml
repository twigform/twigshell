import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    anchors.top: true
    anchors.right: true
    margins.top: 35
    margins.right: 2

    implicitWidth: popupShown ? 280 : 0
    implicitHeight: popupShown ? 68 : 0
    color: "transparent"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    property int volumeLevel: 0
    property int lastVolume: -1
    property bool ready: false
    property bool popupShown: false

    Process {
        id: getVol
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: SplitParser {
            onRead: function (line) {
                let m = line.match(/Volume:\s*([0-9.]+)/);
                if (!m)
                    return;
                let v = Math.round(parseFloat(m[1]) * 100);
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
            anchors.fill: parent
            anchors.margins: 6
            radius: styles.bRadius
            color: colors.surface
            border.color: colors.outline_variant
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 8

                Text {
                    text: {
                        if (root.volumeLevel === 0)
                            return "";
                        if (root.volumeLevel < 50)
                            return "";
                        return "";
                    }
                    color: colors.primary
                    font.family: styles.fontFamily
                    font.bold: true
                    font.variableAxes: {
                        "ROND": 100,
                        "wght": 500
                    }
                    font.pixelSize: 20
                    Layout.alignment: Qt.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                    height: 44
                    Layout.alignment: Qt.AlignVCenter

                    readonly property real handleW: 4
                    readonly property real gap: 5
                    readonly property real handleCenter: width * Math.min(root.volumeLevel / 100, 1.0)

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 0
                        width: Math.max(0, parent.handleCenter - parent.handleW / 2 - parent.gap)
                        height: 12
                        topLeftRadius: 6
                        bottomLeftRadius: 6
                        topRightRadius: 2
                        bottomRightRadius: 2
                        color: colors.primary
                        visible: width > 0

                        Behavior on width {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutExpo
                            }
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: parent.handleCenter + parent.handleW / 2 + parent.gap
                        width: Math.max(0, parent.width - x)
                        height: 12
                        topLeftRadius: 2
                        bottomLeftRadius: 2
                        topRightRadius: 6
                        bottomRightRadius: 6
                        color: colors.secondary_container
                        visible: width > 0

                        Behavior on x {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutExpo
                            }
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: parent.handleCenter - width / 2
                        width: 4
                        height: 32
                        radius: 2
                        color: colors.primary

                        Behavior on x {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutExpo
                            }
                        }
                    }
                }

                Text {
                    text: root.volumeLevel + "%"
                    color: colors.on_surface
                    font.family: styles.fontFamily
                    font.bold: true
                    font.variableAxes: {
                        "ROND": 100,
                        "wght": 650
                    }
                    font.pixelSize: 16
                    Layout.minimumWidth: 38
                    horizontalAlignment: Text.AlignRight
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}
