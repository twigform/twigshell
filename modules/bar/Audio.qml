import QtQuick 2.15
import QtQuick.Controls 2.15
import Quickshell.Io

Item {
    id: root

    anchors {
        verticalCenter: parent.verticalCenter
    }

    // width: 70
    width: volumeText.implicitWidth + 30
    height: 25

    property int volumeLevel: 0

    Process {
        id: getVolumeProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: SplitParser {
            onRead: function(data) {
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

    Component.onCompleted: getVolumeProc.running = true;

    Rectangle {
        anchors.fill: parent
        // color: colors.surface_container_highest
        // radius: 20
        // anchors.margins: 2        
        color: "transparent"

        Text {
            id: volumeText
            anchors.centerIn: parent
            text: {
                let icon = "";
                if (volumeLevel === 0) {
                    icon = "";
                } else if (volumeLevel < 50) {
                    icon = "";
                } else {
                    icon = "";
                }
                return icon + "    " + volumeLevel + "%";
            }
            color: colors.on_background
            font.family: "Google Sans Flex"
            font.variableAxes: {
                "ROND": 100,
                "wght": 650
            }
            font.pixelSize: 16
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.NoButton
            onClicked: {
                launchWiremixProc.running = true;
            }
            onWheel: function(wheel) {
                let delta = wheel.angleDelta.y > 0 ? 5 : -5;
                let newVolume = Math.max(0, Math.min(100, root.volumeLevel + delta));
                if (newVolume !== root.volumeLevel) {
                    root.volumeLevel = newVolume;
                    setVolumeProc.setVolume(newVolume);
                }
            }
        }
        Process {
            id: launchWiremixProc
            command: ["kitty", "wiremix"]
            running: false
        }
    }
}
