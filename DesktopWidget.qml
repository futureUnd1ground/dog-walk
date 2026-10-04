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
    property string playState: "idle"
    property real homeX: 0
    property real ballX: 0
    property real ballTargetX: 0
    property bool ballVisible: false

    implicitWidth: Theme.u * 180
    implicitHeight: Theme.u * 56

    Timer {
        interval: 40
        running: root.visible
        repeat: true
        onTriggered: {
            const maxX = Math.max(0, root.width - dog.width);
            const baseSpeed = Math.max(0.3, Number(root.plugin ? root.plugin.get("speed", 1.0) : 1.0));
            const cpuFactor = 0.6 + Cpu.percent / 100 * 2.4;
            const speed = baseSpeed * cpuFactor * (root.playState === "idle" ? 1 : 1.6);
            if (root.playState === "idle") {
                if (root.sleepy) return;
                root.dogX += root.direction * speed;
                if (root.dogX >= maxX) {
                    root.dogX = maxX;
                    root.direction = -1;
                } else if (root.dogX <= 0) {
                    root.dogX = 0;
                    root.direction = 1;
                }
            } else {
                if (root.playState === "throw")
                    return;
                const target = root.playState === "fetch" ? root.ballTargetX - dog.width / 2 : root.homeX;
                const delta = target - root.dogX;
                root.direction = delta < 0 ? -1 : 1;
                if (Math.abs(delta) <= speed) {
                    root.dogX = Math.max(0, Math.min(maxX, target));
                    if (root.playState === "fetch") {
                        root.ballVisible = false;
                        root.playState = "return";
                    } else {
                        root.playState = "idle";
                        root.excited = false;
                    }
                } else {
                    root.dogX += root.direction * speed;
                }
            }
        }
    }
    NumberAnimation {
        id: ballFlight
        target: root
        property: "ballX"
        duration: 520
        easing.type: Easing.OutQuad
        onFinished: root.playState = "fetch"
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
        anchors.left: parent.left
        anchors.leftMargin: Theme.u * 3
        text: root.playState === "idle" ? (root.sleepy ? "zzz…" : I18n.t("гуляет", "walking")) : I18n.t("несёт мяч!", "fetching!")
        dim: true
        visible: root.plugin ? root.plugin.get("label", true) : true
    }
    PxText {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: Theme.u * 3
        text: "CPU " + Math.round(Cpu.percent) + "%"
        kind: "tiny"
    }
    Rectangle {
        visible: root.ballVisible
        x: root.ballX
        y: parent.height - dog.height - Theme.u * 3 - Math.abs(Math.sin(ballFlight.duration ? ballFlight.currentTime / ballFlight.duration * Math.PI : 0)) * Theme.u * 8
        width: Theme.u * 3
        height: Theme.u * 3
        color: Theme.accent
        border.width: 1
        border.color: Theme.edge
    }
    MouseArea {
        anchors.fill: parent
        onClicked: mouse => {
            if (root.playState !== "idle")
                return;
            root.excited = true;
            excitement.restart();
            root.sleepy = false;
            wake.stop();
            root.homeX = root.dogX;
            root.ballX = root.dogX + dog.width / 2;
            root.ballTargetX = Math.max(dog.width / 2, Math.min(root.width - dog.width / 2, mouse.x));
            root.ballVisible = true;
            root.playState = "throw";
            ballFlight.to = root.ballTargetX;
            ballFlight.restart();
        }
    }
}
