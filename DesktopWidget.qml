import QtQuick
import qs.config
import qs.widgets
import "."

Item {
    id: root
    property var plugin
    property string screenName
    property var widget
    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight

    WalkPanel {
        id: panel
        anchors.fill: parent
        plugin: root.plugin
    }
}
