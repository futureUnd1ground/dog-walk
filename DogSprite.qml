import QtQuick
import qs.config
import qs.widgets
import "."
import "DogFrames.js" as Frames

Item {
    id: root
    property var plugin
    property int pixel: Theme.u * 2
    property bool facingLeft: false
    property bool sleeping: false
    property bool excited: false
    property int frame: 0
    property color fur: plugin && plugin.get("fur", "#c9824a")

    implicitWidth: sprite.width
    implicitHeight: sprite.height + pixel

    Timer {
        interval: root.sleeping ? 720 : Math.max(75, (root.excited ? 230 : 360) - Cpu.percent * 2.6)
        running: root.visible
        repeat: true
        onTriggered: root.frame = (root.frame + 1) % 5
    }

    PxIcon {
        id: sprite
        pixel: root.pixel
        bitmap: root.sleeping ? Frames.sleep.map((r, i) => root.frame % 2 && i < 2 ? r.replace(/z/g, ".") : r) : Frames.walk(root.frame)
        body: root.fur
        fill: Theme.accent
        fill2: Theme.accent2
        fill3: Theme.accent4
        light: Theme.text
        palette: ({"w": Theme.text, "o": Theme.danger, "z": Theme.accent4})
        transform: Scale {
            origin.x: sprite.width / 2
            xScale: root.facingLeft ? -1 : 1
        }
        y: !root.sleeping && root.frame % 2 === 1 ? 0 : root.pixel
    }
}
