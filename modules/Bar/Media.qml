import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell.Services.Mpris

Item {
    id: root

    readonly property int maxTextWidth: 200
    readonly property int marqueeGap: 32
    readonly property int edgeFadeWidth: 18
    readonly property int leadingInset: 18

    anchors.verticalCenter: parent.verticalCenter

    property var currentPlayer: null

    readonly property bool hasPlayer: currentPlayer !== null
    readonly property bool isPlaying: hasPlayer &&
        currentPlayer.playbackState === MprisPlaybackState.Playing

    readonly property string trackTitle: hasPlayer
        ? (currentPlayer.trackTitle ?? "").replace(/(\r\n|\n|\r)/g, "")
        : ""
    readonly property string trackArtist: hasPlayer
        ? (currentPlayer.trackArtist ?? "")
        : ""

    readonly property string displayText: {
        if (!hasPlayer) return "";
        if (trackArtist && trackTitle) return trackTitle + " — " + trackArtist;
        return trackTitle || trackArtist;
    }

    implicitWidth: hasPlayer ? (mediaRow.implicitWidth + 16) : 0
    implicitHeight: 25
    opacity: hasPlayer ? 1.0 : 0.0
    visible: opacity > 0
    clip: true

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
    }
    Behavior on implicitWidth {
        NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
    }

    function updatePlayer() {
        if (!Mpris.players || !Mpris.players.values) {
            currentPlayer = null;
            return;
        }
        let players = Mpris.players.values;

        for (let i = 0; i < players.length; i++) {
            if (players[i] && players[i].playbackState === MprisPlaybackState.Playing) {
                currentPlayer = players[i];
                return;
            }
        }
        for (let i = 0; i < players.length; i++) {
            if (players[i] && players[i].canPlay) {
                currentPlayer = players[i];
                return;
            }
        }
        currentPlayer = null;
    }

    Component.onCompleted: updatePlayer()

    Connections {
        target: Mpris.players
        function onValuesChanged() { root.updatePlayer(); }
    }

    Connections {
        target: root.currentPlayer
        function onPlaybackStateChanged() { root.updatePlayer(); }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.updatePlayer()
    }

    RowLayout {
        id: mediaRow
        anchors.centerIn: parent
        spacing: 8

        Item {
            id: titleViewport
            clip: true
            implicitWidth: Math.min(root.maxTextWidth, titleMetrics.contentWidth)
            implicitHeight: titleMetrics.implicitHeight
            Layout.preferredWidth: implicitWidth
            Layout.maximumWidth: root.maxTextWidth
            Layout.alignment: Qt.AlignVCenter

            property bool shouldScroll: titleMetrics.contentWidth > width && root.displayText.length > 0
            property real marqueeOffset: 0
            property real cycleWidth: titleMetrics.contentWidth + root.marqueeGap + root.leadingInset

            onShouldScrollChanged: {
                if (!shouldScroll)
                    marqueeOffset = 0;
            }

            onWidthChanged: {
                if (!shouldScroll)
                    marqueeOffset = 0;
            }

            Connections {
                target: root

                function onDisplayTextChanged() {
                    titleViewport.marqueeOffset = 0;

                    if (titleViewport.shouldScroll && root.visible)
                        marqueeAnimation.restart();
                }
            }

            Text {
                id: titleMetrics
                text: root.displayText
                visible: false
                color: colors.on_background
                font.family: "Google Sans Flex"
                font.variableAxes: { "ROND": 100, "wght": 650 }
                font.pixelSize: 16
            }

            Item {
                anchors.fill: parent
                clip: true

                Text {
                    id: titleTextPrimary
                    x: titleViewport.shouldScroll ? (root.leadingInset - titleViewport.marqueeOffset) : 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.displayText
                    color: colors.on_background
                    font.family: "Google Sans Flex"
                    font.variableAxes: { "ROND": 100, "wght": 650 }
                    font.pixelSize: 16
                }

                Text {
                    id: titleTextSecondary
                    visible: titleViewport.shouldScroll
                    x: titleTextPrimary.x + titleViewport.cycleWidth
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.displayText
                    color: colors.on_background
                    font.family: "Google Sans Flex"
                    font.variableAxes: { "ROND": 100, "wght": 650 }
                    font.pixelSize: 16
                }
            }

            Rectangle {
                visible: titleViewport.shouldScroll
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: Math.min(root.edgeFadeWidth, titleViewport.width / 2)
                color: "transparent"
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: colors.background }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Rectangle {
                visible: titleViewport.shouldScroll
                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                }
                width: Math.min(root.edgeFadeWidth, titleViewport.width / 2)
                color: "transparent"
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: colors.background }
                }
            }

            SequentialAnimation on marqueeOffset {
                id: marqueeAnimation
                running: titleViewport.shouldScroll && root.visible
                loops: Animation.Infinite

                PauseAnimation { duration: 900 }
                NumberAnimation {
                    from: 0
                    to: titleViewport.cycleWidth
                    duration: Math.max(3500, titleViewport.cycleWidth * 32)
                    easing.type: Easing.Linear
                }
            }
        }

        Text {
            text: "󰒮"
            color: colors.on_background
            font.family: "Google Sans Flex"
            font.pixelSize: 14
            opacity: (root.hasPlayer && root.currentPlayer.canGoPrevious) ? 1.0 : 0.4
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.hasPlayer && root.currentPlayer.canGoPrevious)
                        root.currentPlayer.previous();
                }
            }
        }

        Text {
            text: root.isPlaying ? "" : ""
            color: colors.on_background
            font.family: "Google Sans Flex"
            font.pixelSize: 14
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!root.hasPlayer) return;
                    if (root.isPlaying && root.currentPlayer.canPause)
                        root.currentPlayer.pause();
                    else if (!root.isPlaying && root.currentPlayer.canPlay)
                        root.currentPlayer.play();
                }
            }
        }

        Text {
            text: "󰒭"
            color: colors.on_background
            font.family: "Google Sans Flex"
            font.pixelSize: 14
            opacity: (root.hasPlayer && root.currentPlayer.canGoNext) ? 1.0 : 0.4
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.hasPlayer && root.currentPlayer.canGoNext)
                        root.currentPlayer.next();
                }
            }
        }
    }
}
