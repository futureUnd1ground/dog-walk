import QtQuick
import qs.config
import qs.widgets
import qs.services
import "."
import "PetLogic.js" as Logic

Item {
    id: root
    property var plugin
    property string screenName
    property var widget
    property bool faceLayer: true
    property real dogX: 0
    property int direction: 1
    property bool sleepy: false
    readonly property bool excited: playState !== "idle"
    property string playState: "idle"
    property real homeX: 0
    property real flightStartX: 0
    property real flightProgress: 0
    property real ballTargetX: 0
    readonly property real ballX: playState === "return" ? dogX + (direction < 0 ? 0 : dog.width) : flightStartX + (ballTargetX - flightStartX) * flightProgress
    property bool ballVisible: false
    property real seenPlayCommand: 0
    property bool ready: false
    readonly property bool active: visible && faceLayer && !Shell.locked
    readonly property real maxX: Math.max(0, width - dog.width)
    readonly property real baseSpeed: Logic.bounded(plugin ? plugin.get("speed", 1) : 1, 1, 0.3, 3)
    readonly property real dogSize: Logic.bounded(plugin ? plugin.get("size", 2) : 2, 2, 1, 3)
    readonly property bool napsEnabled: plugin ? !!plugin.get("nap", true) : true
    readonly property real playCommand: Logic.bounded(plugin ? plugin.get("playCommandId", 0) : 0, 0, 0, Number.MAX_SAFE_INTEGER)
    clip: true

    onMaxXChanged: if (ready) clampPositions()
    onNapsEnabledChanged: if (!napsEnabled) sleepy = false
    onPlayCommandChanged: consumePlayCommand()

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
        seenPlayCommand = playCommand;
        ready = true;
        clampPositions();
    }

    function clampBall(value) {
        if (width < dog.width)
            return Math.max(0, width / 2);
        return Logic.bounded(value, width / 2, dog.width / 2, width - dog.width / 2);
    }

    function clampPositions() {
        dogX = Logic.bounded(dogX, 0, 0, maxX);
        homeX = Logic.bounded(homeX, 0, 0, maxX);
        ballTargetX = clampBall(ballTargetX);
        flightStartX = clampBall(flightStartX);
    }

    function consumePlayCommand() {
        if (!ready || !faceLayer || playCommand === seenPlayCommand)
            return;
        seenPlayCommand = playCommand;
        if (playCommand > 0 && active)
            startFetch(plugin ? plugin.get("playTargetX", width / 2) : width / 2);
    }

    function startFetch(targetX) {
        if (!active || playState !== "idle")
            return;
        sleepy = false;
        clampPositions();
        homeX = dogX;
        flightStartX = dogX + dog.width / 2;
        ballTargetX = clampBall(targetX);
        flightProgress = 0;
        ballVisible = true;
        playState = "throw";
        ballFlight.restart();
    }

    function beginNap() {
        if (active && napsEnabled && playState === "idle")
            sleepy = true;
    }

    function advance(seconds) {
        if (!active || sleepy || playState === "throw")
            return;
        const dt = Logic.bounded(seconds, 0, 0, 0.1);
        const cpuFactor = 0.6 + Logic.bounded(Cpu.percent, 0, 0, 100) / 100 * 2.4;
        const step = baseSpeed * cpuFactor * 25 * dt * (playState === "idle" ? 1 : 1.6);
        if (playState === "idle") {
            dogX = Logic.bounded(dogX + direction * step, 0, 0, maxX);
            if (dogX >= maxX) direction = -1;
            else if (dogX <= 0) direction = 1;
            return;
        }
        const target = playState === "fetch" ? Logic.bounded(ballTargetX - dog.width / 2, 0, 0, maxX) : homeX;
        const delta = target - dogX;
        direction = delta < 0 ? -1 : 1;
        if (Math.abs(delta) <= step) {
            dogX = target;
            if (playState === "fetch") {
                playState = "return";
            } else {
                playState = "idle";
                ballVisible = false;
            }
        } else {
            dogX = Logic.bounded(dogX + direction * step, 0, 0, maxX);
        }
    }

    FrameAnimation {
        running: root.active && !root.sleepy && root.playState !== "throw"
        onTriggered: root.advance(frameTime)
    }
    NumberAnimation {
        id: ballFlight
        target: root
        property: "flightProgress"
        from: 0
        to: 1
        duration: 520
        paused: running && !root.active
        easing.type: Easing.OutQuad
        onFinished: root.playState = "fetch"
    }
    Timer {
        interval: 5200
        running: root.active && root.napsEnabled && !root.sleepy && root.playState === "idle"
        repeat: true
        onTriggered: root.beginNap()
    }
    Timer {
        interval: 1800
        running: root.active && root.sleepy
        onTriggered: root.sleepy = false
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
        pixel: Math.max(1, Math.round(Theme.u * root.dogSize))
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
        x: root.ballX - width / 2
        y: root.playState === "return" ? parent.height - dog.height * 0.4 : parent.height - height - Math.sin(root.flightProgress * Math.PI) * Theme.u * 8
        width: Theme.u * 3
        height: Theme.u * 3
        color: Theme.accent
        border.width: 1
        border.color: Theme.edge
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onDoubleClicked: mouse => {
            if (root.faceLayer) {
                root.startFetch(mouse.x);
            } else if (root.plugin) {
                root.plugin.set("playTargetX", mouse.x);
                root.plugin.set("playCommandId", Math.max(Date.now(), root.playCommand + 1));
            }
        }
    }
}
