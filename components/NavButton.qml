import QtQuick
import ".."

Item {
    id: root
    height: 45
    width: parent.width

    property string text: ""
    property bool active: false
    signal clicked

    Rectangle {
        id: accentBar
        width: 3
        height: parent.height * 0.55
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        radius: 1.5
        color: Theme.accent
        opacity: root.active ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
    }

    MyButton {
        text: root.text

        normalColor: Theme.bg
        hoverColor: Qt.lighter(Theme.bg, 1.5)
        textNormalColor: parent.active ? Theme.surface : Theme.textMain
        anchors.fill: parent
        anchors.verticalCenter: parent.verticalCenter
        onClicked: root.clicked()
    }
}
