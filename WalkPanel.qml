import QtQuick
import qs.config
import qs.widgets

Item {
    id: root
    property var plugin
    property bool compact: false
    property int beat: 0
    readonly property bool active: plugin ? plugin.get("active", false) : false
    readonly property double startedAt: plugin ? plugin.get("startedAt", 0) : 0
    readonly property double savedMs: plugin ? plugin.get("elapsedMs", 0) : 0
    readonly property double elapsedMs: savedMs + (active && startedAt > 0 ? Math.max(0, Date.now() - startedAt + beat * 0) : 0)
    readonly property double distanceKm: elapsedMs / 3600000 * (plugin ? plugin.get("paceKmh", 4.5) : 4.5)

    implicitWidth: compact ? Theme.u * 66 : Theme.u * 110
    implicitHeight: compact ? Theme.u * 65 : content.implicitHeight

    function clock(ms) {
        const total = Math.floor(ms / 1000);
        const h = Math.floor(total / 3600);
        const m = Math.floor((total % 3600) / 60);
        const s = total % 60;
        return (h ? String(h).padStart(2, "0") + ":" : "") + String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0");
    }

    function startOrResume() {
        if (!plugin) return;
        plugin.set("active", true);
        plugin.set("startedAt", Date.now());
    }

    function pause() {
        if (!plugin || !active) return;
        plugin.set("elapsedMs", elapsedMs);
        plugin.set("active", false);
        plugin.set("startedAt", 0);
    }

    function finish() {
        if (!plugin) return;
        const finalDistance = distanceKm;
        plugin.set("lastWalkMs", elapsedMs);
        plugin.set("lastWalkKm", finalDistance);
        plugin.set("elapsedMs", 0);
        plugin.set("startedAt", 0);
        plugin.set("active", false);
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.active
        onTriggered: root.beat++
    }

    Column {
        id: content
        anchors.fill: parent
        spacing: Theme.u * 3

        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            kind: "title"
            text: root.compact ? "🐕" : (root.active ? "Dog walk in progress" : "Dog walk")
        }
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            kind: "title"
            text: root.clock(root.elapsedMs)
        }
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            dim: true
            text: root.distanceKm.toFixed(2) + " km estimated"
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.u * 2
            PxButton {
                compact: true
                icon: root.active ? "pause" : "play"
                text: root.active ? "Pause" : (root.elapsedMs > 0 ? "Resume" : "Start")
                onClicked: root.active ? root.pause() : root.startOrResume()
            }
            PxButton {
                visible: root.elapsedMs > 0
                compact: true
                icon: "check"
                text: "Finish"
                onClicked: root.finish()
            }
        }
        PxText {
            visible: !root.active && root.elapsedMs === 0 && root.plugin && root.plugin.get("lastWalkMs", 0) > 0
            anchors.horizontalCenter: parent.horizontalCenter
            dim: true
            text: "Last walk: " + root.clock(root.plugin ? root.plugin.get("lastWalkMs", 0) : 0) + " · " + Number(root.plugin ? root.plugin.get("lastWalkKm", 0) : 0).toFixed(2) + " km"
        }
    }
}
