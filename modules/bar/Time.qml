import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
    Text {
        id: timeBlock
        anchors {
            verticalCenter: parent.verticalCenter
        }
        text: Qt.formatDateTime(clock.date, "hh:mm AP dd MMM, yyyy")
        color: colors.on_background
        font.family: "Google Sans Flex"
        font.pixelSize: 16
        font.variableAxes: {
            "ROND": 100,
            "wght": 650
        }

        Component.onCompleted: {
            parent.width = timeBlock.contentWidth
        }
    }
}
