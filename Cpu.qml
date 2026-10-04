pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root
    property real percent: 0
    property var previous: null

    Timer {
        interval: 2000
        running: !Shell.locked
        repeat: true
        triggeredOnStart: true
        onTriggered: stat.reload()
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const fields = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = fields[3] + fields[4];
            const total = fields.reduce((sum, value) => sum + value, 0);
            if (root.previous && total > root.previous.total) {
                const deltaTotal = total - root.previous.total;
                const deltaIdle = idle - root.previous.idle;
                root.percent = Math.max(0, Math.min(100, 100 * (1 - deltaIdle / deltaTotal)));
            }
            root.previous = {"total": total, "idle": idle};
        }
    }
}
