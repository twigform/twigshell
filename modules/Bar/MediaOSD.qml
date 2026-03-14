import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland

PanelWindow {
    id: root

    anchors.top: true
    anchors.right: true
    margins.top: 45
    margins.right: 8

    implicitWidth: popupShown ? 430 : 0
    implicitHeight: popupShown ? 228 : 0
    color: "transparent"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    property bool popupShown: false
    property var currentPlayer: null
    property real displayPosition: 0
    readonly property real cornerRadius: styles.bRadius
    readonly property int hideTransitionMs: 280

    readonly property string screenName: screen ? screen.name : ""
    readonly property bool hasPlayer: currentPlayer !== null
    readonly property bool isPlaying: hasPlayer
        && currentPlayer.playbackState === MprisPlaybackState.Playing
    readonly property string trackTitle: hasPlayer
        ? (currentPlayer.trackTitle ?? "").replace(/(\r\n|\n|\r)/g, "")
        : ""
    readonly property string trackArtist: hasPlayer
        ? (currentPlayer.trackArtist ?? "")
        : ""
    readonly property string trackAlbum: hasPlayer
        ? (currentPlayer.trackAlbum ?? "")
        : ""
    readonly property string playerIdentity: hasPlayer
        ? (currentPlayer.identity ?? "")
        : ""
    readonly property string trackArtUrl: hasPlayer
        ? (currentPlayer.trackArtUrl ?? "")
        : ""
    readonly property real trackLength: hasPlayer ? Math.max(0, currentPlayer.length ?? 0) : 0
    readonly property real progressRatio: trackLength > 0
        ? Math.max(0, Math.min(displayPosition / trackLength, 1))
        : 0

    function updatePlayer() {
        if (!Mpris.players || !Mpris.players.values) {
            currentPlayer = null;
            if (popupShown)
                popup.hide();
            return;
        }

        const players = Mpris.players.values;

        for (let index = 0; index < players.length; index++) {
            if (players[index]
                && players[index].playbackState === MprisPlaybackState.Playing) {
                currentPlayer = players[index];
                syncPosition();
                return;
            }
        }

        for (let index = 0; index < players.length; index++) {
            if (players[index] && players[index].canPlay) {
                currentPlayer = players[index];
                syncPosition();
                return;
            }
        }

        currentPlayer = null;
        displayPosition = 0;
        if (popupShown)
            popup.hide();
    }

    function syncPosition() {
        displayPosition = hasPlayer ? Math.max(0, currentPlayer.position ?? 0) : 0;
    }

    function togglePopup() {
        updatePlayer();

        if (!hasPlayer)
            return;

        if (popupShown)
            popup.hide();
        else
            popup.show();
    }

    function formatTime(seconds) {
        const totalSeconds = Math.max(0, Math.floor(seconds || 0));
        const minutes = Math.floor(totalSeconds / 60);
        const remainder = totalSeconds % 60;
        return minutes + ":" + (remainder < 10 ? "0" : "") + remainder;
    }

    function seekTo(ratio) {
        if (!hasPlayer || !currentPlayer.canSeek || !currentPlayer.positionSupported || trackLength <= 0)
            return;

        const boundedRatio = Math.max(0, Math.min(ratio, 1));
        currentPlayer.position = trackLength * boundedRatio;
        syncPosition();
    }

    Process {
        id: launchWiremixProc
        command: ["kitty", "wiremix"]
        running: false
    }

    Component.onCompleted: updatePlayer()

    Connections {
        target: osdBridge

        function onToggleMediaOsd(requestedScreenName) {
            if (requestedScreenName && requestedScreenName !== root.screenName)
                return;

            root.togglePopup();
        }
    }

    Connections {
        target: Mpris.players

        function onValuesChanged() {
            root.updatePlayer();
        }
    }

    Connections {
        target: root.currentPlayer

        function onPlaybackStateChanged() {
            root.syncPosition();
        }

        function onTrackTitleChanged() {
            root.syncPosition();
        }

        function onTrackArtistChanged() {
            root.syncPosition();
        }

        function onTrackAlbumChanged() {
            root.syncPosition();
        }

        function onTrackArtUrlChanged() {
            root.syncPosition();
        }

        function onPositionChanged() {
            root.syncPosition();
        }

        function onLengthChanged() {
            root.syncPosition();
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.updatePlayer()
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.popupShown && root.hasPlayer && root.isPlaying && root.currentPlayer.positionSupported
        onTriggered: {
            root.syncPosition();
        }
    }

    Item {
        id: popup
        anchors.fill: parent
        opacity: 0
        scale: 0.94

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutBack
            }
        }

        function show() {
            hideFinalizeTimer.stop();
            root.popupShown = true;
            root.syncPosition();
            popup.opacity = 1;
            popup.scale = 1;
        }

        function hide() {
            popup.opacity = 0;
            popup.scale = 0.94;
            hideFinalizeTimer.restart();
        }

        Timer {
            id: hideFinalizeTimer
            interval: root.hideTransitionMs
            repeat: false
            onTriggered: {
                if (popup.opacity <= 0.01)
                    root.popupShown = false;
            }
        }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: root.cornerRadius
            color: colors.surface_container
            border.width: 1
            border.color: Qt.rgba(colors.outline.r, colors.outline.g, colors.outline.b, 0.3)

            Item {
                id: maskedBackdrop
                anchors.fill: parent
                layer.enabled: root.popupShown
                layer.smooth: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: card.width
                        height: card.height
                        radius: card.radius
                        color: "black"
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.lighter(colors.primary_container, 1.1) }
                        GradientStop { position: 1.0; color: colors.surface_container_low }
                    }
                }

                Image {
                    anchors.fill: parent
                    source: root.popupShown ? root.trackArtUrl : ""
                    sourceSize.width: root.popupShown
                        ? Math.max(1, Math.round(width * (root.screen ? root.screen.devicePixelRatio : 1)))
                        : 0
                    sourceSize.height: root.popupShown
                        ? Math.max(1, Math.round(height * (root.screen ? root.screen.devicePixelRatio : 1)))
                        : 0
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    mipmap: false
                    opacity: status === Image.Ready ? 0.78 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(colors.scrim.r, colors.scrim.g, colors.scrim.b, 0.35) }
                        GradientStop { position: 0.52; color: Qt.rgba(colors.scrim.r, colors.scrim.g, colors.scrim.b, 0.48) }
                        GradientStop { position: 1.0; color: Qt.rgba(colors.scrim.r, colors.scrim.g, colors.scrim.b, 0.82) }
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 96
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop {
                            position: 0.0
                            color: Qt.rgba(colors.background.r, colors.background.g, colors.background.b, 0.0)
                        }
                        GradientStop {
                            position: 0.45
                            color: Qt.rgba(colors.background.r, colors.background.g, colors.background.b, 0.34)
                        }
                        GradientStop {
                            position: 1.0
                            color: Qt.rgba(colors.background.r, colors.background.g, colors.background.b, 0.72)
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: metaColumn.implicitHeight

                        Column {
                            id: metaColumn
                            width: parent.width
                            spacing: 4

                            Text {
                                width: parent.width
                                text: root.trackTitle || "Nothing playing"
                                color: colors.on_surface
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                font.family: styles.fontFamily
                                font.bold: true
                                font.pixelSize: 22
                            }

                            Text {
                                width: parent.width
                                text: root.trackArtist || root.trackAlbum || root.playerIdentity
                                color: Qt.rgba(colors.on_surface.r, colors.on_surface.g, colors.on_surface.b, 0.92)
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                font.family: styles.fontFamily
                                font.pixelSize: 14
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Item {
                        id: progressTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 20

                        property real handleW: 4
                        property real gap: 2
                        property real handleCenter: Math.max(handleW / 2, Math.min(root.progressRatio * width, width - handleW / 2))

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: 0
                            width: Math.max(0, parent.handleCenter - parent.handleW / 2 - parent.gap)
                            height: 8
                            topLeftRadius: 4
                            bottomLeftRadius: 4
                            topRightRadius: 2
                            bottomRightRadius: 2
                            color: colors.primary
                            visible: width > 0

                            Behavior on width {
                                NumberAnimation { duration: 200; easing.type: Easing.OutExpo }
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.handleCenter + parent.handleW / 2 + parent.gap
                            width: Math.max(0, parent.width - x)
                            height: 8
                            topLeftRadius: 2
                            bottomLeftRadius: 2
                            topRightRadius: 4
                            bottomRightRadius: 4
                            color: colors.secondary_container
                            visible: width > 0

                            Behavior on x {
                                NumberAnimation { duration: 200; easing.type: Easing.OutExpo }
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.handleCenter - width / 2
                            width: parent.handleW
                            height: 32
                            radius: 2
                            color: colors.primary

                            Behavior on x {
                                NumberAnimation { duration: 200; easing.type: Easing.OutExpo }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: root.hasPlayer && root.currentPlayer.canSeek && root.currentPlayer.positionSupported && root.trackLength > 0
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: function (mouse) {
                                root.seekTo(mouse.x / width);
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Text {
                            Layout.preferredWidth: 40
                            text: root.formatTime(root.displayPosition)
                            color: Qt.rgba(colors.on_surface.r, colors.on_surface.g, colors.on_surface.b, 0.88)
                            font.family: styles.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 10

                            Rectangle {
                                id: previousButton
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                radius: root.cornerRadius
                                color: "transparent"
                                opacity: root.hasPlayer && root.currentPlayer.canGoPrevious ? 1 : 0.45
                                scale: previousMouse.pressed ? 0.9 : (previousMouse.containsMouse ? 1.08 : 1.0)

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 120
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒮"
                                    color: colors.on_surface
                                    font.family: styles.fontFamily
                                    font.bold: true
                                    font.pixelSize: 25
                                }

                                MouseArea {
                                    id: previousMouse
                                    anchors.fill: parent
                                    enabled: root.hasPlayer && root.currentPlayer.canGoPrevious
                                    hoverEnabled: true
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: root.currentPlayer.previous()
                                }
                            }

                            Rectangle {
                                id: playPauseButton
                                Layout.preferredWidth: 58
                                Layout.preferredHeight: 58
                                radius: playPauseMouse.pressed
                                    ? root.cornerRadius
                                    : (playPauseMouse.containsMouse ? root.cornerRadius + 2 : root.cornerRadius + 4)
                                color: playPauseMouse.pressed
                                    ? Qt.darker(colors.primary, 1.18)
                                    : (playPauseMouse.containsMouse ? Qt.lighter(colors.primary, 1.12) : colors.primary)
                                scale: playPauseMouse.pressed ? 0.96 : (playPauseMouse.containsMouse ? 1.08 : 1.0)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 230
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 230
                                        easing.type: Easing.OutBack
                                    }
                                }

                                Behavior on radius {
                                    NumberAnimation {
                                        duration: 230
                                        easing.type: Easing.OutBack
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.isPlaying ? "" : ""
                                    color: colors.on_primary
                                    font.family: styles.fontFamily
                                    font.bold: true
                                    font.pixelSize: 24
                                }

                                MouseArea {
                                    id: playPauseMouse
                                    anchors.fill: parent
                                    enabled: root.hasPlayer && (root.currentPlayer.canPause || root.currentPlayer.canPlay)
                                    hoverEnabled: true
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (!root.hasPlayer)
                                            return;

                                        if (root.isPlaying && root.currentPlayer.canPause)
                                            root.currentPlayer.pause();
                                        else if (!root.isPlaying && root.currentPlayer.canPlay)
                                            root.currentPlayer.play();
                                    }
                                }
                            }

                            Rectangle {
                                id: nextButton
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                radius: root.cornerRadius
                                color: "transparent"
                                opacity: root.hasPlayer && root.currentPlayer.canGoNext ? 1 : 0.45
                                scale: nextMouse.pressed ? 0.9 : (nextMouse.containsMouse ? 1.08 : 1.0)

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 230
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒭"
                                    color: colors.on_surface
                                    font.family: styles.fontFamily
                                    font.bold: true
                                    font.pixelSize: 25
                                }

                                MouseArea {
                                    id: nextMouse
                                    anchors.fill: parent
                                    enabled: root.hasPlayer && root.currentPlayer.canGoNext
                                    hoverEnabled: true
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: root.currentPlayer.next()
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                            text: root.trackLength > 0 ? root.formatTime(root.trackLength) : "0:00"
                            color: Qt.rgba(colors.on_surface.r, colors.on_surface.g, colors.on_surface.b, 0.88)
                            font.family: styles.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }
            }

            Rectangle {
                id: settingsButton
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 2
                    rightMargin: 2
                }
                width: 30
                height: 30
                radius: root.cornerRadius
                color: "transparent"
                scale: settingsMouse.pressed ? 0.9 : (settingsMouse.containsMouse ? 1.08 : 1.0)
                border.width: 0

                Behavior on scale {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: colors.on_surface
                    font.family: styles.fontFamily
                    font.bold: true
                    font.pixelSize: 15
                }

                MouseArea {
                    id: settingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: launchWiremixProc.running = true
                }
            }
        }
    }
}