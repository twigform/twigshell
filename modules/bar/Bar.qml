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
    implicitHeight: 35
    color: "transparent"

    

    Rectangle {
        anchors.topMargin: 8
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.fill: parent
        color: colors.background
        bottomLeftRadius: 10
        bottomRightRadius: 10
        topLeftRadius: 10
        topRightRadius: 10
        
        // left
        RowLayout {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 0
            }
            Loader { active: true; sourceComponent: Workspaces { monitorName: bar.screen.name } }
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
                    if (!title) return "";
                    return title.length > maxTitleLength ? title.substring(0, maxTitleLength) + "..." : title;
                }
                text: truncatedTitle(niri.focusedWindow?.title)
                font.family: "Google Sans Flex"
                font.variableAxes: {
                    "ROND": 100,
                    "wght": 650
                }
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
            Loader { active: true; sourceComponent: Audio {} }
            Loader { active: true; sourceComponent: Time {} }
        }
    }
}
