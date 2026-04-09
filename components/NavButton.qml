import QtQuick
import ".."

Item {
    id: root
    height: 45
    width: parent.width

    property string text: ""
    property bool active: false
    signal clicked

    MyButton {
        text: root.text

        normalColor: Theme.bg
        hoverColor: Theme.surface
        textNormalColor: parent.active ? Theme.surface : Theme.textMain
        anchors.fill: parent
        anchors.verticalCenter: parent.verticalCenter
        onClicked: root.clicked()
    }
}
