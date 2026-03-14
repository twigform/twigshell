import QtQuick 2.15
import QtQuick.Controls 2.15
import Quickshell.Io

Item {
    id: root

    anchors {
        verticalCenter: parent.verticalCenter
    }

    implicitWidth: 54
    implicitHeight: 25

    property string targetScreenName: ""

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutCubic
        }
    }

    property int volumeLevel: 0
    property int previousVolumeLevel: -1
    property bool volumePillExpanded: false

    function pulseVolumePill() {
        volumePillExpanded = true;
        pillCollapseTimer.restart();
    }

    onVolumeLevelChanged: {
        if (previousVolumeLevel !== -1 && previousVolumeLevel !== volumeLevel)
            pulseVolumePill();
        previousVolumeLevel = volumeLevel;
    }

    Process {
        id: getVolumeProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: SplitParser {
            onRead: function (data) {
                let match = data.match(/Volume:\s*([0-9.]+)/);
                if (match) {
                    root.volumeLevel = Math.round(parseFloat(match[1]) * 100);
                }
            }
        }
    }

    Process {
        id: setVolumeProc
        property int targetVolume: 0
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (targetVolume / 100).toFixed(2)]
        running: false
        onTargetVolumeChanged: {
            command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (targetVolume / 100).toFixed(2)];
        }
        function setVolume(vol) {
            targetVolume = vol;
            running = true;
        }
    }

    Timer {
        interval: 200
        repeat: true
        running: true
        onTriggered: getVolumeProc.running = true
    }

    Timer {
        id: pillCollapseTimer
        interval: 600
        repeat: false
        onTriggered: root.volumePillExpanded = false
    }

    Rectangle {
        anchors.fill: parent
        // color: colors.surface_container_highest
        // radius: 20
        // anchors.margins: 2
        color: "transparent"

        Row {
            anchors.centerIn: parent
            spacing: 8

            Text {
                id: volumeIcon
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (volumeLevel === 0)
                        return "";
                    if (volumeLevel < 50)
                        return "";
                    return "";
                }
                color: colors.on_background
                font.family: styles.fontFamily
                font.bold: true
                font.pixelSize: 16
            }

            Rectangle {
                id: volumePillTrack
                anchors.verticalCenter: parent.verticalCenter
                width: root.volumePillExpanded ? 8 : 4
                height: 18
                radius: width / 2
                color: Qt.rgba(colors.secondary_container.r, colors.secondary_container.g, colors.secondary_container.b, 0.75)
                clip: true

                Behavior on width {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: Math.max(2, parent.height * Math.max(0, Math.min(100, root.volumeLevel)) / 100)
                    radius: parent.radius
                    color: colors.primary

                    Rectangle {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        height: Math.min(parent.radius, parent.height)
                        color: parent.color
                        visible: root.volumeLevel < 98
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.NoButton
            onClicked: {
                osdBridge.toggleMediaOsd(root.targetScreenName);
            }
            onWheel: function (wheel) {
                let delta = wheel.angleDelta.y > 0 ? 5 : -5;
                let newVolume = Math.max(0, Math.min(100, root.volumeLevel + delta));
                if (newVolume !== root.volumeLevel) {
                    root.volumeLevel = newVolume;
                    setVolumeProc.setVolume(newVolume);
                    root.pulseVolumePill();
                }
            }
        }
    }
}
