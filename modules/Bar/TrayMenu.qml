import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

PopupWindow {
    id: root

    property var trayItem: null
    property Item anchorItem: null
    property bool isRightmost: false

    anchor.item: anchorItem
    anchor.rect.x: anchorItem ? Math.max(0, (anchorItem.width / 2) - (implicitWidth / 2)) - (isRightmost ? 16 : 0) : 0
    anchor.rect.y: anchorItem ? anchorItem.height + 6 : 0

    visible: false
    color: "transparent"

    readonly property var menuHandle: trayItem?.menu ?? null

    function closeMenu() {
        hideAnim.start()
    }

    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: menuContent; property: "opacity"; to: 1.0;  duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { target: menuContent; property: "scale";   to: 1.0;  duration: 200; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: hideAnim
        NumberAnimation { target: menuContent; property: "opacity"; to: 0.0;  duration: 150; easing.type: Easing.InCubic }
        NumberAnimation { target: menuContent; property: "scale";   to: 0.96; duration: 150; easing.type: Easing.InCubic }
        onFinished: root.visible = false
    }

    QsMenuOpener {
        id: menuOpener
        menu: root.menuHandle
    }

    implicitWidth: 220
    implicitHeight: menuColumn.implicitHeight + 16

    Rectangle {
        id: menuContent
        anchors.fill: parent
        color: colors.surface
        radius: 8
        border.color: colors.outline_variant
        border.width: 1
        opacity: 0
        scale: 0.96
        transformOrigin: Item.Top

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

                    scale: entryMouse.containsMouse && !modelData.isSeparator ? 1.02 : 1.0
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation {
                            duration: 320
                            easing.type: Easing.OutBack
                        }
                    }

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

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
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
                                root.closeMenu()
                            }
                        }
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: root.closeMenu()

    onVisibleChanged: {
        if (visible) {
            menuContent.opacity = 0
            menuContent.scale = 0.96
            showAnim.start()
        } else {
            Qt.callLater(() => { root.trayItem = null })
        }
    }
}
