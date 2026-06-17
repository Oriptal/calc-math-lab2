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

    title: "Вычислительная математика"
    flags: Qt.Window | Qt.FramelessWindowHint
    MyRect {
        id: root
        anchors.fill: parent

        Header {
            id: header
        }

        Body {
            anchors.top: header.bottom
        }

        // Ручки ресайза по краям и углам безрамочного окна.
        MouseArea {
            width: 6
            height: parent.height
            anchors.left: parent.left
            cursorShape: Qt.SizeHorCursor
            onPressed: appWindow.startSystemResize(Qt.LeftEdge)
        }
        MouseArea {
            width: 6
            height: parent.height
            anchors.right: parent.right
            cursorShape: Qt.SizeHorCursor
            onPressed: appWindow.startSystemResize(Qt.RightEdge)
        }
        MouseArea {
            width: parent.width
            height: 6
            anchors.top: parent.top
            cursorShape: Qt.SizeVerCursor
            onPressed: appWindow.startSystemResize(Qt.TopEdge)
        }
        MouseArea {
            width: parent.width
            height: 6
            anchors.bottom: parent.bottom
            cursorShape: Qt.SizeVerCursor
            onPressed: appWindow.startSystemResize(Qt.BottomEdge)
        }
        MouseArea {
            width: 14
            height: 14
            anchors.left: parent.left
            anchors.top: parent.top
            cursorShape: Qt.SizeFDiagCursor
            onPressed: appWindow.startSystemResize(Qt.LeftEdge | Qt.TopEdge)
        }
        MouseArea {
            width: 14
            height: 14
            anchors.right: parent.right
            anchors.top: parent.top
            cursorShape: Qt.SizeBDiagCursor
            onPressed: appWindow.startSystemResize(Qt.RightEdge | Qt.TopEdge)
        }
        MouseArea {
            width: 14
            height: 14
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            cursorShape: Qt.SizeBDiagCursor
            onPressed: appWindow.startSystemResize(Qt.LeftEdge | Qt.BottomEdge)
        }
        MouseArea {
            width: 14
            height: 14
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            cursorShape: Qt.SizeFDiagCursor
            onPressed: appWindow.startSystemResize(Qt.RightEdge | Qt.BottomEdge)
        }
    }
}
