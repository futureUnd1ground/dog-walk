import QtQuick
import qs.config
import qs.widgets

Column {
    id: root
    property var plugin
    width: parent ? parent.width : 400
    spacing: Theme.u * 4

    PxGroup {
        title: I18n.t("Собака на рабочем столе", "Desktop dog")
        icon: "paw-print"
        width: parent.width
        SettingRow {
            label: I18n.t("Размер", "Size")
            PxSegmented {
                model: [{"label": "×1.5", "value": 1.5}, {"label": "×2", "value": 2}, {"label": "×3", "value": 3}]
                currentValue: root.plugin ? root.plugin.get("size", 2) : 2
                onActivated: v => root.plugin.set("size", v)
            }
        }
        SettingRow {
            label: I18n.t("Скорость ходьбы", "Walk speed")
            PxSlider {
                width: parent.width
                from: 0.3
                to: 3
                stepSize: 0.1
                value: root.plugin ? root.plugin.get("speed", 1) : 1
                suffix: "×"
                onReleased: v => root.plugin.set("speed", v)
            }
        }
        SettingRow {
            label: I18n.t("Иногда спит", "Occasional naps")
            PxToggle {
                checked: root.plugin ? root.plugin.get("nap", true) : true
                onToggled: v => root.plugin.set("nap", v)
            }
        }
        SettingRow {
            label: I18n.t("Подпись", "Label")
            PxToggle {
                checked: root.plugin ? root.plugin.get("label", true) : true
                onToggled: v => root.plugin.set("label", v)
            }
        }
    }
}
