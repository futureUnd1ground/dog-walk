import QtQuick
import Quickshell
import qs.services

Item {
    id: root
    property var plugin

    Timer {
        interval: 800
        repeat: false
        running: true
        onTriggered: {
            const screen = Shell.primaryName || (Quickshell.screens[0] || {}).name;
            if (screen && !DesktopWidgets.has("plugin:dog-walk", screen))
                DesktopWidgets.add("plugin:dog-walk", screen);
        }
    }
}
