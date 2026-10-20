import Quickshell
import QtQuick
import qs.CustomTheme

// Custom (not ML4W upstream): AirDrop. Click toggles the AirDrop panel, which
// drops down under this icon; drop files on it to open the panel with them.
// Installed by ~/.config/ml4w-statusbar/patch-airdrop.sh.
Rectangle {
    id: airdrop

    // Set by the keyboard navigation in StatusbarWindow.
    property bool focused: false
    readonly property bool active: mouseArea.containsMouse || focused || dropArea.containsDrag

    // Screen x of this icon's centre: the bar spans the screen from x = 0.
    function anchorX(): string {
        return String(Math.round(airdrop.mapToItem(null, airdrop.width / 2, 0).x))
    }

    function activate(): void {
        Quickshell.execDetached(["airdrop-app", "--toggle", "--at", anchorX()])
    }

    implicitWidth: 34
    implicitHeight: 30
    radius: 15
    color: active ? Theme.primary : "transparent"
    Behavior on color {
        ColorAnimation { duration: 500; easing.type: Easing.OutQuint }
    }

    Text {
        anchors.centerIn: parent
        text: String.fromCodePoint(0xF0003)   // md-access_point: AirDrop's rings
        color: airdrop.active ? Theme.background : Theme.primary
        font.family: "Symbols Nerd Font"
        font.pixelSize: 17
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: airdrop.activate()
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        keys: ["text/uri-list"]
        onEntered: drag => drag.accept(Qt.CopyAction)
        onDropped: drop => {
            let paths = []
            for (let u of drop.urls) {
                let s = u.toString()
                if (s.startsWith("file://"))
                    paths.push(decodeURIComponent(s.substring(7)))
            }
            if (paths.length > 0) {
                Quickshell.execDetached(["airdrop-app", "--show", "--at", anchorX()].concat(paths))
                drop.accept(Qt.CopyAction)
            }
        }
    }
}
