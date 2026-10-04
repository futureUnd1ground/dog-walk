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
    implicitWidth: dog.width + Theme.u * 3
    implicitHeight: Theme.u * 13

    DogSprite {
        id: dog
        anchors.centerIn: parent
        plugin: root.plugin
        pixel: Theme.u
    }
    MouseArea {
        anchors.fill: parent
        onClicked: popup.toggle()
    }
    BarPopup {
        id: popup
        panelId: "dog-walk"
        anchorItem: root
        above: BarLayout.bottom
        title: I18n.t("собака.exe", "dog.exe")
        icon: "paw-print"
        contentWidth: Theme.u * 100
        contentHeight: Theme.u * 48
        DogSprite {
            anchors.centerIn: parent
            plugin: root.plugin
            pixel: Theme.u * 3
            excited: true
        }
    }
}
