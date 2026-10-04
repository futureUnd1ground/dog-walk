import QtQuick
import qs.config
import qs.widgets
import qs.modules.bar
import "."

Item {
    id: root
    property var plugin
    property string screenName
    property var barWindow
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    PxButton {
        id: button
        compact: true
        flat: true
        icon: "paw-print"
        text: root.plugin && root.plugin.get("active", false) ? "Walk" : "Dog"
        onClicked: popup.toggle()
    }

    BarPopup {
        id: popup
        panelId: "dog-walk"
        anchorItem: root
        above: BarLayout.bottom
        title: "Dog walk"
        icon: "paw-print"
        contentWidth: Theme.u * 112
        contentHeight: Theme.u * 120

        WalkPanel {
            anchors.centerIn: parent
            plugin: root.plugin
        }
    }
}
