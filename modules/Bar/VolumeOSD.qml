import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    anchors.top: true
    anchors.right: true
    margins.top: baseTopMargin
    margins.right: baseRightMargin + rightOffset

    implicitWidth: popupShown ? 92 : 0
    implicitHeight: popupShown ? 228 : 0
    color: "transparent"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    readonly property string screenName: screen ? screen.name : ""
    readonly property int baseTopMargin: 45
    readonly property int baseRightMargin: 8
    readonly property int mediaAvoidDistance: 442
    readonly property real cornerRadius: styles.bRadius
    property int volumeLevel: 0
    property int lastVolume: -1
    property bool ready: false
    property bool popupShown: false
    property bool popupHovered: false
    property bool mediaOsdVisible: false
    property real displayVolume: 0
    property real rightOffset: mediaOsdVisible ? mediaAvoidDistance : 0

    onVolumeLevelChanged: displayVolume = volumeLevel

    function applyVolume(newVolume) {
        const boundedVolume = Math.max(0, Math.min(Math.round(newVolume), 100));

        if (boundedVolume === root.volumeLevel && boundedVolume === root.lastVolume)
            return;

        root.volumeLevel = boundedVolume;
        root.lastVolume = boundedVolume;
        setVol.setVolume(boundedVolume);
        popup.show();
    }

    Behavior on displayVolume {
        NumberAnimation {
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    Behavior on rightOffset {
        NumberAnimation {
            duration: 260
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

    Process {
        id: setVol
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
        onTriggered: getVol.running = true
    }

    Timer {
        interval: 1000
        running: true
        onTriggered: root.ready = true
    }

    Connections {
        target: osdBridge

        function onMediaOsdVisibilityChanged(requestedScreenName, visible) {
            if (requestedScreenName && requestedScreenName !== root.screenName)
                return;

            root.mediaOsdVisible = visible;
        }
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
            onTriggered: {
                if (root.popupHovered) {
                    hideTimer.restart();
                    return;
                }
                popup.hide();
            }
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
            id: card
            anchors.fill: parent
            radius: root.cornerRadius
            color: colors.surface

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onEntered: {
                    root.popupHovered = true;
                }
                onExited: {
                    root.popupHovered = false;
                    if (popup.opacity > 0)
                        hideTimer.restart();
                }
                onWheel: function (wheel) {
                    let delta = wheel.angleDelta.y > 0 ? 5 : -5;
                    root.applyVolume(root.volumeLevel + delta);
                }
            }

            Item {
                anchors.fill: parent
                anchors.margins: 18

                Text {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(root.displayVolume) + "%"
                    color: colors.on_surface
                    font.family: styles.fontFamily
                    font.bold: true
                    font.pixelSize: 16
                    font.variableAxes: {
                        "ROND": 100,
                        "wght": 650
                    }
                }

                Item {
                    id: sliderTrack
                    anchors.top: parent.top
                    anchors.topMargin: 34
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 32

                    readonly property real handleH: 4
                    readonly property real gap: 2
                    readonly property real progressRatio: Math.max(0, Math.min(root.displayVolume / 100, 1))
                    readonly property real handleCenter: Math.max(handleH / 2,
                        Math.min(height - (progressRatio * height), height - handleH / 2))

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 0
                        width: 12
                        height: Math.max(0, parent.handleCenter - parent.handleH / 2 - parent.gap)
                        topLeftRadius: 6
                        topRightRadius: 6
                        bottomLeftRadius: 2
                        bottomRightRadius: 2
                        color: colors.secondary_container
                        visible: height > 0

                        Behavior on height {
                            NumberAnimation { duration: 200; easing.type: Easing.OutExpo }
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.handleCenter + parent.handleH / 2 + parent.gap
                        width: 12
                        height: Math.max(0, parent.height - y)
                        topLeftRadius: 2
                        topRightRadius: 2
                        bottomLeftRadius: 6
                        bottomRightRadius: 6
                        color: colors.primary
                        visible: height > 0

                        Behavior on y {
                            NumberAnimation { duration: 200; easing.type: Easing.OutExpo }
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.handleCenter - height / 2
                        width: parent.width
                        height: parent.handleH
                        radius: 2
                        color: colors.primary

                        Behavior on y {
                            NumberAnimation { duration: 200; easing.type: Easing.OutExpo }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        function updateVolume(mouseY) {
                            const boundedY = Math.max(0, Math.min(mouseY, height));
                            const ratio = 1 - (boundedY / height);
                            root.applyVolume(ratio * 100);
                        }

                        onPressed: function (mouse) {
                            updateVolume(mouse.y);
                        }

                        onPositionChanged: function (mouse) {
                            if (pressed)
                                updateVolume(mouse.y);
                        }

                        onClicked: function (mouse) {
                            updateVolume(mouse.y);
                        }
                    }
                }
            }
        }
    }
}
