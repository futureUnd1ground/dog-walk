import QtQuick
import qs.config
import qs.widgets
import "PetLogic.js" as Logic

Column {
    id: root
    property var plugin
    property bool invalidColor: false
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
            label: I18n.t("Базовая скорость", "Base speed")
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
        PxText {
            text: I18n.t("При высокой нагрузке CPU собака ускоряется и бежит.", "The dog speeds up and runs when CPU load rises.")
            dim: true
            wrapMode: Text.Wrap
            width: parent.width
        }
        SettingRow {
            label: I18n.t("Иногда спит", "Occasional naps")
            PxToggle {
                checked: root.plugin ? root.plugin.get("nap", true) : true
                onToggled: v => root.plugin.set("nap", v)
            }
        }
        SettingRow {
            label: I18n.t("Цвет шерсти (#RRGGBB)", "Fur color (#RRGGBB)")
            PxField {
                width: Theme.u * 50
                text: Logic.furColor(root.plugin ? root.plugin.get("fur", "#c9824a") : "#c9824a")
                onAccepted: {
                    const color = text.trim();
                    root.invalidColor = !/^#[0-9a-fA-F]{6}$/.test(color);
                    if (!root.invalidColor && root.plugin)
                        root.plugin.set("fur", color);
                }
            }
        }
        PxText {
            visible: root.invalidColor
            text: I18n.t("Введи цвет вида #c9824a и нажми Enter.", "Enter a color such as #c9824a and press Enter.")
            color: Theme.danger
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
