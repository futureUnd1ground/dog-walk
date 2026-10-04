import QtQuick
import qs.config
import qs.widgets
import "."

Item {
    id: root
    property var plugin
    property string screenName
    property var widget
    property real dogX: 0
    property int direction: 1
    property bool sleepy: false
    property bool excited: false

    implicitWidth: Theme.u * 180
    implicitHeight: Theme.u * 56

    Timer {
        interval: 40
        running: root.visible
        repeat: true
        onTriggered: {
            const maxX = Math.max(0, root.width - dog.width);
            const speed = Math.max(0.3, Number(root.plugin ? root.plugin.get("speed", 1.0) : 1.0));
            if (root.sleepy) return;
            root.dogX += root.direction * speed;
            if (root.dogX >= maxX) {
                root.dogX = maxX;
                root.direction = -1;
            } else if (root.dogX <= 0) {
                root.dogX = 0;
                root.direction = 1;
            }
        }
    }
    Timer {
        id: nap
        interval: 5200
        running: root.visible && root.plugin && root.plugin.get("nap", true)
        repeat: true
        onTriggered: {
            root.sleepy = true;
            wake.start();
        }
    }
    Timer {
        id: wake
        interval: 1800
        onTriggered: root.sleepy = false
    }
    Timer {
        id: excitement
        interval: 1200
        onTriggered: root.excited = false
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Theme.accent, 0.18)
        radius: Theme.u
    }
    DogSprite {
        id: dog
        x: root.dogX
        anchors.bottom: parent.bottom
        pixel: Theme.u * (root.plugin ? root.plugin.get("size", 2) : 2)
        plugin: root.plugin
        facingLeft: root.direction < 0
        sleeping: root.sleepy
        excited: root.excited
    }
    PxText {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.sleepy ? I18n.t("zzz…", "zzz…") : I18n.t("гуляет", "walking")
        dim: true
        visible: root.plugin ? root.plugin.get("label", true) : true
    }
    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.excited = true;
            excitement.restart();
            root.sleepy = false;
            wake.stop();
        }
    }
}
