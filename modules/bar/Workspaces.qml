import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    property string monitorName: ""
    
    anchors.left: parent.left
    color: "transparent"
    height: 25
    width: 215

    Rectangle {
        id: workspaceLayout
        color: "transparent"
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
            leftMargin: 10
            rightMargin: 10
        }

        RowLayout {
            anchors {
                verticalCenter: parent.verticalCenter
            }
            spacing: 5

            Repeater {
                model: niri.workspaces

                Rectangle {
                    Text {
                        text: index
                        font.family: "Google Sans Rounded"
                        font.pixelSize: 10
                        anchors.centerIn: parent
                        color: model.isActive ? colors.on_primary : colors.surface_container_highest
                    }
                    visible: (model.output === monitorName) && (index < 11)
                    Layout.preferredWidth: model.isActive ? 30 : 15
                    Layout.preferredHeight: 15
                    Layout.alignment: Qt.AlignVCenter
                    width: model.isActive ? 30 : 15
                    height: 15
                    radius: model.isActive ? 5 : 10
                    color: model.isActive ? colors.primary : colors.surface_container_highest
                    
                    Behavior on Layout.preferredWidth {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutBack
                        }
                    }
                    
                    Behavior on width {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutBack
                        }
                    }
                    
                    Behavior on radius {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutBack
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: niri.focusWorkspaceById(model.id)
                    }
                }
            }
        }
    }
}
