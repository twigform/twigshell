import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: root

    anchors.verticalCenter: parent.verticalCenter

    property var trayItems: []

    implicitWidth: trayItems.length > 0 ? trayRow.implicitWidth : 0
    implicitHeight: 25
    visible: trayItems.length > 0
    clip: true

    Behavior on implicitWidth {
        NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
    }

    TrayMenu {
        id: trayMenu
    }

    function updateItems() {
        if (!SystemTray.items || !SystemTray.items.values) {
            trayItems = []
            return
        }
        var all = SystemTray.items.values
        var visible = []
        for (var i = 0; i < all.length; i++) {
            var item = all[i]
            if (item && item.status !== SystemTray.Passive) {
                visible.push(item)
            }
        }
        trayItems = visible
    }

    Connections {
        target: SystemTray.items
        function onValuesChanged() { root.updateItems() }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.updateItems()
    }

    Component.onCompleted: root.updateItems()

    function openMenu(item, anchor) {
        if (trayMenu.visible && trayMenu.trayItem === item) {
            trayMenu.visible = false
            return
        }
        trayMenu.trayItem = item
        trayMenu.anchorItem = anchor
        trayMenu.visible = true
    }

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.trayItems

            delegate: Item {
                required property var modelData
                required property int index

                id: iconDelegate
                width: 24
                height: 24
                opacity: iconHover.containsMouse ? 0.75 : 1.0

                Behavior on opacity {
                    NumberAnimation { duration: 120 }
                }

                IconImage {
                    id: trayIcon
                    width: 16
                    height: 16
                    anchors.centerIn: parent
                    asynchronous: true
                    backer.fillMode: Image.PreserveAspectFit

                    source: {
                        const ic = modelData?.icon ?? ""
                        if (!ic) return ""
                        if (ic.includes("?path=")) {
                            const parts = ic.split("?path=")
                            const name = parts[0]
                            const path = parts[1]
                            const fname = name.substring(name.lastIndexOf("/") + 1)
                            return `file://${path}/${fname}`
                        }
                        return ic
                    }
                }

                Rectangle {
                    visible: modelData.status === SystemTray.NeedsAttention
                    width: 5
                    height: 5
                    radius: 2.5
                    color: colors.error
                    anchors {
                        bottom: trayIcon.bottom
                        right: trayIcon.right
                        bottomMargin: -1
                        rightMargin: -1
                    }
                }

                MouseArea {
                    id: iconHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton) {
                            if (modelData.onlyMenu && modelData.menu) {
                                root.openMenu(modelData, iconDelegate)
                            } else {
                                trayMenu.visible = false
                                modelData.activate()
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            trayMenu.visible = false
                            modelData.secondaryActivate()
                        } else if (mouse.button === Qt.RightButton) {
                            if (modelData.menu) {
                                root.openMenu(modelData, iconDelegate)
                            }
                        }
                    }
                }
            }
        }
    }
}
