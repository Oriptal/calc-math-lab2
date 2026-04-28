import QtQuick
import ".."

MyRect {
    height: 50

    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 12

    MyText {
        text: "Численная математика — ЛР №2 + ЛР №3"
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        MyButton {
            text: "—"
            textNormalColor: Theme.textMain
            textHoverColor: Theme.textDimmed
            leftAligned: false
            bold: true
            onClicked: Window.window.showMinimized()
        }

        MyButton {
            text: "✕"
            textNormalColor: Theme.textMain
            textHoverColor: Theme.textDimmed
            leftAligned: false
            bold: true
            onClicked: Qt.quit()
        }
    }
}
