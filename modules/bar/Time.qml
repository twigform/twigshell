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
        font.family: "Google Sans Rounded"
        font.pixelSize: 16
        Component.onCompleted: {
            parent.width = timeBlock.contentWidth
        }
    }
}
