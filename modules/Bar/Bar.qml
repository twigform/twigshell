import QtQuick
import QtQuick.Layouts
import Quickshell

PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: styles.barHeight
    color: "transparent"

    Rectangle {
        anchors.topMargin: styles.barMargin
        anchors.leftMargin: styles.barMargin
        anchors.rightMargin: styles.barMargin
        anchors.fill: parent
        color: colors.background
        radius: styles.barRadius

        // left
        RowLayout {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 0
            }
            Loader {
                active: true
                sourceComponent: Workspaces {
                    monitorName: bar.screen.name
                }
            }
        }
        // center
        RowLayout {
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }

            Text {
                property int maxTitleLength: 35
                function truncatedTitle(title) {
                    if (!title)
                        return "";
                    return title.length > maxTitleLength ? title.substring(0, maxTitleLength) + "..." : title;
                }
                text: truncatedTitle(niri.focusedWindow?.title)
                font.family: styles.fontFamily
                font.bold: true
                font.pixelSize: 16
                color: colors.on_background
            }
        }
        // right
        RowLayout {
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: 10
            }
            spacing: 10
            Loader {
                active: true
                sourceComponent: Media {}
            }
            Loader {
                active: true
                sourceComponent: Tray {}
            }
            Loader {
                active: true
                sourceComponent: Audio {}
            }
            Loader {
                active: true
                sourceComponent: Time {}
            }
        }
    }
}
