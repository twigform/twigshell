import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

PopupWindow {
    id: root

    property var trayItem: null
    property Item anchorItem: null

    anchor.item: anchorItem
    anchor.rect.x: anchorItem ? Math.max(0, (anchorItem.width / 2) - (implicitWidth / 2)) : 0
    anchor.rect.y: anchorItem ? anchorItem.height + 6 : 0

    visible: false
    color: "transparent"

    readonly property var menuHandle: trayItem?.menu ?? null

    QsMenuOpener {
        id: menuOpener
        menu: root.menuHandle
    }

    implicitWidth: 220
    implicitHeight: menuColumn.implicitHeight + 16

    Rectangle {
        anchors.fill: parent
        color: colors.surface_container
        radius: 8
        border.color: colors.outline_variant
        border.width: 1

        layer.enabled: true

        Column {
            id: menuColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: 8
                leftMargin: 8
                rightMargin: 8
                bottomMargin: 8
            }
            spacing: 2

            Repeater {
                model: menuOpener.children ? [...menuOpener.children.values] : []

                delegate: Item {
                    required property var modelData

                    width: menuColumn.width
                    height: modelData.isSeparator ? 9 : 30

                    Rectangle {
                        visible: modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 8
                        height: 1
                        color: colors.outline_variant
                        opacity: 0.6
                    }

                    Rectangle {
                        visible: !modelData.isSeparator
                        anchors.fill: parent
                        color: entryMouse.containsMouse
                            ? Qt.rgba(
                                colors.primary_fixed.r,
                                colors.primary_fixed.g,
                                colors.primary_fixed.b,
                                0.15
                              )
                            : "transparent"
                        radius: 6
                    }

                    Text {
                        visible: !modelData.isSeparator
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 12
                            rightMargin: 12
                        }
                        text: modelData.text || ""
                        color: (modelData.enabled ?? true)
                            ? colors.on_surface
                            : colors.outline_variant
                        font.family: "Google Sans Flex"
                        font.pixelSize: 14
                        font.variableAxes: { "ROND": 100, "wght": 500 }
                        elide: Text.ElideRight

                        Behavior on color {
                            ColorAnimation { duration: 80 }
                        }
                    }

                    MouseArea {
                        id: entryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !modelData.isSeparator
                            && (modelData.enabled ?? true)
                            && root.visible
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (!modelData.isSeparator) {
                                modelData.triggered()
                                root.visible = false
                            }
                        }
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: root.visible = false

    onVisibleChanged: {
        if (!visible) {
            Qt.callLater(() => { root.trayItem = null })
        }
    }
}
