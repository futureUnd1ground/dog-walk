import QtQuick
import qs.config
import qs.widgets
import "."

Item {
    id: root
    property var plugin
    property string screenName
    property var widget
    property bool faceLayer: true
    property real dogX: 0
    property int direction: 1
    property bool sleepy: false
    property bool excited: false
    property string playState: "idle"
    property real homeX: 0
    property real ballX: 0
    property real ballTargetX: 0
    property bool ballVisible: false
    property int pendingClicks: 0
    property int seenPlayCommand: 0

    implicitWidth: Theme.u * 180
    implicitHeight: Theme.u * 56

    Component.onCompleted: {
        let ancestor = parent;
        while (ancestor) {
            if (ancestor.role === "face" || ancestor.role === "input") {
                faceLayer = ancestor.role === "face";
                break;
            }
            ancestor = ancestor.parent;
        }
        if (faceLayer && plugin)
            seenPlayCommand = Number(plugin.get("playCommandId", 0));
    }

    function startFetch(targetX) {
        if (playState !== "idle")
            return;
        excited = true;
        excitement.restart();
        sleepy = false;
        wake.stop();
        homeX = dogX;
        ballX = dogX + dog.width / 2;
        ballTargetX = Math.max(dog.width / 2, Math.min(width - dog.width / 2, targetX));
        ballVisible = true;
        playState = "throw";
        ballFlight.to = ballTargetX;
        ballFlight.restart();
    }

    Timer {
        interval: 40
        running: root.visible && root.faceLayer
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
        interval: 80
        running: root.visible && root.faceLayer
        repeat: true
        onTriggered: {
            if (!root.plugin)
                return;
            const commandId = Number(root.plugin.get("playCommandId", 0));
            if (commandId <= root.seenPlayCommand)
                return;
            root.seenPlayCommand = commandId;
            root.startFetch(Number(root.plugin.get("playTargetX", root.width / 2)));
        }
    }
    Timer {
        id: nap
        interval: 5200
        running: root.visible && root.faceLayer && root.plugin && root.plugin.get("nap", true)
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
        visible: root.faceLayer
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
        visible: root.faceLayer
    }
    PxText {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: Theme.u * 3
        text: root.playState === "idle" ? (root.sleepy ? "zzz…" : I18n.t("двойной клик — мяч", "double-click to fetch")) : I18n.t("несёт мяч!", "fetching!")
        dim: true
        visible: root.faceLayer && (root.plugin ? root.plugin.get("label", true) : true)
    }
    PxText {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: Theme.u * 3
        text: "CPU " + Math.round(Cpu.percent) + "%"
        kind: "tiny"
        visible: root.faceLayer
    }
    Rectangle {
        visible: root.faceLayer && root.ballVisible
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
        acceptedButtons: Qt.LeftButton
        onClicked: mouse => {
            if (root.faceLayer)
                return;
            if (root.pendingClicks === 0) {
                root.pendingClicks = 1;
                clickReset.restart();
                return;
            }
            root.pendingClicks = 0;
            clickReset.stop();
            if (root.plugin) {
                root.plugin.set("playTargetX", mouse.x);
                root.plugin.set("playCommandId", Date.now());
            }
        }
    }
    Timer {
        id: clickReset
        interval: 420
        onTriggered: root.pendingClicks = 0
    }
}
