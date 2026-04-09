import QtQuick
import QtQuick.Layouts
import ".."

MyRect {
    color: "transparent"

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20

        Text {
            text: "Настройки интерфейса"
            color: Theme.textMain
            font.pixelSize: 24
            Layout.alignment: Qt.AlignHCenter
        }

        NavButton {
            Layout.preferredWidth: 200
            text: Theme.isDark ? "Светлая тема" : "Тёмная тема"
            active: false
            onClicked: Theme.isDark = !Theme.isDark
        }

        Text {
            text: "Текущий режим: " + (Theme.isDark ? "Тёмный" : "Светлый")
            color: Theme.textDimmed
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
