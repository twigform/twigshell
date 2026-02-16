import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
// import Quickshell.Service.Pipewire
import Niri 0.1
import "./modules/bar/"

ShellRoot{

    id: root

    Colors{
        id: colors
    }

    Variants {
        model: Quickshell.screens
        Bar {
            property var modelData
            screen: modelData
        }
    }

    Niri {
        id: niri
        Component.onCompleted: connect()

        onConnected: console.info("Connected to niri")
        onErrorOccurred: function(error) {
            console.error("Niri error:", error)
        }
    }
}