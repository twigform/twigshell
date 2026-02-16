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
            Loader { active: true; sourceComponent: Workspaces {} }
        }
        // center
        RowLayout {
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }

            Text {
                text: niri.focusedWindow?.title ?? ""
                font.family: "Google Sans Rounded"
                font.pixelSize: 16
                color: colors.on_background
            }
        }
        // right
        RowLayout {
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: 25
            }
            spacing: 10
            Loader { active: true; sourceComponent: Time {} }
        }
    }
}
