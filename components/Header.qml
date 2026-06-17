import QtQuick
import ".."

MyRect {
    height: 50

    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 12

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onPressed: Window.window.startSystemMove()
        onDoubleClicked: Window.window.visibility === Window.Maximized
                         ? Window.window.showNormal()
                         : Window.window.showMaximized()
    }

    MyText {
        text: "Вычислительная математика"
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
