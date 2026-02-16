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

    // FloatingWindow{
    //     visible: true
    //     width: 400
    //     height: 300
    //     color: colors.background
    //     Text{
    //         anchors.centerIn: parent
    //         text: "This is a floating window. It can be dragged and resized."
    //         color: colors.on_background
    //         font.family: "Google Sans Rounded"
    //         font.pixelSize: 14
    //     }
    // }
    

    Niri {
        id: niri
        Component.onCompleted: connect()

        onConnected: console.info("Connected to niri")
        onErrorOccurred: function(error) {
            console.error("Niri error:", error)
        }
    }

    LazyLoader{ active: true; component: Bar{} }
}
