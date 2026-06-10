import QtQuick
import QtQuick.Window
import "components"

Window {
    id: appWindow

    // Адаптивный размер окна: на мониторе 1920×1080 занимает почти всю
    // доступную площадь (крупные графики), но корректно ужимается на
    // меньших экранах/ноутбуке. Раньше окно было жёстко 1400×1050.
    readonly property int availW: Screen.desktopAvailableWidth
    readonly property int availH: Screen.desktopAvailableHeight

    width: Math.min(1920, availW - 40)
    height: Math.min(1080, availH - 40)
    minimumWidth: Math.min(1200, availW - 40)
    minimumHeight: Math.min(700, availH - 40)
    x: Screen.virtualX + Math.round((Screen.width - width) / 2)
    y: Screen.virtualY + Math.round((Screen.height - height) / 2)
    visible: true
    color: "transparent"

    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    MyRect {
        id: root
        anchors.fill: parent

        Header {
            id: header
        }

        Body {
            anchors.top: header.bottom
        }
    }
}
